// PASS 0052, PART 1, THE RED. Runs BOTH floor metrics over the same four
// documents and prints what each one can see.
//
// The old metric is a ratio of PNG BYTE LENGTHS: a screenshot of the drawn
// canvas divided by a screenshot of the same selector in an empty render. A
// painted background is in both pictures, so it lands in the numerator and the
// denominator together and drives the ratio toward 1 - which is the blindness
// pass 0051 measured at 1.05 and finding 67 recorded.
//
// The new metric compares the two pictures against EACH OTHER: the fraction of
// pixels whose largest per-channel difference exceeds a threshold. A painted
// background is identical in both, so it contributes zero changed pixels and
// cancels instead of dominating.
//
// Both numbers, side by side, for every case. A red that only showed the new
// metric working would not be a red.

const fs = require('fs');
const { chromium } = require('playwright');

const VIEWPORT = { width: 1280, height: 900 };
const DEVICE_SCALE_FACTOR = 1;
const SETTLE_MS = 1200;

async function openPage(browser) {
  const context = await browser.newContext({ viewport: VIEWPORT, deviceScaleFactor: DEVICE_SCALE_FACTOR });
  await context.route('http://**', route => route.abort());
  await context.route('https://**', route => route.abort());
  const page = await context.newPage();
  return { context, page };
}

async function shoot(browser, file, selector) {
  const { context, page } = await openPage(browser);
  try {
    await page.goto('file:///' + file.split('\\').join('/'));
    await page.waitForTimeout(SETTLE_MS);
    const handle = await page.$(selector);
    if (!handle) { return null; }
    return await handle.screenshot({ type: 'png' });
  } finally { await context.close(); }
}

// Decoded in the browser that is already open rather than by a PNG library.
// Adding a decoder to package.json would add a dependency to a harness whose
// whole claim is that it needs nothing but the pinned Playwright, and the
// browser can already decode a PNG. A data: URL does not taint a canvas, so
// getImageData is readable.
async function changedFraction(browser, pngA, pngB, threshold) {
  const { context, page } = await openPage(browser);
  try {
    await page.goto('about:blank');
    return await page.evaluate(async (arg) => {
      const load = src => new Promise((res, rej) => {
        const i = new Image(); i.onload = () => res(i); i.onerror = () => rej(new Error('decode')); i.src = src;
      });
      const ia = await load('data:image/png;base64,' + arg.a);
      const ib = await load('data:image/png;base64,' + arg.b);
      if (ia.width !== ib.width || ia.height !== ib.height) {
        return { error: 'size mismatch', a: [ia.width, ia.height], b: [ib.width, ib.height] };
      }
      const c = document.createElement('canvas');
      c.width = ia.width; c.height = ia.height;
      const g = c.getContext('2d', { willReadFrequently: true });
      g.drawImage(ia, 0, 0);
      const da = g.getImageData(0, 0, c.width, c.height).data;
      g.clearRect(0, 0, c.width, c.height);
      g.drawImage(ib, 0, 0);
      const db = g.getImageData(0, 0, c.width, c.height).data;
      let changed = 0;
      const n = c.width * c.height;
      for (let i = 0; i < n; i++) {
        const o = i * 4;
        const d = Math.max(
          Math.abs(da[o] - db[o]),
          Math.abs(da[o + 1] - db[o + 1]),
          Math.abs(da[o + 2] - db[o + 2]));
        if (d > arg.t) { changed++; }
      }
      return { changed: changed, total: n, fraction: changed / n, width: c.width, height: c.height };
    }, { a: pngA.toString('base64'), b: pngB.toString('base64'), t: threshold });
  } finally { await context.close(); }
}

async function run() {
  const job = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  const rows = [];

  for (const c of job.cases) {
    const drawn = await shoot(browser, c.drawn, c.selector);
    const empty = await shoot(browser, c.empty, c.selector);
    if (!drawn || !empty) { rows.push({ case: c.name, error: 'nothing matched ' + c.selector }); continue; }

    const delta = await changedFraction(browser, drawn, empty, job.threshold);
    rows.push({
      case: c.name,
      background: c.background,
      oldMetric: {
        drawnBytes: drawn.length,
        emptyBytes: empty.length,
        ratio: Number((drawn.length / empty.length).toFixed(3)),
      },
      newMetric: delta.error ? delta : {
        changedPixels: delta.changed,
        totalPixels: delta.total,
        fraction: Number(delta.fraction.toFixed(4)),
      },
    });
  }

  await browser.close();
  console.log(JSON.stringify({
    viewport: VIEWPORT, deviceScaleFactor: DEVICE_SCALE_FACTOR,
    channelThreshold: job.threshold, rows,
  }, null, 2));
}

run().catch(e => { console.error(e); process.exit(2); });
