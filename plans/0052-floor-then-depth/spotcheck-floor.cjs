// SPOT-CHECK SC1's browser half: does the repaired floor survive every
// background this backend ships, and can it still tell a drawing from nothing?
//
// Four case kinds, and the pass needs all four. A probe that only showed the
// new metric working would not be a spot-check, it would be an announcement.
//
//   separate  a DRAWN document against an EMPTY one of the same set. The new
//             fraction must clear the floor and the old ratio is reported
//             beside it, so the case that broke the old metric is visible
//             rather than described.
//   noise     one EMPTY document against a SECOND capture of ITSELF. This is
//             what justifies a per-channel threshold of 12 rather than 1: a
//             WebGL canvas is not bit-identical between two contexts, and a
//             floor that counted that noise as drawing would pass over a blank
//             page. Must score ~0.
//   blind     the OLD metric on a painted background, reported against the
//             floor it used to carry. This is the red, kept runnable.
//   dark      a document whose DRAWING has been corrupted - not removed - so
//             only the browser can see it. Must fall UNDER the floor.
//
// The same decode-in-the-browser trick tests/browser/smoke.cjs uses, for the
// same reason: the harness declares one dependency and a PNG library would be
// a second.

const fs = require('fs');

// Resolved from where the DRIVER says it is, not from this file's own
// node_modules. This script lives in the harness repository and the browser it
// drives is installed in the renderer's, so `require('playwright')` looks in
// the wrong tree - node resolves from the script's directory and never from the
// working one. The driver passes the path; nothing here guesses at a layout.
const { chromium } = require(process.env.PSGR_PLAYWRIGHT || 'playwright');

const VIEWPORT = { width: 1280, height: 900 };
const DEVICE_SCALE_FACTOR = 1;
const SETTLE_MS = 1400;

async function openPage(browser) {
  const context = await browser.newContext({ viewport: VIEWPORT, deviceScaleFactor: DEVICE_SCALE_FACTOR });
  const attempted = [];
  await context.route('http://**', route => { attempted.push(route.request().url()); route.abort(); });
  await context.route('https://**', route => { attempted.push(route.request().url()); route.abort(); });
  const page = await context.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') { errors.push(m.text()); } });
  page.on('pageerror', e => errors.push('uncaught: ' + e.message));
  return { context, page, errors, attempted };
}

async function shoot(browser, file, selector) {
  const { context, page, errors } = await openPage(browser);
  try {
    await page.goto('file:///' + file.split('\\').join('/'));
    await page.waitForTimeout(SETTLE_MS);
    const handle = await page.$(selector);
    if (!handle) { return { png: null, errors }; }
    return { png: await handle.screenshot({ type: 'png' }), errors };
  } finally { await context.close(); }
}

async function changedFraction(browser, a, b, threshold) {
  const { context, page } = await openPage(browser);
  try {
    await page.goto('about:blank');
    return await page.evaluate(async (arg) => {
      const load = src => new Promise((res, rej) => {
        const i = new Image();
        i.onload = () => res(i);
        i.onerror = () => rej(new Error('decode failed'));
        i.src = src;
      });
      const ia = await load('data:image/png;base64,' + arg.a);
      const ib = await load('data:image/png;base64,' + arg.b);
      if (ia.width !== ib.width || ia.height !== ib.height) {
        return { error: 'size mismatch ' + ia.width + 'x' + ia.height + ' vs ' + ib.width + 'x' + ib.height };
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
      const total = c.width * c.height;
      for (let i = 0; i < total; i++) {
        const o = i * 4;
        const d = Math.max(
          Math.abs(da[o] - db[o]),
          Math.abs(da[o + 1] - db[o + 1]),
          Math.abs(da[o + 2] - db[o + 2]));
        if (d > arg.t) { changed++; }
      }
      return { changed: changed, total: total, fraction: changed / total };
    }, { a: a.toString('base64'), b: b.toString('base64'), t: threshold });
  } finally { await context.close(); }
}

async function run() {
  const job = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  const browser = await chromium.launch();
  const rows = [];
  let failed = 0;

  function record(row, ok, why) {
    row.ok = ok;
    if (!ok) { row.why = why; failed++; }
    rows.push(row);
  }

  for (const c of job.cases) {
    const first = await shoot(browser, c.a, c.selector);
    const second = await shoot(browser, c.b, c.selector);
    if (!first.png || !second.png) {
      record({ case: c.name, kind: c.kind }, false, 'nothing matched ' + c.selector);
      continue;
    }

    const diff = await changedFraction(browser, first.png, second.png, job.threshold);
    const row = {
      case: c.name,
      kind: c.kind,
      note: c.note,
      aBytes: first.png.length,
      bBytes: second.png.length,
      ratio: Number((first.png.length / second.png.length).toFixed(3)),
      fraction: diff.error ? null : Number(diff.fraction.toFixed(5)),
      floor: c.floor === undefined ? null : c.floor,
    };
    if (diff.error) { record(row, false, diff.error); continue; }

    if (c.kind === 'separate') {
      record(row, diff.fraction >= c.floor,
        'the drawn view changed ' + row.fraction + ' of the rectangle and the floor is ' + c.floor);
    } else if (c.kind === 'noise') {
      // Two captures of the SAME document. Anything above the ceiling means
      // the threshold is counting compositor noise as drawing.
      record(row, diff.fraction <= c.ceiling,
        'two captures of one empty document differ in ' + row.fraction
        + ' of the rectangle and the ceiling is ' + c.ceiling);
      row.ceiling = c.ceiling;
    } else if (c.kind === 'blind') {
      // The RED, kept runnable: the old byte ratio, on a painted background,
      // against the floor it used to carry. Passing here means the old metric
      // really would have failed a correct page.
      record(row, row.ratio < c.oldFloor,
        'the old ratio came out at ' + row.ratio + ', which is NOT under the ' + c.oldFloor
        + ' it used to require - so this case no longer demonstrates the blindness');
      row.oldFloor = c.oldFloor;
    } else if (c.kind === 'dark') {
      // Falsification: the drawing corrupted rather than removed, so every
      // PowerShell assertion still passes and only the browser can tell.
      record(row, diff.fraction < c.floor,
        'a corrupted drawing still changed ' + row.fraction + ' of the rectangle, which clears the floor of '
        + c.floor + ' - the gate cannot see a page that stopped drawing');
    } else {
      record(row, false, 'unknown case kind ' + c.kind);
    }
  }

  await browser.close();
  console.log(JSON.stringify({
    viewport: VIEWPORT, deviceScaleFactor: DEVICE_SCALE_FACTOR,
    channelThreshold: job.threshold, cases: rows.length, failed, rows,
  }, null, 2));
  process.exit(failed ? 1 : 0);
}

run().catch(e => { console.error(e); process.exit(2); });
