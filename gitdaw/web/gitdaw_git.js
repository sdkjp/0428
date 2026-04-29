/**
 * GitDAW Web Git Bridge
 * File System Access API adapter + isomorphic-git bindings for Flutter JS interop.
 * Exposed as window.gitdaw — called from lib/services/git_service_web.dart.
 */

// ---------------------------------------------------------------------------
// File System Access API adapter for isomorphic-git
// isomorphic-git expects a node-like fs object with .promises.*
// ---------------------------------------------------------------------------

class _FSAAdapter {
  constructor(rootHandle) {
    this._root = rootHandle;
    // isomorphic-git accesses fs.promises.*
    this.promises = this;
  }

  // Walk path segments from root, returning the last parent dir handle + final name
  async _resolve(path) {
    const parts = path.replace(/^\/+|\/+$/g, '').split('/').filter(Boolean);
    let dir = this._root;
    for (let i = 0; i < parts.length - 1; i++) {
      try {
        dir = await dir.getDirectoryHandle(parts[i]);
      } catch (_) {
        const e = new Error(`ENOENT: no such file or directory, open '${path}'`);
        e.code = 'ENOENT';
        throw e;
      }
    }
    return { parent: dir, name: parts[parts.length - 1] || null, parts };
  }

  async readFile(path, options) {
    const { parent, name } = await this._resolve(path);
    if (!name) throw Object.assign(new Error('EISDIR'), { code: 'EISDIR' });
    let fh;
    try { fh = await parent.getFileHandle(name); }
    catch (_) {
      const e = new Error(`ENOENT: '${path}'`); e.code = 'ENOENT'; throw e;
    }
    const file = await fh.getFile();
    const buf = await file.arrayBuffer();
    const enc = typeof options === 'string' ? options : options?.encoding;
    return (enc === 'utf8' || enc === 'utf-8')
      ? new TextDecoder().decode(buf)
      : new Uint8Array(buf);
  }

  async writeFile(path, data, _options) {
    const parts = path.replace(/^\/+|\/+$/g, '').split('/').filter(Boolean);
    let dir = this._root;
    for (let i = 0; i < parts.length - 1; i++) {
      dir = await dir.getDirectoryHandle(parts[i], { create: true });
    }
    const fh = await dir.getFileHandle(parts[parts.length - 1], { create: true });
    const w = await fh.createWritable();
    await w.write(typeof data === 'string' ? new TextEncoder().encode(data) : data);
    await w.close();
  }

  async unlink(path) {
    const { parent, name } = await this._resolve(path);
    await parent.removeEntry(name);
  }

  async readdir(path, options) {
    let dir = this._root;
    if (path && path !== '/') {
      const parts = path.replace(/^\/+|\/+$/g, '').split('/').filter(Boolean);
      for (const p of parts) dir = await dir.getDirectoryHandle(p);
    }
    const entries = [];
    for await (const entry of dir.values()) {
      if (options?.withFileTypes) {
        entries.push({
          name: entry.name,
          isDirectory: () => entry.kind === 'directory',
          isFile: () => entry.kind === 'file',
          isSymbolicLink: () => false,
        });
      } else {
        entries.push(entry.name);
      }
    }
    return entries;
  }

  async mkdir(path, _options) {
    const parts = path.replace(/^\/+|\/+$/g, '').split('/').filter(Boolean);
    let dir = this._root;
    for (const p of parts) dir = await dir.getDirectoryHandle(p, { create: true });
  }

  async rmdir(path) {
    const { parent, name } = await this._resolve(path);
    await parent.removeEntry(name, { recursive: true });
  }

  async stat(path) { return this.lstat(path); }

  async lstat(path) {
    if (!path || path === '/') {
      return _fsaStat(null, 'directory');
    }
    const { parent, name } = await this._resolve(path);
    if (!name) return _fsaStat(null, 'directory');

    // Try file
    try {
      const fh = await parent.getFileHandle(name);
      const file = await fh.getFile();
      return _fsaStat(file, 'file');
    } catch (_) {}

    // Try directory
    try {
      await parent.getDirectoryHandle(name);
      return _fsaStat(null, 'directory');
    } catch (_) {}

    const e = new Error(`ENOENT: '${path}'`); e.code = 'ENOENT'; throw e;
  }

  async rename(src, dst) {
    const data = await this.readFile(src);
    await this.writeFile(dst, data);
    await this.unlink(src);
  }

  // isomorphic-git calls these for symlinks (.git/HEAD etc.)
  // FSA doesn't support symlinks — store as plain file with a special suffix
  async symlink(target, path) {
    await this.writeFile(path + '.__symlink__', target);
  }
  async readlink(path) {
    return this.readFile(path + '.__symlink__', 'utf8');
  }
}

function _fsaStat(file, kind) {
  const mt = file ? file.lastModified : 0;
  return {
    isFile: () => kind === 'file',
    isDirectory: () => kind === 'directory',
    isSymbolicLink: () => false,
    size: file ? file.size : 0,
    ctimeMs: mt, mtimeMs: mt, atimeMs: mt, birthtimeMs: mt,
    mode: kind === 'directory' ? 0o40755 : 0o100644,
    ino: 0, dev: 0, uid: 0, gid: 0, nlink: 1,
  };
}

// ---------------------------------------------------------------------------
// Author config (persisted in localStorage)
// ---------------------------------------------------------------------------

function _getAuthor() {
  return {
    name: localStorage.getItem('gitdaw_author_name') || 'GitDAW User',
    email: localStorage.getItem('gitdaw_author_email') || 'user@gitdaw.local',
  };
}

// ---------------------------------------------------------------------------
// Built-in fetch-based HTTP transport for isomorphic-git push/pull
// (avoids depending on a separate CDN bundle for GitHttp)
// ---------------------------------------------------------------------------

const _gitHttp = {
  async request({ url, method, headers, body, onProgress }) {
    const chunks = [];
    if (body) {
      for await (const chunk of body) chunks.push(chunk);
    }
    const res = await fetch(url, {
      method,
      headers,
      body: chunks.length
        ? new Blob(chunks)
        : undefined,
    });
    const buf = await res.arrayBuffer();
    return {
      url: res.url,
      method,
      statusCode: res.status,
      statusMessage: res.statusText,
      body: [new Uint8Array(buf)],
      headers: Object.fromEntries(res.headers.entries()),
    };
  },
};

// ---------------------------------------------------------------------------
// Active repo state
// ---------------------------------------------------------------------------

let _dirHandle = null;  // FileSystemDirectoryHandle
let _fs = null;         // _FSAAdapter instance
let _repoPath = '/';

// ---------------------------------------------------------------------------
// Public API (window.gitdaw)
// ---------------------------------------------------------------------------

window.gitdaw = {

  /** Open native directory picker. Returns directory name, or null on cancel. */
  async openDirectory() {
    try {
      const handle = await window.showDirectoryPicker({ mode: 'readwrite' });
      _dirHandle = handle;
      _fs = new _FSAAdapter(handle);
      _repoPath = '/';
      return handle.name;
    } catch (e) {
      if (e.name === 'AbortError') return null;
      throw e;
    }
  },

  /** Re-attach to an already-held handle (e.g. after page reload — handle may be stale). */
  async reattach(handle) {
    _dirHandle = handle;
    _fs = new _FSAAdapter(handle);
    _repoPath = '/';
  },

  isDirectoryOpen() {
    return _dirHandle !== null;
  },

  /** Initialise a git repo at the open directory (git init + initial empty commit). */
  async initRepo() {
    _assertOpen();
    await git.init({ fs: _fs, dir: _repoPath, defaultBranch: 'main' });
    await git.commit({
      fs: _fs, dir: _repoPath,
      message: '初期化',
      author: _getAuthor(),
    });
  },

  /** Returns true if the open directory is already a git repo. */
  async isGitRepo() {
    if (!_fs) return false;
    try {
      await git.resolveRef({ fs: _fs, dir: _repoPath, ref: 'HEAD' });
      return true;
    } catch (_) {
      return false;
    }
  },

  /** Get current branch name. */
  async getCurrentBranch() {
    _assertOpen();
    return (await git.currentBranch({ fs: _fs, dir: _repoPath })) || 'main';
  },

  /** List all local branches. Returns array of { name, oid }. */
  async getBranches() {
    _assertOpen();
    const names = await git.listBranches({ fs: _fs, dir: _repoPath });
    return names.map(n => ({ name: n }));
  },

  /**
   * Get log for a branch. Returns array of commit objects.
   * Each: { sha, message, authorName, authorEmail, isoDate, files[] }
   * files: { path, insertions, deletions }
   */
  async getLog(branch, limit) {
    _assertOpen();
    const commits = await git.log({
      fs: _fs, dir: _repoPath,
      ref: branch || 'HEAD',
      depth: limit || 300,
    });

    // Enrich with file-change stats (expensive for large repos — skip for now,
    // return empty files array; hover panel will show 0)
    return commits.map(c => ({
      sha: c.oid,
      message: c.commit.message.trim(),
      authorName: c.commit.author.name,
      authorEmail: c.commit.author.email,
      isoDate: new Date(c.commit.author.timestamp * 1000).toISOString(),
      files: [],
    }));
  },

  /** Stage all changes (git add -A equivalent). */
  async stageAll() {
    _assertOpen();
    await git.add({ fs: _fs, dir: _repoPath, filepath: '.' });
  },

  /** Returns true if there are uncommitted changes. */
  async hasUncommittedChanges() {
    _assertOpen();
    const status = await git.statusMatrix({ fs: _fs, dir: _repoPath });
    // [head, workdir, stage] — if all 1,1,1 the file is unchanged
    return status.some(([, head, workdir, stage]) =>
      !(head === 1 && workdir === 1 && stage === 1)
    );
  },

  /** Create a commit. Returns the new SHA. */
  async commit(message) {
    _assertOpen();
    const sha = await git.commit({
      fs: _fs, dir: _repoPath,
      message,
      author: _getAuthor(),
    });
    return sha;
  },

  /** Auto-commit if dirty. Returns new SHA or null. */
  async autoCommitIfChanged() {
    if (!await this.hasUncommittedChanges()) return null;
    await this.stageAll();
    const now = new Date();
    const pad = n => String(n).padStart(2, '0');
    const label = `${now.getFullYear()}-${pad(now.getMonth()+1)}-${pad(now.getDate())} ` +
                  `${pad(now.getHours())}:${pad(now.getMinutes())}`;
    return this.commit(`自動保存 ${label}`);
  },

  /** Create a new branch, optionally from a given SHA. */
  async createBranch(name, fromSha) {
    _assertOpen();
    const ref = fromSha || await git.resolveRef({ fs: _fs, dir: _repoPath, ref: 'HEAD' });
    await git.branch({ fs: _fs, dir: _repoPath, ref: name, object: ref });
    await git.checkout({ fs: _fs, dir: _repoPath, ref: name });
    return name;
  },

  /** Checkout a branch. */
  async checkoutBranch(name) {
    _assertOpen();
    await git.checkout({ fs: _fs, dir: _repoPath, ref: name });
  },

  /** Checkout a specific commit (detached HEAD). */
  async checkoutCommit(sha) {
    _assertOpen();
    await git.checkout({ fs: _fs, dir: _repoPath, ref: sha, noUpdateHead: false });
  },

  /** Checkout the tip of a branch (recover from detached HEAD). */
  async checkoutLatest(branch) {
    _assertOpen();
    await git.checkout({ fs: _fs, dir: _repoPath, ref: branch });
  },

  /**
   * Merge sourceBranch into targetBranch.
   * Returns { success, hasConflicts, errorMessage }.
   */
  async mergeBranch(sourceBranch, targetBranch) {
    _assertOpen();
    try {
      await git.checkout({ fs: _fs, dir: _repoPath, ref: targetBranch });
      const result = await git.merge({
        fs: _fs, dir: _repoPath,
        ours: targetBranch,
        theirs: sourceBranch,
        abortOnConflict: true,
        author: _getAuthor(),
      });
      return { success: true, hasConflicts: false, errorMessage: null };
    } catch (e) {
      const hasConflicts = e.name === 'MergeConflictError';
      return { success: false, hasConflicts, errorMessage: e.message };
    }
  },

  /** Push to remote (requires CORS-enabled server or GitHub token in headers). */
  async push(remote, branch, token) {
    _assertOpen();
    const br = branch || await this.getCurrentBranch();
    await git.push({
      fs: _fs, dir: _repoPath,
      http: _gitHttp,
      remote: remote || 'origin',
      ref: br,
      onAuth: token ? () => ({ username: token }) : undefined,
    });
  },

  /** Pull from remote. */
  async pull(remote, branch, token) {
    _assertOpen();
    const br = branch || await this.getCurrentBranch();
    await git.pull({
      fs: _fs, dir: _repoPath,
      http: _gitHttp,
      remote: remote || 'origin',
      ref: br,
      author: _getAuthor(),
      onAuth: token ? () => ({ username: token }) : undefined,
    });
  },

  /** Save author identity to localStorage. */
  setAuthor(name, email) {
    localStorage.setItem('gitdaw_author_name', name);
    localStorage.setItem('gitdaw_author_email', email);
  },

  getAuthor: _getAuthor,
};

function _assertOpen() {
  if (!_fs) throw new Error('No directory open. Call gitdaw.openDirectory() first.');
}

// ---------------------------------------------------------------------------
// JSON bridge — called from Dart via dart:js_interop
// Complex return values are JSON-encoded to avoid JS↔Dart object mapping.
// ---------------------------------------------------------------------------

window.gitdawJson = {
  async getLog(branch, limit) {
    return JSON.stringify(await window.gitdaw.getLog(branch, limit));
  },
  async getBranches() {
    return JSON.stringify(await window.gitdaw.getBranches());
  },
  async mergeBranch(sourceBranch, targetBranch) {
    return JSON.stringify(await window.gitdaw.mergeBranch(sourceBranch, targetBranch));
  },
  async getMergeResult(src, tgt) {
    return JSON.stringify(await window.gitdaw.mergeBranch(src, tgt));
  },
};
