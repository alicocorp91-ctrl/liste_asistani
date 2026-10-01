# -*- coding: utf-8 -*-
"""
Katalog şeması ve yardımcılar.

Şablon (template) JSON yapısı:
{
  "id", "name", "description", "icon", "color",
  "kind": "checklist" | "inventory",   # inventory = malzeme/stok listesi (stokta / eksik takibi)
  "preselect": true|false,             # false: öneri ekranında hiçbir kalem ön seçili gelmez (market)
  "quickAdd": true|false,              # true: liste ekranının altında hızlı ekleme çubuğu (market)
  "dateMode": "none" | "single" | "range",
  "dateLabel", "endDateLabel",
  "textFields": [{"id","label","hint"}],
  "filters":    [{"id","label","question","options":[{"id","label","icon"}],"default"}],
  "sections":   [{"id","name","icon"}],
  "categories": [{"id","name","icon","color","section"}],
  "items":      [{"id","name","category","when":{filterId:[optionId,...]},
                  "qty":{"base","perDay","max"} | null, "unit", "essential", "note", "daysBefore"}]
}

Kurallar:
- "when" boş/yok  -> her koşulda önerilir. Aynı filtre içinde VEYA, filtreler arası VE.
- "qty" null      -> sadece işaretlenebilir (miktar gösterilmez).
- "daysBefore"    -> tarihli listelerde hatırlatıcı önerisi (etkinlik tarihinden N gün önce).
- "kind"          -> "inventory" ise her kalemde gereken miktar + stok miktarı tutulur,
                     eksikler vurgulanır ve market listesine aktarılabilir. Yoksa "checklist".
"""
import json, os, re

# Renk paleti (Material)
C = {
    "blue": "#448AFF", "indigo": "#5C6BC0", "teal": "#26A69A", "green": "#66BB6A", "lightgreen": "#9CCC65",
    "amber": "#FFC107", "orange": "#FF9800", "deeporange": "#FF7043", "red": "#EF5350", "pink": "#EC407A",
    "purple": "#AB47BC", "deeppurple": "#7E57C2", "cyan": "#26C6DA", "brown": "#8D6E63", "grey": "#9E9E9E",
    "lime": "#D4E157", "bluegrey": "#78909C", "lightblue": "#29B6F6",
}

def item(id, name, category, when=None, qty=None, unit=None, essential=False, note=None, daysBefore=None):
    d = {"id": id, "name": name, "category": category}
    if when: d["when"] = when
    if qty is not None:
        if isinstance(qty, int):
            d["qty"] = {"base": qty, "perDay": 0, "max": None}
        else:
            base, perDay, mx = qty
            d["qty"] = {"base": base, "perDay": perDay, "max": mx}
    if unit: d["unit"] = unit
    if essential: d["essential"] = True
    if note: d["note"] = note
    if daysBefore is not None: d["daysBefore"] = daysBefore
    return d

def cat(id, name, icon, color, section):
    return {"id": id, "name": name, "icon": icon, "color": color, "section": section}

def sec(id, name, icon):
    return {"id": id, "name": name, "icon": icon}

def opt(id, label, icon=None):
    d = {"id": id, "label": label}
    if icon: d["icon"] = icon
    return d

def filt(id, label, question, options, default):
    return {"id": id, "label": label, "question": question, "options": options, "default": default}

def field(id, label, hint=""):
    return {"id": id, "label": label, "hint": hint}

def validate(t):
    errs = []
    ids = set()
    for k in ("id", "name", "icon", "color", "dateMode", "sections", "categories", "items"):
        if k not in t: errs.append(f"{t.get('id')}: eksik alan {k}")
    sec_ids = {s["id"] for s in t["sections"]}
    cat_ids = {}
    for c in t["categories"]:
        if c["section"] not in sec_ids: errs.append(f"{t['id']}: kategori {c['id']} bilinmeyen bölüm {c['section']}")
        if c["id"] in cat_ids: errs.append(f"{t['id']}: tekrar kategori {c['id']}")
        cat_ids[c["id"]] = c
    filt_opts = {f["id"]: {o["id"] for o in f["options"]} for f in t.get("filters", [])}
    for f in t.get("filters", []):
        if f["default"] not in filt_opts[f["id"]]: errs.append(f"{t['id']}: filtre {f['id']} varsayılanı geçersiz")
    for it in t["items"]:
        if it["id"] in ids: errs.append(f"{t['id']}: tekrar eşya id {it['id']}")
        ids.add(it["id"])
        if not re.match(r"^[a-z0-9_]+$", it["id"]): errs.append(f"{t['id']}: geçersiz id {it['id']}")
        if it["category"] not in cat_ids: errs.append(f"{t['id']}: {it['id']} bilinmeyen kategori {it['category']}")
        w = it.get("when")
        blocks = w if isinstance(w, list) else ([w] if w else [])
        for block in blocks:
            for fid, vals in block.items():
                if fid not in filt_opts: errs.append(f"{t['id']}: {it['id']} bilinmeyen filtre {fid}")
                else:
                    for v in vals:
                        if v not in filt_opts[fid]: errs.append(f"{t['id']}: {it['id']} filtre {fid} bilinmeyen seçenek {v}")
    # boş kategori uyarısı
    used = {it["category"] for it in t["items"]}
    for cid in cat_ids:
        if cid not in used: errs.append(f"{t['id']}: UYARI boş kategori {cid}")
    return errs

def write(t, out_dir):
    t.setdefault("kind", "checklist")
    t.setdefault("preselect", True)
    t.setdefault("quickAdd", False)
    assert t["kind"] in ("checklist", "inventory"), f"{t['id']}: geçersiz kind {t['kind']}"
    errs = validate(t)
    hard = [e for e in errs if "UYARI" not in e]
    for e in errs: print("  ", e)
    if hard: raise SystemExit(f"{t['id']}: {len(hard)} hata")
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"{t['id']}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(t, f, ensure_ascii=False, indent=1)
    print(f"✔ {t['id']}: {len(t['items'])} eşya, {len(t['categories'])} kategori, {len(t['sections'])} bölüm -> {path}")
    return t
