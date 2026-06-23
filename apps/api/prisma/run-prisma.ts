import { spawnSync } from 'node:child_process';
import { loadEnvFiles } from '../src/common/utils/load-env';

loadEnvFiles();

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error('Usage: tsx prisma/run-prisma.ts <prisma command...>');
  process.exit(1);
}

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is not set. Copy .env.example to .env in the repo root.');
  process.exit(1);
}

const result = spawnSync('prisma', args, {
  stdio: 'inherit',
  env: process.env,
});

process.exit(result.status ?? 1);
