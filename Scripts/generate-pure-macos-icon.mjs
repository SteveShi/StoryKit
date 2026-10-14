import { writeFileSync, mkdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { createCanvas } from '../web/cartographer/node_modules/@napi-rs/canvas/index.js';

/**
 * Generates pure macOS platform-style icons conforming strictly to Apple HIG:
 * - 1024x1024 edge-to-edge full-bleed canvas
 * - No fake rounded corners or inner borders (OS handles squircle)
 * - Restrained diffuse ambient shadows, no gratuitous glossy reflections
 * - Precise geometric drafting & cartographic aesthetics
 */

function drawContour(ctx, points, color, width) {
  ctx.save();
  ctx.beginPath();
  ctx.moveTo(points[0][0], points[0][1]);
  for (let i = 1; i < points.length - 2; i++) {
    const xc = (points[i][0] + points[i + 1][0]) / 2;
    const yc = (points[i][1] + points[i + 1][1]) / 2;
    ctx.quadraticCurveTo(points[i][0], points[i][1], xc, yc);
  }
  ctx.quadraticCurveTo(
    points[points.length - 2][0],
    points[points.length - 2][1],
    points[points.length - 1][0],
    points[points.length - 1][1]
  );
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.stroke();
  ctx.restore();
}

// ==========================================
// Style 1: Deep Nautical Slate (Apple Pro / Cartographer)
// ==========================================
function renderSlateNavyIcon() {
  const canvas = createCanvas(1024, 1024);
  const ctx = canvas.getContext('2d');
  const cx = 512;
  const cy = 512;

  // 1. Full-bleed background gradient (Deep Nautical Slate)
  const bg = ctx.createLinearGradient(0, 0, 1024, 1024);
  bg.addColorStop(0, '#1C2938');
  bg.addColorStop(0.5, '#141E2B');
  bg.addColorStop(1, '#0C131D');
  ctx.fillStyle = bg;
  ctx.fillRect(0, 0, 1024, 1024);

  // 2. Subtle cartographic topographic contours (refined, restrained)
  const contourColor = 'rgba(255, 255, 255, 0.045)';
  const contourMajor = 'rgba(255, 255, 255, 0.08)';

  drawContour(ctx, [[-50, 200], [250, 150], [400, 320], [700, 260], [1074, 180]], contourColor, 1.5);
  drawContour(ctx, [[-50, 320], [220, 270], [450, 420], [750, 380], [1074, 300]], contourMajor, 2);
  drawContour(ctx, [[-50, 440], [200, 420], [420, 520], [680, 500], [1074, 460]], contourColor, 1.5);
  drawContour(ctx, [[-50, 600], [280, 620], [520, 680], [800, 640], [1074, 620]], contourMajor, 2);
  drawContour(ctx, [[-50, 750], [300, 780], [600, 790], [820, 810], [1074, 760]], contourColor, 1.5);

  // 3. Coordinate Graticule Rings
  ctx.save();
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.07)';
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.arc(cx, cy, 380, 0, Math.PI * 2);
  ctx.stroke();

  ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(cx, cy, 340, 0, Math.PI * 2);
  ctx.stroke();

  // Degree tick marks (every 15 degrees, bold at 45/90)
  for (let deg = 0; deg < 360; deg += 15) {
    const rad = (deg * Math.PI) / 180;
    const isMajor = deg % 45 === 0;
    const isCardinal = deg % 90 === 0;
    const rIn = isCardinal ? 318 : isMajor ? 324 : 330;
    const rOut = 340;

    const x1 = cx + Math.sin(rad) * rIn;
    const y1 = cy - Math.cos(rad) * rIn;
    const x2 = cx + Math.sin(rad) * rOut;
    const y2 = cy - Math.cos(rad) * rOut;

    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.strokeStyle = isCardinal ? 'rgba(255, 255, 255, 0.5)' : isMajor ? 'rgba(255, 255, 255, 0.3)' : 'rgba(255, 255, 255, 0.15)';
    ctx.lineWidth = isCardinal ? 3 : isMajor ? 2 : 1.2;
    ctx.stroke();
  }
  ctx.restore();

  // 4. Center Compass Rose with macOS Layered Ambient Shadow
  ctx.save();
  ctx.shadowColor = 'rgba(0, 0, 0, 0.45)';
  ctx.shadowBlur = 36;
  ctx.shadowOffsetY = 16;

  // Cardinal dimensions
  const rMajor = 300; // Tip length of major points
  const rMinor = 210; // Tip length of diagonal points
  const rBase = 58;   // Base width at center

  // Minor diagonal points (NE, NW, SE, SW)
  const drawCornerPoint = (angleDeg, lightColor, darkColor) => {
    const rad = (angleDeg * Math.PI) / 180;
    const tipX = cx + Math.sin(rad) * rMinor;
    const tipY = cy - Math.cos(rad) * rMinor;

    const radLeft = rad - Math.PI / 4;
    const radRight = rad + Math.PI / 4;
    const baseLX = cx + Math.sin(radLeft) * (rBase * 0.7);
    const baseLY = cy - Math.cos(radLeft) * (rBase * 0.7);
    const baseRX = cx + Math.sin(radRight) * (rBase * 0.7);
    const baseRY = cy - Math.cos(radRight) * (rBase * 0.7);

    // Left half
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(baseLX, baseLY);
    ctx.lineTo(tipX, tipY);
    ctx.closePath();
    ctx.fillStyle = lightColor;
    ctx.fill();

    // Right half
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(tipX, tipY);
    ctx.lineTo(baseRX, baseRY);
    ctx.closePath();
    ctx.fillStyle = darkColor;
    ctx.fill();
  };

  drawCornerPoint(45, '#8E9AA8', '#667484');
  drawCornerPoint(135, '#8E9AA8', '#667484');
  drawCornerPoint(225, '#8E9AA8', '#667484');
  drawCornerPoint(315, '#8E9AA8', '#667484');

  // Major Cardinal Points:
  // North (Red Apple vermilion)
  // Left half (North)
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx - rBase, cy);
  ctx.lineTo(cx, cy - rMajor);
  ctx.closePath();
  ctx.fillStyle = '#FF5247'; // Clean Apple Vermilion
  ctx.fill();

  // Right half (North)
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx, cy - rMajor);
  ctx.lineTo(cx + rBase, cy);
  ctx.closePath();
  ctx.fillStyle = '#D93829'; // Shaded Vermilion
  ctx.fill();

  // South (White / Light Silver)
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx - rBase, cy);
  ctx.lineTo(cx, cy + rMajor);
  ctx.closePath();
  ctx.fillStyle = '#E5E8EB';
  ctx.fill();

  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx, cy + rMajor);
  ctx.lineTo(cx + rBase, cy);
  ctx.closePath();
  ctx.fillStyle = '#B0B8C2';
  ctx.fill();

  // East (Silver)
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx, cy - rBase);
  ctx.lineTo(cx + rMajor, cy);
  ctx.closePath();
  ctx.fillStyle = '#D2D7DE';
  ctx.fill();

  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx + rMajor, cy);
  ctx.lineTo(cx, cy + rBase);
  ctx.closePath();
  ctx.fillStyle = '#9AA5B2';
  ctx.fill();

  // West (Silver)
  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx, cy - rBase);
  ctx.lineTo(cx - rMajor, cy);
  ctx.closePath();
  ctx.fillStyle = '#B0B8C2';
  ctx.fill();

  ctx.beginPath();
  ctx.moveTo(cx, cy);
  ctx.lineTo(cx - rMajor, cy);
  ctx.lineTo(cx, cy + rBase);
  ctx.closePath();
  ctx.fillStyle = '#E5E8EB';
  ctx.fill();

  ctx.restore();

  // 5. Center Pivot Pin (Matte Titanium & Fine Bevel)
  ctx.save();
  // Outer rim
  ctx.beginPath();
  ctx.arc(cx, cy, 26, 0, Math.PI * 2);
  ctx.fillStyle = '#2A3644';
  ctx.strokeStyle = '#FFFFFF';
  ctx.lineWidth = 3.5;
  ctx.stroke();
  ctx.fill();

  // Inner pin
  ctx.beginPath();
  ctx.arc(cx, cy, 14, 0, Math.PI * 2);
  const pinGrad = ctx.createLinearGradient(cx - 10, cy - 10, cx + 10, cy + 10);
  pinGrad.addColorStop(0, '#FFFFFF');
  pinGrad.addColorStop(1, '#8E9AA8');
  ctx.fillStyle = pinGrad;
  ctx.fill();
  ctx.restore();

  return canvas;
}

// Generate the 1024x1024 master icon
const canvas = renderSlateNavyIcon();
const outDir = 'StoryKit/Resources/Assets.xcassets/AppIcon.appiconset';
mkdirSync(outDir, { recursive: true });

const base1024 = `${outDir}/icon_512x512@2x.png`;
writeFileSync(base1024, canvas.toBuffer('image/png'));

// Resample all macOS standard sizes
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

// Generate AppIcon.icns for macOS Finder bundle
execSync(`iconutil -c icns "${outDir}" -o StoryKit/Resources/AppIcon.icns 2>/dev/null || true`);

console.log('Pure macOS style AppIcon & icns generated successfully!');
