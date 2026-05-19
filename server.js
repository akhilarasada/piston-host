'use strict';

const express = require('express');
const { exec } = require('child_process');
const fs       = require('fs');
const path     = require('path');
const crypto   = require('crypto');

const app  = express();
const PORT = process.env.PORT || 8080;

/* ── CORS (browser calls this directly) ───────────────────────────────────── */
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

app.use(express.json({ limit: '2mb' }));

/* ── Language definitions ─────────────────────────────────────────────────── */
const LANGS = {
  python: {
    ext: 'py',
    run: (f) => `python3 "${f}"`,
  },
  javascript: {
    ext: 'js',
    run: (f) => `node "${f}"`,
  },
  typescript: {
    ext: 'ts',
    compile: (f, d) =>
      `tsc "${f}" --outDir "${d}" --target ES2020 --module commonjs --skipLibCheck`,
    run: (_f, d) => `node "${path.join(d, 'code.js')}"`,
  },
  java: {
    ext: 'java',
    compile: (f, d) => `javac -d "${d}" "${f}"`,
    run: (_f, d, cls) => `java -cp "${d}" -Xmx256m ${cls}`,
  },
  c: {
    ext: 'c',
    compile: (f, d) => `gcc "${f}" -o "${path.join(d, 'prog')}" -lm`,
    run: (_f, d) => `"${path.join(d, 'prog')}"`,
  },
  'c++': {
    ext: 'cpp',
    compile: (f, d) => `g++ "${f}" -o "${path.join(d, 'prog')}"`,
    run: (_f, d) => `"${path.join(d, 'prog')}"`,
  },
  csharp: {
    ext: 'cs',
    compile: (f, d) => `mcs "${f}" -out:"${path.join(d, 'prog.exe')}"`,
    run: (_f, d) => `mono "${path.join(d, 'prog.exe')}"`,
  },
  go: {
    ext: 'go',
    run: (f) => `go run "${f}"`,
  },
  rust: {
    ext: 'rs',
    compile: (f, d) => `rustc "${f}" -o "${path.join(d, 'prog')}"`,
    run: (_f, d) => `"${path.join(d, 'prog')}"`,
  },
  ruby: {
    ext: 'rb',
    run: (f) => `ruby "${f}"`,
  },
  kotlin: {
    ext: 'kt',
    compile: (f, d) =>
      `kotlinc "${f}" -include-runtime -d "${path.join(d, 'prog.jar')}"`,
    run: (_f, d) => `java -jar "${path.join(d, 'prog.jar')}"`,
    compileTimeout: 60000, // kotlinc JVM startup is slow
  },
};

const RUNTIMES = Object.keys(LANGS).map((language) => ({
  language,
  version: '1.0.0',
  aliases: [],
}));

/* ── Helpers ──────────────────────────────────────────────────────────────── */
function javaClass(code) {
  const m = code.match(/public\s+class\s+(\w+)/);
  return m ? m[1] : 'Main';
}

function shell(cmd, stdinText, timeout) {
  return new Promise((resolve) => {
    const proc = exec(
      cmd,
      { timeout, maxBuffer: 512 * 1024 },
      (err, stdout, stderr) => {
        const timedOut = !!(err?.killed);
        resolve({
          stdout: stdout || '',
          stderr: timedOut
            ? `Time limit exceeded (${timeout / 1000}s)\n`
            : stderr || '',
          code: timedOut ? 124 : (err?.code ?? 0),
        });
      },
    );
    if (stdinText) {
      try { proc.stdin?.write(stdinText); proc.stdin?.end(); } catch {}
    }
  });
}

/* ── Routes ───────────────────────────────────────────────────────────────── */
app.get('/health', (_req, res) => res.json({ ok: true }));

// Piston-compatible: list runtimes
app.get('/api/v2/runtimes', (_req, res) => res.json(RUNTIMES));

// Piston-compatible: package stubs (not needed but keeps frontend happy)
app.get('/api/v2/packages',  (_req, res) => res.json([]));
app.post('/api/v2/packages', (req, res) =>
  res.json({ language: req.body?.language, version: req.body?.version }),
);

// Piston-compatible: execute
app.post('/api/v2/execute', async (req, res) => {
  const { language = '', files = [], stdin = '' } = req.body || {};
  const lang = language.toLowerCase();
  const cfg  = LANGS[lang];

  if (!cfg)          return res.status(400).json({ message: `${language} runtime is unknown` });
  if (!files.length) return res.status(400).json({ message: 'No files provided' });

  const code  = files[0]?.content ?? '';
  const tmpId = crypto.randomBytes(8).toString('hex');
  const dir   = `/tmp/exec/${tmpId}`;

  try {
    fs.mkdirSync(dir, { recursive: true });

    // Java: filename must exactly match public class name
    const fname    = lang === 'java' ? `${javaClass(code)}.java` : `code.${cfg.ext}`;
    const filePath = path.join(dir, fname);
    fs.writeFileSync(filePath, code, 'utf8');

    /* Compile ──────────────────────────────────────────────────────────────── */
    let compileOut = null;
    if (cfg.compile) {
      const compileCmd     = cfg.compile(filePath, dir);
      const compileTimeout = cfg.compileTimeout || 30000;
      compileOut = await shell(compileCmd, null, compileTimeout);

      if (compileOut.code !== 0) {
        return res.json({
          compile: {
            stdout: compileOut.stdout,
            stderr: compileOut.stderr,
            code:   compileOut.code,
          },
          run: { stdout: '', stderr: '', code: 1 },
        });
      }
    }

    /* Run ──────────────────────────────────────────────────────────────────── */
    const runCmd = lang === 'java'
      ? cfg.run(filePath, dir, javaClass(code))
      : cfg.run(filePath, dir);

    const runOut = await shell(runCmd, stdin, 15000);

    return res.json({
      compile: compileOut,
      run: {
        stdout: runOut.stdout,
        stderr: runOut.stderr,
        code:   runOut.code,
      },
    });

  } catch (e) {
    return res.status(500).json({ message: e.message });
  } finally {
    fs.rm(dir, { recursive: true, force: true }, () => {});
  }
});

app.listen(PORT, '0.0.0.0', () =>
  console.log(`Code runner ready on port ${PORT}`),
);
