// 그림 렌더러 본체: node tools/render.js <svg>... (render.py 가 호출한다)
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
(async () => {
  const pairs = process.argv.slice(2);
  const b = await chromium.launch();
  for (let i = 0; i < pairs.length; i += 2) {
    const svg = fs.readFileSync(pairs[i], 'utf8');
    const m = svg.match(/viewBox="\s*0\s+0\s+([\d.]+)\s+([\d.]+)"/);
    if (!m) { console.error('viewBox 없음: ' + pairs[i]); process.exitCode = 1; continue; }
    const w = Math.round(+m[1]), h = Math.round(+m[2]);
    const pg = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    await pg.setContent('<html><head><style>html,body{margin:0;background:#fff}svg{display:block;width:' + w + 'px;height:' + h + 'px}</style></head><body>' + svg + '</body></html>');
    await pg.evaluate(() => document.fonts.ready);
    await pg.locator('svg').first().screenshot({ path: pairs[i + 1] });
    await pg.close();
    console.log(path.basename(pairs[i]) + '  →  ' + path.basename(pairs[i + 1]) + ' (' + w * 2 + 'x' + h * 2 + ')');
  }
  await b.close();
})();
