# -*- coding: utf-8 -*-
"""Tüm şablonları assets/data/templates/ altına JSON olarak üretir.  Çalıştır: python3 tools/catalog/gen.py"""
import os, sys, json
sys.path.insert(0, os.path.dirname(__file__))
from common import write
import seyahat, market, piknik, mangal, kamp, plaj, tasinma

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "data", "templates")
mods = [seyahat, market, piknik, mangal, kamp, plaj, tasinma]
index = []
total = 0
for m in mods:
    t = write(m.TEMPLATE, OUT)
    total += len(t["items"])
    index.append(t["id"])
with open(os.path.join(OUT, "index.json"), "w", encoding="utf-8") as f:
    json.dump(index, f)
# ikon envanteri (Dart tarafı için)
icons = set()
for m in mods:
    t = m.TEMPLATE
    icons.add(t["icon"])
    for s in t["sections"]: icons.add(s["icon"])
    for c in t["categories"]: icons.add(c["icon"])
    for f in t.get("filters", []):
        for o in f["options"]:
            if o.get("icon"): icons.add(o["icon"])
with open(os.path.join(os.path.dirname(__file__), "icons_used.txt"), "w") as f:
    f.write("\n".join(sorted(icons)))
print(f"\nTOPLAM: {total} eşya, {len(icons)} farklı ikon")
