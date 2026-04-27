#!/usr/bin/env node

/**
 * Operator CLI — Matrix Console for Nebuchadnezzar
 *
 * Forked from gastown-gui (web3dev1337). Same shape, retargeted.
 *
 * Usage:
 *   operator [command] [options]
 *
 * Commands:
 *   start         Start the Operator server (default)
 *   doctor        Check Nebuchadnezzar installation
 *   version       Show version
 *   help          Show help
 *
 * Options:
 *   --port, -p    Port to run on (default: 7667)
 *   --host, -h    Host to bind to (default: 127.0.0.1)
 *   --open, -o    Open browser after starting
 *   --dev         Enable development mode (auto-reload)
 *
 * Env vars:
 *   OPERATOR_PORT  Server port (alias of GASTOWN_PORT for upstream compat)
 *   OPERATOR_HOST  Server host (alias of HOST)
 *   GT_ROOT        Gas Town root directory (default: /gt or ~/gt)
 *   GT_BIN         Path to gt binary (default: PATH lookup)
 *   BD_BIN         Path to bd binary (default: PATH lookup)
 */

import { spawn, execSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const packageRoot = path.resolve(__dirname, '..');

const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
  showHelp();
  process.exit(0);
}
if (args.includes('--version') || args.includes('-v')) {
  showVersion();
  process.exit(0);
}

const command = args.find(a => !a.startsWith('-')) || 'start';
const options = {
  port: getOption(['--port', '-p'])
    || process.env.OPERATOR_PORT
    || process.env.GASTOWN_PORT
    || '7667',
  host: getOption(['--host', '-h'])
    || process.env.OPERATOR_HOST
    || process.env.HOST
    || '127.0.0.1',
  open: hasFlag(['--open', '-o']),
  dev: hasFlag(['--dev']),
};

function getOption(flags) {
  for (const flag of flags) {
    const idx = args.indexOf(flag);
    if (idx !== -1 && args[idx + 1]) {
      return args[idx + 1];
    }
  }
  return null;
}

function hasFlag(flags) {
  return flags.some(f => args.includes(f));
}

function showHelp() {
  console.log(`
Operator — Matrix Console for Nebuchadnezzar

Usage:
  operator [command] [options]

Commands:
  start         Start the Operator server (default)
  version       Show version information
  doctor        Check Nebuchadnezzar installation
  help          Show this help message

Options:
  --port, -p <port>   Port to run on (default: 7667, or OPERATOR_PORT env var)
  --host, -h <host>   Host to bind to (default: 127.0.0.1, or OPERATOR_HOST env var)
  --open, -o          Open browser after starting
  --dev               Enable development mode

Environment Variables:
  OPERATOR_PORT  Server port (alias: GASTOWN_PORT) — default 7667
  OPERATOR_HOST  Server host (alias: HOST) — default 127.0.0.1
  GT_ROOT        Gas Town root directory — default /gt (or ~/gt fallback)
  GT_BIN         Path to gt binary — default PATH lookup
  BD_BIN         Path to bd binary — default PATH lookup

Examples:
  operator                    # Start on default port (7667)
  operator start --port 9234  # Start on custom port
  operator start --open       # Start and open browser
  operator doctor             # Check Nebuchadnezzar installation

Prerequisites:
  - Nebuchadnezzar gt CLI installed and in PATH (or GT_BIN set)
  - bd (beads) CLI for issue tracking
  - gh (GitHub CLI) for PR/issue tracking (optional)

Upstream: https://github.com/web3dev1337/gastown-gui (sync via scripts/sync-upstream.sh)
This fork: https://github.com/maxz2040/Operator
`);
}

function showVersion() {
  const packageJson = JSON.parse(fs.readFileSync(path.join(packageRoot, 'package.json'), 'utf8'));
  console.log(`operator v${packageJson.version}`);

  try {
    const gtVersion = execSync('gt version 2>/dev/null || echo "not installed"', { encoding: 'utf8' }).trim();
    console.log(`gt: ${gtVersion}`);
  } catch {
    console.log('gt: not found in PATH');
  }

  try {
    const ghVersion = execSync('gh --version 2>/dev/null | head -1 || echo "not installed"', { encoding: 'utf8' }).trim();
    console.log(`gh: ${ghVersion}`);
  } catch {
    console.log('gh: not found in PATH');
  }
}

function runDoctor() {
  console.log('Operator Doctor — verifying Nebuchadnezzar prerequisites\n');

  let allGood = true;

  const nodeVersion = process.version;
  const major = parseInt(nodeVersion.slice(1).split('.')[0], 10);
  if (major >= 18) {
    console.log(`✅ Node.js ${nodeVersion} (>= 18 required)`);
  } else {
    console.log(`❌ Node.js ${nodeVersion} (>= 18 required)`);
    allGood = false;
  }

  try {
    const gtPath = execSync('which gt 2>/dev/null', { encoding: 'utf8' }).trim();
    const gtVersion = execSync('gt version 2>/dev/null', { encoding: 'utf8' }).trim();
    console.log(`✅ gt installed at ${gtPath}`);
    console.log(`   Version: ${gtVersion}`);
  } catch {
    console.log('❌ gt not found in PATH');
    console.log('   Build Nebuchadnezzar: cd /gt/neb/mayor/rig && make build');
    allGood = false;
  }

  try {
    execSync('which bd 2>/dev/null', { encoding: 'utf8' });
    console.log('✅ bd (beads) installed');
  } catch {
    console.log('⚠️  bd (beads) not found — some features may not work');
  }

  try {
    const ghVersion = execSync('gh --version 2>/dev/null | head -1', { encoding: 'utf8' }).trim();
    console.log(`✅ GitHub CLI: ${ghVersion}`);
    try {
      execSync('gh auth status 2>&1', { encoding: 'utf8' });
      console.log('   ✅ Authenticated');
    } catch {
      console.log('   ⚠️  Not authenticated — run: gh auth login');
    }
  } catch {
    console.log('⚠️  GitHub CLI (gh) not found — PR/issue tracking disabled');
  }

  const gtRoot = process.env.GT_ROOT
    || (fs.existsSync('/gt') ? '/gt' : path.join(process.env.HOME || '', 'gt'));
  if (fs.existsSync(gtRoot)) {
    console.log(`✅ GT_ROOT exists: ${gtRoot}`);
    try {
      const rigs = fs.readdirSync(gtRoot).filter(f => {
        const fullPath = path.join(gtRoot, f);
        return fs.statSync(fullPath).isDirectory() && fs.existsSync(path.join(fullPath, 'config.json'));
      });
      console.log(`   Found ${rigs.length} construct(s): ${rigs.join(', ') || '(none)'}`);
    } catch {
      // Ignore
    }
  } else {
    console.log(`⚠️  GT_ROOT not found: ${gtRoot}`);
    console.log('   Set GT_ROOT explicitly or initialise a town with `gt install`');
  }

  console.log('');
  if (allGood) {
    console.log('✅ All prerequisites met. Run: operator start');
  } else {
    console.log('❌ Some prerequisites missing. Fix issues above and try again.');
    process.exit(1);
  }
}

function startServer() {
  console.log(`Starting Operator on http://${options.host}:${options.port}...`);

  const env = {
    ...process.env,
    OPERATOR_PORT: options.port,
    GASTOWN_PORT: options.port, // legacy alias
    HOST: options.host,
    OPERATOR_HOST: options.host,
  };

  const serverPath = path.join(packageRoot, 'server.js');
  const serverArgs = options.dev ? ['--dev'] : [];

  const child = spawn('node', [serverPath, ...serverArgs], {
    env,
    stdio: 'inherit',
    cwd: packageRoot,
  });

  if (options.open) {
    setTimeout(() => {
      const url = `http://${options.host}:${options.port}`;
      const openCmd = process.platform === 'darwin' ? 'open' :
                      process.platform === 'win32' ? 'start' : 'xdg-open';
      try {
        execSync(`${openCmd} ${url}`, { stdio: 'ignore' });
      } catch {
        console.log(`Open browser manually: ${url}`);
      }
    }, 1500);
  }

  child.on('error', (err) => {
    console.error('Failed to start server:', err.message);
    process.exit(1);
  });

  child.on('exit', (code) => {
    process.exit(code || 0);
  });

  process.on('SIGINT', () => {
    child.kill('SIGINT');
  });

  process.on('SIGTERM', () => {
    child.kill('SIGTERM');
  });
}

switch (command) {
  case 'start':
    startServer();
    break;
  case 'version':
  case '-v':
  case '--version':
    showVersion();
    break;
  case 'doctor':
    runDoctor();
    break;
  case 'help':
  case '-h':
  case '--help':
    showHelp();
    break;
  default:
    console.error(`Unknown command: ${command}`);
    console.error('Run: operator help');
    process.exit(1);
}
