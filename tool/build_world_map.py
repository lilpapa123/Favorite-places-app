"""Builds assets/maps/world.json from the design's World map artboard.

The design (WorldMap.dc.html) draws Natural Earth 1:50m in Mercator, 1308.2 x
874 at zoom 1, with every larger country split into 5-6 regions. This copies
its country shapes and region cells as they are, so the app matches it.

Run: python3 tool/build_world_map.py WorldMap.dc.html codes.json assets/maps/world.json
codes.json maps Natural Earth names to ISO 3166 alpha-2 codes (from
world-atlas ids with i18n-iso-countries).
"""
import json
import re
import sys

html, codes_file, out_file = sys.argv[1:4]
s = open(html).read()
codes = json.load(open(codes_file))
# Natural Earth places without an ISO code, counted with their country.
codes.update({'Kosovo': 'XK', 'Somaliland': 'SO', 'N. Cyprus': 'CY',
              'Indian Ocean Ter.': 'AU', 'Siachen Glacier': 'IN'})

def label_point(d):
    """Where the name goes, the middle of the country's biggest piece, and
    that piece's width, so a name only shows where it fits."""
    best, best_area = None, -1
    for ring in d.split('M')[1:]:
        pts = [tuple(map(float, p.split(','))) for p in ring.rstrip('Z').split('L')]
        a = cx = cy = 0
        for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
            cross = x0 * y1 - x1 * y0
            a += cross
            cx += (x0 + x1) * cross
            cy += (y0 + y1) * cross
        if a and abs(a) > best_area:
            xs = [x for x, _ in pts]
            best_area, best = abs(a), [round(cx / (3 * a), 1), round(cy / (3 * a), 1),
                                       round(max(xs) - min(xs), 1)]
    return best or [0, 0, 0]


countries = {}
for i, d, title in re.findall(
        r'<path id="wdc(\d+)" d="([^"]*)"><title>([^<]*)</title>', s):
    name = title.removesuffix(', visited')
    countries[int(i)] = {'name': name, 'code': codes[name], 'd': d, 'label': label_point(d), 'cells': []}

regions = s[s.index('data-regions="1"'):]
regions = regions[:regions.index('</g>\n')]
for i, d in re.findall(r'clip-path="url\(#wdkc(\d+)\)"><path d="([^"]*)"', regions):
    countries[int(i)]['cells'] = ['M' + c for c in d.split('M')[1:]]

grat = re.search(
    r'<path d="([^"]*)" fill="none" stroke="rgba\(42,124,19,0.08\)"', s).group(1)
out = {
    'w': 1308.2, 'h': 874,
    # Mercator: x = 654.1 + 208.2 * lon, y = 613.9 - 208.2 * ln(tan(45 + lat/2)).
    'scale': 1308.2 / (2 * 3.141592653589793), 'translate': [654.1, 613.9],
    # Opens on Europe, as the design does.
    'startX': 499.4,
    'total': 195,
    'grat': grat,
    'countries': [countries[i] for i in sorted(countries)],
}
json.dump(out, open(out_file, 'w'), separators=(',', ':'))
print(len(out['countries']), 'countries,',
      sum(len(c['cells']) for c in out['countries']), 'regions')
