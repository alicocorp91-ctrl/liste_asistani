# -*- coding: utf-8 -*-
"""Seyahat şablonu: v1'deki 259 kalem taşınır + iyileştirmeler + yeni filtreler (amaç, çocuk)."""
import json, os
from common import *

HERE = os.path.dirname(__file__)
legacy = json.load(open(os.path.join(HERE, "legacy_seyahat.json"), encoding="utf-8"))

# ── Filtreler ────────────────────────────────────────────────────────────────
FILTERS = [
    filt("gender", "Kişi Tipi", "Kimin için hazırlanıyor?",
         [opt("male", "Erkek", "man"), opt("female", "Kadın", "woman"), opt("couple", "Çift", "people")], "male"),
    filt("season", "Mevsim", "Gideceğiniz yerde mevsim nasıl?",
         [opt("spring", "İlkbahar", "local_florist"), opt("summer", "Yaz", "wb_sunny"),
          opt("autumn", "Sonbahar", "eco"), opt("winter", "Kış", "ac_unit")], "summer"),
    filt("transport", "Ulaşım", "Nasıl gideceksiniz?",
         [opt("plane", "Uçak", "flight"), opt("car", "Araba", "directions_car"),
          opt("bus", "Otobüs", "directions_bus"), opt("train", "Tren", "train")], "plane"),
    filt("tripType", "Seyahat Tipi", "Yurt içi mi, yurt dışı mı?",
         [opt("domestic", "Yurt İçi", "home"), opt("international", "Yurt Dışı", "public")], "domestic"),
    filt("purpose", "Amaç", "Seyahatin amacı ne?",
         [opt("leisure", "Tatil / Gezi", "beach_access"), opt("business", "İş", "work"),
          opt("beach", "Deniz Tatili", "pool"), opt("ski", "Kayak / Kış Sporu", "downhill_skiing"),
          opt("visit", "Aile / Arkadaş Ziyareti", "family_restroom")], "leisure"),
    filt("kids", "Çocuk", "Yanınızda çocuk var mı?",
         [opt("no", "Hayır", "person"), opt("yes", "Evet", "child_care")], "no"),
]

SECTIONS = [
    sec("valiz", "Valiz", "luggage"),
    sec("ev", "Ev Kontrolleri", "home"),
    sec("hazirlik", "Hazırlıklar", "event_note"),
]

CATEGORIES = [
    # Valiz
    cat("documents",          "Belgeler ve Para",     "description",      C["red"],        "valiz"),
    cat("documentsIntl",      "Yurt Dışı Belgeleri",  "public",           C["red"],        "valiz"),
    cat("electronics",        "Elektronik",           "devices",          C["amber"],      "valiz"),
    cat("clothingBasic",      "Temel Giyim",          "checkroom",        C["blue"],       "valiz"),
    cat("clothingMale",       "Erkek Giyim",          "man",              C["blue"],       "valiz"),
    cat("clothingFemale",     "Kadın Giyim",          "woman",            C["blue"],       "valiz"),
    cat("clothingWinter",     "Kış Giyim",            "ac_unit",          C["lightblue"],  "valiz"),
    cat("clothingSummer",     "Yaz ve Plaj",          "wb_sunny",         C["orange"],     "valiz"),
    cat("sports",             "Spor ve Aktivite",     "downhill_skiing",  C["cyan"],       "valiz"),
    cat("personalCare",       "Hijyen ve Bakım",      "soap",             C["green"],      "valiz"),
    cat("personalCareMale",   "Erkek Bakım",          "face",             C["green"],      "valiz"),
    cat("personalCareFemale", "Kadın Bakım",          "face_3",           C["green"],      "valiz"),
    cat("health",             "Sağlık ve İlaç",       "medical_services", C["teal"],       "valiz"),
    cat("kids",               "Çocuk",       "child_care",       C["pink"],       "valiz"),
    cat("transport",          "Yolculuk Konforu",     "airline_seat_recline_extra", C["purple"], "valiz"),
    cat("vehicle",            "Araç",                 "directions_car",   C["deeporange"], "valiz"),
    cat("practical",          "Pratik Eşyalar",       "handyman",         C["indigo"],     "valiz"),
    cat("intimate",           "Özel",                 "lock",             C["deeppurple"], "valiz"),
    cat("other",              "Diğer",                "category",         C["grey"],       "valiz"),
    # Ev kontrolleri
    cat("electric",  "Elektrik",  "electrical_services", C["amber"],  "ev"),
    cat("waterGas",  "Su ve Gaz", "water_drop",          C["blue"],   "ev"),
    cat("kitchen",   "Mutfak",    "kitchen",             C["orange"], "ev"),
    cat("security",  "Güvenlik",  "security",            C["red"],    "ev"),
    cat("homeOther", "Diğer",     "more_horiz",          C["grey"],   "ev"),
    # Hazırlıklar
    cat("prepDocs",     "Belgeler ve Rezervasyon", "receipt_long",           C["red"],    "hazirlik"),
    cat("prepFinance",  "Finans",                  "account_balance_wallet", C["green"],  "hazirlik"),
    cat("prepCare",     "Kişisel Bakım",           "spa",                    C["pink"],   "hazirlik"),
    cat("prepTech",     "Elektronik",              "battery_charging_full",  C["blue"],   "hazirlik"),
    cat("prepHome",     "Ev ve Alışveriş",         "shopping_cart",          C["orange"], "hazirlik"),
    cat("prepVehicle",  "Araç",                    "car_repair",             C["deeporange"], "hazirlik"),
    cat("prepTravel",   "Yolculuk",                "map",                    C["purple"], "hazirlik"),
]

# ── v1 verisini taşıma ───────────────────────────────────────────────────────
GENDER_MAP = {
    "all": None, "maleOnly": ["male"], "femaleOnly": ["female"], "coupleOnly": ["couple"],
    "maleAndCouple": ["male", "couple"], "femaleAndCouple": ["female", "couple"],
}
# v1 eşyaları için miktar kuralları (base, perDay, max)
QTY = {
    "underwear": (0, 1, 10), "socks": (0, 1, 10), "pajamas": (1, 0.15, 3),
    "tshirt_m": (0, 0.7, 7), "pants_m": (1, 0.2, 4), "jeans_m": (1, 0, 2), "shirt_m": (0, 0.5, 5),
    "boxer": (0, 1, 10), "undershirt": (0, 0.5, 5), "blouse": (0, 0.5, 5), "skirt": (1, 0.15, 3),
    "dress": (0, 0.3, 4), "leggings": (1, 0.2, 3), "bra": (1, 0.3, 4), "panties": (0, 1, 10),
    "jeans_f": (1, 0, 2), "sweater": (1, 0.2, 3), "wool_socks": (0, 0.5, 5), "towel": (1, 0, 2),
}
ESSENTIAL = {"idcard", "passport", "visa", "tickets", "hotelreservation", "phone", "phonecharger",
             "creditcard", "cash_tl", "wallet", "prescription", "driverlicense"}
NOTES = {
    "powerbank": "Uçakta mutlaka kabin bagajında taşınmalı.",
    "shampoo": "Uçak kabin bagajı için 100 ml altı şişe kullanın.",
    "passport": "Geçerlilik süresi dönüş tarihinden en az 6 ay sonra olmalı.",
    "prescription": "Reçete fotokopisini de yanınıza alın.",
    "cash_tl": "Küçük banknotlar bahşiş ve ulaşım için pratik olur.",
}
MOVE_CATEGORY = {"carcharger": "vehicle", "carphoneholder": "vehicle", "navigation": "vehicle",
                 "reçeteli ilaçlar": "health"}
DROP = {"plugadapter", "shorts_m"}          # tekrar edenler (adapter / shorts_summer zaten var)
RENAME_ID = {"reçeteli ilaçlar": "prescription"}
OVERRIDE_WHEN = {
    "suit": {"purpose": ["business"], "gender": ["male", "couple"]},
    "tie": {"purpose": ["business"], "gender": ["male", "couple"]},
    "shorts_summer": {"season": ["summer", "spring"]},
    "swimsuit_m": [{"season": ["summer"], "gender": ["male", "couple"]}, {"purpose": ["beach"], "gender": ["male", "couple"]}],
    "bikini": [{"season": ["summer"], "gender": ["female", "couple"]}, {"purpose": ["beach"], "gender": ["female", "couple"]}],
    "beach_dress": [{"season": ["summer"], "gender": ["female", "couple"]}, {"purpose": ["beach"], "gender": ["female", "couple"]}],
    "water_shoes": [{"season": ["summer"]}, {"purpose": ["beach"]}],
    "beachbag": [{"season": ["summer"]}, {"purpose": ["beach"]}],
    "sunhat": [{"season": ["summer"]}, {"purpose": ["beach"]}],
    "sandals": [{"season": ["summer", "spring"]}, {"purpose": ["beach"]}],
    "guidebook": {"purpose": ["leisure"]},
    "map": {"purpose": ["leisure"]},
    "laptop": {"purpose": ["business", "leisure", "visit"]},
    "laptopcharger": {"purpose": ["business", "leisure", "visit"]},
    "tripod": {"purpose": ["leisure", "beach"]},
    "selfiestick": {"purpose": ["leisure", "beach"]},
    "snow_boots": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "thermal_top": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "thermal_bottom": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "wool_socks": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "gloves": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "beanie": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "scarf": [{"season": ["winter"]}, {"purpose": ["ski"]}],
    "polar": [{"season": ["winter", "autumn"]}, {"purpose": ["ski"]}],
}

def legacy_when(i):
    w = {}
    g = GENDER_MAP[i["gender"]]
    if g: w["gender"] = g
    if i["seasons"]: w["season"] = i["seasons"]
    if i["transports"]: w["transport"] = i["transports"]
    if i["intl"]: w["tripType"] = ["international"]
    return w or None

items = []
seen = set()
for i in legacy["items"]:
    iid = RENAME_ID.get(i["id"], i["id"]).replace(" ", "_")
    if iid in DROP or i["id"] in DROP: continue
    catid = MOVE_CATEGORY.get(i["id"], i["category"])
    w = OVERRIDE_WHEN.get(iid, legacy_when(i))
    it = item(iid, i["name"], catid, when=w, qty=QTY.get(iid), essential=iid in ESSENTIAL, note=NOTES.get(iid))
    items.append(it); seen.add(iid)

# Ev kontrolleri (v1: filtre yok)
for c in legacy["checks"]:
    if c["id"] in ("pets",): continue  # evcil hayvan yok (kullanıcı isteği)
    catid = "homeOther" if c["category"] == "other" else c["category"]
    items.append(item("hc_" + c["id"], c["name"], catid))

# Hazırlıklar (v1) - kategori eşlemesi + gün önerisi
PREP_MAP = {
    "haircut": ("prepCare", 2), "nails": ("prepCare", 1), "skincare": ("prepCare", 2),
    "withdraw_cash": ("prepFinance", 1), "currency_exchange": ("prepFinance", 3),
    "charge_phone": ("prepTech", 0), "charge_headphones": ("prepTech", 0), "charge_powerbank": ("prepTech", 0),
    "grocery": ("prepHome", 1), "offline_maps": ("prepTravel", 1), "download_videos": ("prepTravel", 1),
}
for p in legacy["preps"]:
    catid, days = PREP_MAP.get(p["id"], ({"personalCare": "prepCare", "finance": "prepFinance", "electronics": "prepTech",
                                           "shopping": "prepHome", "travelPrep": "prepTravel"}[p["category"]], 1))
    w = {"tripType": ["international"]} if p["intl"] else None
    items.append(item("prep_" + p["id"], p["name"], catid, when=w, daysBefore=days))

# ── YENİ EŞYALAR ─────────────────────────────────────────────────────────────
NEW = [
    # Belgeler
    item("keys", "Ev / araba anahtarları", "documents", essential=True),
    item("boardingpass", "Biniş kartı (online check-in)", "documents", when={"transport": ["plane"]}, essential=True),
    item("bus_ticket_qr", "Otobüs bileti / PNR", "documents", when={"transport": ["bus"]}),
    item("train_ticket", "Tren bileti / PNR", "documents", when={"transport": ["train"]}),
    item("emergency_contacts", "Acil durum iletişim listesi", "documents"),
    item("doc_copies", "Belge fotokopileri / dijital kopyalar", "documents", note="Telefona ve buluta yedekleyin."),
    item("business_cards", "Kartvizit", "documents", when={"purpose": ["business"]}),
    item("work_docs", "Sunum / iş belgeleri", "documents", when={"purpose": ["business"]}),
    item("kid_id", "Çocuk kimliği", "documents", when={"kids": ["yes"], "tripType": ["domestic"]}, essential=True),
    item("kid_passport", "Çocuk pasaportu", "documentsIntl", when={"kids": ["yes"], "tripType": ["international"]}, essential=True),
    item("esim", "eSIM / yurt dışı hat", "documentsIntl", when={"tripType": ["international"]}),
    item("hotel_address_local", "Otel adresi (yerel dilde yazılı)", "documentsIntl", when={"tripType": ["international"]}),
    # Elektronik
    item("earbuds_case", "Kulaklık şarj kutusu", "electronics"),
    item("multi_plug", "Çoklu priz / seyahat prizi", "electronics", when={"purpose": ["business", "leisure"]}),
    item("kids_headphones", "Çocuk kulaklığı", "electronics", when={"kids": ["yes"]}),
    item("waterproof_case", "Su geçirmez telefon kılıfı", "electronics", when=[{"purpose": ["beach"]}, {"season": ["summer"]}]),
    # Giyim ekleri
    item("light_jacket", "İnce ceket / rüzgarlık", "clothingBasic", when={"season": ["spring", "autumn"]}, qty=1),
    item("rain_jacket", "Yağmurluk", "clothingBasic", when={"season": ["spring", "autumn", "winter"]}),
    item("formal_shoes", "Klasik ayakkabı", "clothingMale", when={"purpose": ["business"], "gender": ["male", "couple"]}, qty=1),
    item("formal_outfit_f", "Resmi kıyafet / takım", "clothingFemale", when={"purpose": ["business"], "gender": ["female", "couple"]}, qty=1),
    item("heels", "Topuklu ayakkabı", "clothingFemale", when={"purpose": ["business", "visit"], "gender": ["female", "couple"]}, qty=1),
    item("evening_outfit", "Gece / özel gün kıyafeti", "clothingBasic", when={"purpose": ["visit", "leisure"]}),
    item("beach_towel", "Plaj havlusu", "clothingSummer", when=[{"purpose": ["beach"]}, {"season": ["summer"]}], qty=1),
    item("snorkel", "Şnorkel / deniz gözlüğü", "clothingSummer", when={"purpose": ["beach"]}),
    item("inflatable", "Şişme deniz yatağı / simit", "clothingSummer", when={"purpose": ["beach"]}),
    item("beach_umbrella", "Plaj şemsiyesi / tente", "clothingSummer", when={"purpose": ["beach"], "transport": ["car"]}),
    item("aftersun", "Güneş sonrası losyon", "clothingSummer", when=[{"purpose": ["beach"]}, {"season": ["summer"]}]),
    item("flipflops", "Parmak arası terlik", "clothingSummer", when=[{"purpose": ["beach"]}, {"season": ["summer"]}]),
    # Spor / kayak
    item("ski_jacket", "Kayak montu", "sports", when={"purpose": ["ski"]}, essential=True),
    item("ski_pants", "Kayak pantolonu", "sports", when={"purpose": ["ski"]}),
    item("ski_goggles", "Kayak gözlüğü", "sports", when={"purpose": ["ski"]}),
    item("ski_gloves", "Kayak eldiveni (su geçirmez)", "sports", when={"purpose": ["ski"]}),
    item("balaclava", "Kar maskesi / balaklava", "sports", when={"purpose": ["ski"]}),
    item("helmet", "Kask", "sports", when={"purpose": ["ski"]}),
    item("ski_socks", "Kayak çorabı", "sports", when={"purpose": ["ski"]}, qty=(1, 0.5, 5)),
    item("hand_warmers", "El ısıtıcı paketleri", "sports", when={"purpose": ["ski"]}),
    item("lip_spf", "SPF'li dudak koruyucu", "sports", when={"purpose": ["ski"]}),
    item("ski_pass", "Kayak pasosu / ekipman kiralama rezervasyonu", "sports", when={"purpose": ["ski"]}),
    item("gym_clothes", "Spor kıyafeti", "sports", when={"purpose": ["business", "leisure"]}),
    item("hiking_shoes", "Yürüyüş ayakkabısı", "sports", when={"purpose": ["leisure"]}),
    # Hijyen
    item("wet_wipes", "Islak mendil", "personalCare"),
    item("tissues", "Kağıt mendil", "personalCare"),
    item("hand_sanitizer_mini", "Cep dezenfektanı", "personalCare"),
    item("mini_detergent", "Seyahat boy deterjan", "personalCare", note="Uzun seyahatlerde el yıkama için."),
    item("sunscreen_face", "Yüz güneş kremi", "personalCare", when=[{"season": ["summer"]}, {"purpose": ["beach", "ski"]}]),
    # Sağlık
    item("bandage_elastic", "Elastik bandaj", "health", when={"purpose": ["ski", "leisure"]}),
    item("blister_plaster", "Su toplama bandı", "health", when={"purpose": ["leisure"]}),
    item("rehydration", "Oral rehidrasyon tuzu", "health", when={"tripType": ["international"]}),
    item("health_card", "Sağlık / sigorta kartı", "health"),
    # Çocuk
    item("formula", "Mama / biberon", "kids", when={"kids": ["yes"]}),
    item("kid_clothes", "Çocuk kıyafetleri", "kids", when={"kids": ["yes"]}, qty=(1, 1.5, 12), unit="takım"),
    item("toys", "Oyuncaklar", "kids", when={"kids": ["yes"]}),
    item("kid_meds", "Çocuk ilaçları / ateş düşürücü", "kids", when={"kids": ["yes"]}, essential=True),
    item("car_seat", "Çocuk oto koltuğu", "kids", when={"kids": ["yes"], "transport": ["car"]}, essential=True),
    item("changing_mat", "Alt açma örtüsü", "kids", when={"kids": ["yes"]}),
    item("kid_snacks", "Çocuk atıştırmalıkları", "kids", when={"kids": ["yes"]}),
    item("coloring_book", "Boyama kitabı / kalemler", "kids", when={"kids": ["yes"]}),
    item("kid_tablet", "Çocuk tableti / indirilmiş çizgi filmler", "kids", when={"kids": ["yes"]}),
    item("arm_floats", "Yüzme kolluğu / can yeleği", "kids", when=[{"kids": ["yes"], "season": ["summer"]}, {"kids": ["yes"], "purpose": ["beach"]}]),
    item("potty", "Lazımlık / klozet adaptörü", "kids", when={"kids": ["yes"], "transport": ["car"]}),
    # Yolculuk konforu
    item("liquids_bag", "Sıvı poşeti (100 ml şişeler)", "transport", when={"transport": ["plane"]}),
    item("luggage_scale", "Bagaj tartısı", "transport", when={"transport": ["plane"]}),
    item("compression_socks", "Varis / uçuş çorabı", "transport", when={"transport": ["plane"], "tripType": ["international"]}),
    item("travel_pillow_kids", "Çocuk boyun yastığı", "transport", when={"kids": ["yes"], "transport": ["plane", "bus", "train"]}),
    item("packing_cubes", "Valiz düzenleyici (packing cube)", "transport"),
    item("motion_bands", "Araç tutması bilekliği", "transport", when={"transport": ["car", "bus"]}),
    # Araç
    item("car_registration", "Araç ruhsatı", "vehicle", when={"transport": ["car"]}, essential=True),
    item("car_insurance", "Trafik sigortası / kasko belgesi", "vehicle", when={"transport": ["car"]}, essential=True),
    item("hgs", "HGS / OGS etiketi", "vehicle", when={"transport": ["car"]}),
    item("spare_key", "Yedek araç anahtarı", "vehicle", when={"transport": ["car"]}),
    item("first_aid_car", "İlk yardım çantası", "vehicle", when={"transport": ["car"]}),
    item("triangle", "Reflektör / üçgen", "vehicle", when={"transport": ["car"]}),
    item("fire_ext", "Yangın tüpü", "vehicle", when={"transport": ["car"]}),
    item("snow_chains", "Kar zinciri", "vehicle", when={"transport": ["car"], "season": ["winter"]}),
    item("ice_scraper", "Buz kazıyıcı", "vehicle", when={"transport": ["car"], "season": ["winter"]}),
    item("washer_fluid", "Cam suyu", "vehicle", when={"transport": ["car"]}),
    item("car_trash", "Araç çöp poşeti", "vehicle", when={"transport": ["car"]}),
    item("sunshade", "Araç güneşliği", "vehicle", when={"transport": ["car"], "season": ["summer"]}),
    item("jumper_cables", "Takviye kablosu", "vehicle", when={"transport": ["car"]}),
    item("tire_kit", "Yedek lastik / tamir kiti kontrolü", "vehicle", when={"transport": ["car"]}),
    item("cooler_bag", "Soğutucu çanta", "vehicle", when={"transport": ["car"]}),
    # Pratik
    item("gift", "Hediye / ikramlık", "practical", when={"purpose": ["visit"]}, essential=True),
    item("reusable_bag", "Katlanır alışveriş çantası", "practical"),
    item("door_stopper", "Kapı kilidi / güvenlik alarmı", "practical", when={"tripType": ["international"]}),
    item("mini_lock", "Asma kilit (dolap / hostel)", "practical", when={"purpose": ["leisure"], "tripType": ["international"]}),
    item("laundry_sheets", "Çamaşır yıkama yaprağı", "practical", when={"purpose": ["leisure", "business"]}),
    item("binoculars", "Dürbün", "practical", when={"purpose": ["leisure"]}),
    # Ev kontrolleri ekleri
    item("hc_boiler", "Kombi / termosifonu kapat veya düşük moda al", "waterGas"),
    item("hc_dispenser", "Su sebilini kapat", "electric"),
    item("hc_laundry", "Asılı çamaşırları topla", "homeOther"),
    item("hc_fridge_door", "Buzdolabı kapısının kapalı olduğunu kontrol et", "kitchen"),
    item("hc_modem", "Modem / router (kamera yoksa) kapat", "electric"),
    item("hc_safe", "Değerli eşyaları kasaya koy", "security"),
    # Hazırlık ekleri (daysBefore = etkinlikten kaç gün önce)
    item("prep_checkin", "Online check-in yap", "prepTravel", when={"transport": ["plane"]}, daysBefore=1),
    item("prep_confirm", "Otel / bilet rezervasyonlarını teyit et", "prepDocs", daysBefore=3),
    item("prep_passport_check", "Pasaport geçerliliğini kontrol et (6 ay kuralı)", "prepDocs", when={"tripType": ["international"]}, daysBefore=45),
    item("prep_visa", "Vize başvurusu / e-vize al", "prepDocs", when={"tripType": ["international"]}, daysBefore=40),
    item("prep_insurance", "Seyahat sigortası yaptır", "prepDocs", when={"tripType": ["international"]}, daysBefore=7),
    item("prep_vaccine", "Aşı / sağlık gerekliliklerini araştır", "prepDocs", when={"tripType": ["international"]}, daysBefore=30),
    item("prep_id_kids", "Çocuk kimlik / pasaport geçerliliğini kontrol et", "prepDocs", when={"kids": ["yes"]}, daysBefore=30),
    item("prep_bank_notice", "Bankaya yurt dışı kullanım bildirimi yap", "prepFinance", when={"tripType": ["international"]}, daysBefore=3),
    item("prep_bills", "Faturaları öde / otomatik ödemeleri kontrol et", "prepFinance", daysBefore=5),
    item("prep_roaming", "Roaming / eSIM paketi al", "prepTech", when={"tripType": ["international"]}, daysBefore=2),
    item("prep_backup", "Telefon yedeğini al", "prepTech", daysBefore=1),
    item("prep_plants", "Bitki sulama düzeni kur / komşuya bırak", "prepHome", daysBefore=1),
    item("prep_laundry", "Çamaşırları yıka", "prepHome", daysBefore=2),
    item("prep_pack", "Valizi hazırla", "prepHome", daysBefore=1),
    item("prep_fridge", "Buzdolabındaki bozulacakları tüket", "prepHome", daysBefore=2),
    item("prep_car_service", "Araç bakımı / lastik / yağ kontrolü", "prepVehicle", when={"transport": ["car"]}, daysBefore=7),
    item("prep_hgs", "HGS / OGS bakiyesi yükle", "prepVehicle", when={"transport": ["car"]}, daysBefore=1),
    item("prep_fuel", "Depoyu doldur", "prepVehicle", when={"transport": ["car"]}, daysBefore=0),
    item("prep_route", "Rota / mola noktalarını planla", "prepVehicle", when={"transport": ["car"]}, daysBefore=1),
    item("prep_airport_transfer", "Havalimanı ulaşımını ayarla", "prepTravel", when={"transport": ["plane"]}, daysBefore=2),
    item("prep_seat", "Koltuk seçimi yap", "prepTravel", when={"transport": ["plane", "bus", "train"]}, daysBefore=3),
    item("prep_currency_check", "Gidilecek ülkenin para birimi / kur bilgisi", "prepFinance", when={"tripType": ["international"]}, daysBefore=5),
    item("prep_haircut_kids", "Çocuğun kıyafet / ihtiyaç listesini gözden geçir", "prepHome", when={"kids": ["yes"]}, daysBefore=3),
]
items += NEW

TEMPLATE = {
    "id": "seyahat",
    "name": "Seyahat",
    "description": "Valiz, ev kontrolleri ve seyahat öncesi hazırlıklar — kişi, mevsim, ulaşım ve amaca göre.",
    "icon": "flight_takeoff",
    "color": "#1976D2",
    "dateMode": "range",
    "dateLabel": "Gidiş tarihi",
    "endDateLabel": "Dönüş tarihi",
    "textFields": [field("from", "Nereden", "İstanbul"), field("to", "Nereye", "Antalya")],
    "filters": FILTERS,
    "sections": SECTIONS,
    "categories": CATEGORIES,
    "items": items,
}
