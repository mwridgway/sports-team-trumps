// Publish the exported game data to Vercel Blob (store urc-trumps-data).
// Run after scripts/export_app_data.py with BLOB_READ_WRITE_TOKEN set.
// Uploads new headshots only, then urc/latest.json (short cache, so the app sees updates quickly).
import { list, put } from '@vercel/blob';
import { readFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';

const dataDir = new URL('../../ios/URCTrumps/Resources/GameData/', import.meta.url).pathname;
const headshotDir = join(dataDir, 'headshots');

async function existingPaths(prefix) {
  const paths = new Set();
  let cursor;
  do {
    const page = await list({ prefix, cursor, limit: 1000 });
    page.blobs.forEach((b) => paths.add(b.pathname));
    cursor = page.hasMore ? page.cursor : undefined;
  } while (cursor);
  return paths;
}

const have = await existingPaths('urc/headshots/');
const files = (await readdir(headshotDir)).filter((f) => f.endsWith('.jpg') && !have.has(`urc/headshots/${f}`));

for (let i = 0; i < files.length; i += 16) {
  await Promise.all(files.slice(i, i + 16).map(async (f) =>
    put(`urc/headshots/${f}`, await readFile(join(headshotDir, f)), {
      access: 'public', contentType: 'image/jpeg', addRandomSuffix: false, cacheControlMaxAge: 60 * 60 * 24 * 30,
    })));
}

const json = await readFile(join(dataDir, 'urc.json'));
const { generated_at: generatedAt } = JSON.parse(json);
const latest = await put('urc/latest.json', json, {
  access: 'public', contentType: 'application/json', addRandomSuffix: false, allowOverwrite: true, cacheControlMaxAge: 60,
});
console.log(`uploaded ${files.length} new headshots (${have.size} already there); latest.json ${generatedAt} -> ${latest.url}`);
