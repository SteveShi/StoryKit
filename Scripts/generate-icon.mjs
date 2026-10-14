import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { loadImage, createCanvas } from '../web/cartographer/node_modules/@napi-rs/canvas/index.js';

const svg = readFileSync('web/cartographer/public/favicon.svg', 'utf8');

// Full-bleed: replace rounded corners rx="13" with rx="0" and x="0" y="0" width="64" height="64"
const fullBleedSvg = svg
  .replace('<rect x="1" y="1" width="62" height="62" rx="13"', '<rect x="0" y="0" width="64" height="64"')
  .replace('<svg ', '<svg width="1024" height="1024" ');

const img = await loadImage(Buffer.from(fullBleedSvg));
const canvas = createCanvas(1024, 1024);
const ctx = canvas.getContext('2d');

// Full-bleed parchment background extending to every corner pixel
ctx.fillStyle = '#f2ecdf';
ctx.fillRect(0, 0, 1024, 1024);
ctx.drawImage(img, 0, 0, 1024, 1024);

const outDir = 'StoryKit/Resources/Assets.xcassets/AppIcon.appiconset';
mkdirSync(outDir, { recursive: true });

const base1024 = `${outDir}/icon_512x512@2x.png`;
writeFileSync(base1024, canvas.toBuffer('image/png'));

// Generate all standard macOS icon resolutions
const resolutions = [
  { name: 'icon_16x16.png', size: 16 },
  { name: 'icon_16x16@2x.png', size: 32 },
  { name: 'icon_32x32.png', size: 32 },
  { name: 'icon_32x32@2x.png', size: 64 },
  { name: 'icon_128x128.png', size: 128 },
  { name: 'icon_128x128@2x.png', size: 256 },
  { name: 'icon_256x256.png', size: 256 },
  { name: 'icon_256x256@2x.png', size: 512 },
  { name: 'icon_512x512.png', size: 512 }
];

for (const r of resolutions) {
  execSync(`sips -z ${r.size} ${r.size} "${base1024}" --out "${outDir}/${r.name}" > /dev/null`);
}

const contentsJson = {
  images: [
    { size: '16x16', idiom: 'mac', filename: 'icon_16x16.png', scale: '1x' },
    { size: '16x16', idiom: 'mac', filename: 'icon_16x16@2x.png', scale: '2x' },
    { size: '32x32', idiom: 'mac', filename: 'icon_32x32.png', scale: '1x' },
    { size: '32x32', idiom: 'mac', filename: 'icon_32x32@2x.png', scale: '2x' },
    { size: '128x128', idiom: 'mac', filename: 'icon_128x128.png', scale: '1x' },
    { size: '128x128', idiom: 'mac', filename: 'icon_128x128@2x.png', scale: '2x' },
    { size: '256x256', idiom: 'mac', filename: 'icon_256x256.png', scale: '1x' },
    { size: '256x256', idiom: 'mac', filename: 'icon_256x256@2x.png', scale: '2x' },
    { size: '512x512', idiom: 'mac', filename: 'icon_512x512.png', scale: '1x' },
    { size: '512x512', idiom: 'mac', filename: 'icon_512x512@2x.png', scale: '2x' }
  ],
  info: {
    author: 'xcode',
    version: 1
  }
};

writeFileSync(`${outDir}/Contents.json`, JSON.stringify(contentsJson, null, 2));

// Also generate AppIcon.icns for direct fallback
execSync(`iconutil -c icns "${outDir}" -o StoryKit/Resources/AppIcon.icns 2>/dev/null || true`);

console.log('macOS AppIcon and icns generated successfully.');
