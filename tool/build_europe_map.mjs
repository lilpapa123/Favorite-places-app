// Builds assets/maps/europe.json from Natural Earth 1:50m (world-atlas), with
// the projection and 5-6 generated regions per country of the design.
// Run: npm i d3-geo d3-delaunay topojson-client world-atlas, then
// node tool/build_europe_map.mjs assets/maps/europe.json. Country codes are
// added afterwards (see the "code" field).
import fs from 'node:fs';
import { geoAzimuthalEqualArea, geoPath, geoGraticule10, geoContains, geoCentroid } from 'd3-geo';
import { Delaunay } from 'd3-delaunay';
import { feature } from 'topojson-client';
const topo = JSON.parse(fs.readFileSync(new URL('node_modules/world-atlas/countries-50m.json', import.meta.url)));
const countries = feature(topo, topo.objects.countries).features;
const W = 402, H = 874;
const proj = geoAzimuthalEqualArea().rotate([-12, -53]).clipExtent([[0, 0], [W, H]]);
proj.fitExtent([[6, 190], [W - 6, 590]], { type: 'MultiPoint', coordinates: [[-10, 36], [34, 36], [-10, 62], [30, 66], [40, 48]] });
const path = geoPath(proj).digits(1);
let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const isEurope = f => { const [lon, lat] = geoCentroid(f); return f.properties.name === 'Russia' || (lat > 35 && lon > -25 && lon < 45); };
const out = { w: W, h: H, scale: proj.scale(), translate: proj.translate(), center: [12, 53], grat: path(geoGraticule10()), countries: [] };
for (const f of countries) {
  const d = path(f); if (!d) continue;
  const c = { name: f.properties.name, id: f.id ?? null, d, centers: [], cells: [] };
  const [[x0, y0], [x1, y1]] = path.bounds(f);
  const area = path.area(f);
  if (isEurope(f) && area > 90) {
    const k = area > 3000 ? 6 : 5;
    const pts = [];
    for (let i = 0; i < 2500 && pts.length < 400; i++) {
      const x = x0 + rnd() * (x1 - x0), y = y0 + rnd() * (y1 - y0);
      const g = proj.invert([x, y]);
      if (g && geoContains(f, g)) pts.push([x, y]);
    }
    if (pts.length >= k * 4) {
      let cen = pts.slice(0, k).map(p => p.slice());
      for (let it = 0; it < 25; it++) {
        const sum = cen.map(() => [0, 0, 0]);
        for (const p of pts) { let b = 0, bd = 1e9; cen.forEach((q, j) => { const dd = (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2; if (dd < bd) { bd = dd; b = j; } }); sum[b][0] += p[0]; sum[b][1] += p[1]; sum[b][2]++; }
        cen = cen.map((q, j) => sum[j][2] ? [sum[j][0] / sum[j][2], sum[j][1] / sum[j][2]] : q);
      }
      const vor = Delaunay.from(cen).voronoi([x0 - 2, y0 - 2, x1 + 2, y1 + 2]);
      c.centers = cen.map(p => p.map(v => +v.toFixed(1)));
      c.cells = cen.map((_, j) => 'M' + vor.cellPolygon(j).map(p => p.map(v => v.toFixed(1)).join(',')).join('L') + 'Z');
    }
  }
  out.countries.push(c);
}
fs.writeFileSync(process.argv[2], JSON.stringify(out));
const pins = { Istanbul: [28.98, 41.01], Lisbon: [-9.14, 38.72], Rome: [12.5, 41.9] };
console.log(JSON.stringify({ scale: out.scale, translate: out.translate, pins: Object.fromEntries(Object.entries(pins).map(([k, c]) => [k, proj(c)])) }));
console.log('countries', out.countries.length, 'divided', out.countries.filter(c => c.cells.length).length, 'regions', out.countries.reduce((a, c) => a + c.cells.length, 0), Math.round(fs.statSync(process.argv[2]).size / 1024) + 'KB');
