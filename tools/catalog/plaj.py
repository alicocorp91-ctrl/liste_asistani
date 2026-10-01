# -*- coding: utf-8 -*-
"""Plaj günü listesi: kiminle / ne kadar / aktivite filtreleri. Tek günlük, kontrol listesi."""
from common import *

FILTERS = [
    filt("who", "Kimler", "Kimler gidiyor?",
         [opt("solo", "Tek / çift", "person"), opt("family", "Aile", "family_restroom"), opt("friends", "Arkadaş grubu", "groups")], "family"),
    filt("kids", "Çocuk", "Çocuk olacak mı?", [opt("no", "Hayır"), opt("yes", "Evet", "child_care")], "no"),
    filt("duration", "Süre", "Ne kadar kalınacak?",
         [opt("half", "Yarım gün", "wb_sunny"), opt("full", "Tüm gün", "beach_access")], "full"),
    filt("activity", "Aktivite", "Ne yapılacak?",
         [opt("swim", "Yüzme / güneşlenme", "pool"), opt("snorkel", "Şnorkel / dalış", "scuba_diving"), opt("sport", "Spor (voleybol, raket)", "sports_volleyball")], "swim"),
    filt("food", "Yemek", "Yemek nasıl?",
         [opt("bring", "Evden götürülecek", "lunch_dining"), opt("buy", "Orada alınacak", "storefront")], "bring"),
]
SECTIONS = [sec("main", "Plaj", "beach_access")]
CATEGORIES = [
    cat("sun",      "Güneş Koruma",        "wb_sunny",          C["amber"],      "main"),
    cat("swim",     "Yüzme ve Havlu",      "pool",              C["cyan"],       "main"),
    cat("comfort",  "Oturma ve Gölge",     "beach_access",      C["orange"],     "main"),
    cat("food",     "Yiyecek ve İçecek",   "local_drink",       C["green"],      "main"),
    cat("gear",     "Aktivite Ekipmanı",   "sports_volleyball", C["blue"],       "main"),
    cat("care",     "Bakım ve Hijyen",     "sanitizer",         C["teal"],       "main"),
    cat("kids",     "Çocuk",               "child_care",        C["deeppurple"], "main"),
    cat("misc",     "Diğer",               "category",          C["grey"],       "main"),
]
KIDS = {"kids": ["yes"]}; FULL = {"duration": ["full"]}; BRING = {"food": ["bring"]}
items = [
    # Güneş
    item("sunscreen", "Güneş kremi (SPF 30+)", "sun", essential=True),
    item("after_sun", "Güneş sonrası losyon / aloe vera", "sun"),
    item("sunglasses", "Güneş gözlüğü", "sun", essential=True),
    item("hat", "Şapka", "sun", essential=True),
    item("lip_balm", "Güneş korumalı dudak kremi", "sun"),
    item("umbrella", "Plaj şemsiyesi", "sun", when=FULL),
    item("sun_tent", "Gölgelik / plaj çadırı", "sun", when=[{"kids": ["yes"]}, {"who": ["family"]}]),
    # Yüzme
    item("swimsuit", "Mayo / bikini / şort", "swim", essential=True),
    item("spare_swimsuit", "Yedek mayo", "swim", when=FULL),
    item("towel", "Plaj havlusu", "swim", qty=(1, 0, None), unit="adet", essential=True),
    item("small_towel", "Küçük havlu / peştemal", "swim"),
    item("flipflops", "Terlik", "swim", essential=True),
    item("water_shoes", "Deniz ayakkabısı (taşlı plaj)", "swim"),
    item("goggles", "Yüzücü gözlüğü", "swim"),
    item("swim_cap", "Bone", "swim"),
    item("dry_bag", "Islak eşya poşeti / kuru çanta", "swim"),
    item("change_clothes", "Dönüş için kuru kıyafet / iç çamaşırı", "swim", essential=True),
    item("cover_up", "Pareo / plaj elbisesi", "swim"),
    # Oturma
    item("mat", "Plaj matı / hasır", "comfort", essential=True),
    item("chair", "Katlanır plaj sandalyesi", "comfort", when=FULL),
    item("cooler", "Soğutucu çanta / buzluk", "comfort", when=FULL, essential=True),
    item("ice_packs", "Buz aküsü", "comfort", when=FULL),
    item("beach_bag", "Plaj çantası", "comfort", essential=True),
    item("pillow", "Şişme yastık", "comfort"),
    item("blanket", "Örtü / ince battaniye (akşam serinliği)", "comfort", when=FULL),
    # Yiyecek
    item("water", "Su", "food", qty=(1, 0, None), unit="büyük şişe", essential=True),
    item("cold_drinks", "Soğuk içecek / ayran / meyve suyu", "food"),
    item("fruit", "Meyve (karpuz, kavun, üzüm)", "food", when=BRING),
    item("sandwiches", "Sandviç / dürüm / börek", "food", when=BRING),
    item("snacks", "Atıştırmalık (kraker, kuruyemiş)", "food"),
    item("salt_snack", "Tuzlu atıştırmalık (terleme için)", "food", when=FULL),
    item("cutlery", "Tabak, çatal, bardak", "food", when=BRING),
    item("napkins", "Peçete / kağıt havlu", "food", when=BRING),
    item("cash", "Nakit para (büfe, şezlong, otopark)", "food", when={"food": ["buy"]}, essential=True),
    item("thermos", "Termos (çay / kahve)", "food"),
    # Aktivite
    item("snorkel", "Şnorkel + maske", "gear", when={"activity": ["snorkel"]}, essential=True),
    item("fins", "Palet", "gear", when={"activity": ["snorkel"]}),
    item("ball", "Plaj topu / voleybol topu", "gear", when={"activity": ["sport"]}),
    item("rackets", "Plaj raketi", "gear", when={"activity": ["sport"]}),
    item("frisbee", "Frizbi", "gear", when={"who": ["friends", "family"]}),
    item("float", "Şişme deniz yatağı / simit", "gear"),
    item("pump", "Şişirme pompası", "gear"),
    item("speaker", "Bluetooth hoparlör", "gear", when={"who": ["friends"]}),
    item("book", "Kitap / dergi / kulaklık", "gear"),
    item("waterproof_case", "Su geçirmez telefon kılıfı", "gear"),
    item("camera", "Fotoğraf makinesi / aksiyon kamerası", "gear"),
    item("powerbank", "Powerbank", "gear", when=FULL),
    # Bakım
    item("wet_wipes", "Islak mendil", "care", essential=True),
    item("hand_sanitizer", "El dezenfektanı", "care"),
    item("trash_bags", "Çöp poşeti", "care", essential=True),
    item("zip_bags", "Kilitli poşet (telefon, anahtar)", "care"),
    item("first_aid", "Küçük ilk yardım seti (yara bandı, antiseptik)", "care"),
    item("sting_relief", "Denizanası / böcek sokması kremi", "care"),
    item("hair_brush", "Tarak / saç tokası", "care"),
    item("deodorant", "Deodorant", "care"),
    item("tissues", "Kağıt mendil", "care"),
    item("talc", "Kumu temizlemek için talk pudrası", "care", when=KIDS),
    # Çocuk
    item("kid_sunscreen", "Çocuk güneş kremi (SPF 50)", "kids", when=KIDS, essential=True),
    item("kid_swim", "Çocuk mayosu / UV t-shirt", "kids", when=KIDS, essential=True),
    item("kid_hat", "Çocuk şapkası", "kids", when=KIDS, essential=True),
    item("armbands", "Kolluk / can yeleği", "kids", when=KIDS, essential=True),
    item("sand_toys", "Kum oyuncakları (kova, kürek)", "kids", when=KIDS),
    item("kid_snacks", "Çocuk atıştırmalıkları", "kids", when=KIDS),
    item("kid_change", "Yedek çocuk kıyafeti", "kids", when=KIDS, qty=2, unit="takım"),
    item("kid_towel", "Çocuk havlusu / pançosu", "kids", when=KIDS),
    # Diğer
    item("keys_wallet", "Anahtar, cüzdan, kimlik", "misc", essential=True),
    item("phone", "Telefon (şarjı dolu)", "misc", essential=True),
    item("parking", "Otopark / plaj giriş bilgisi", "misc", note="Rezervasyon gerekiyorsa önceden kontrol et"),
    item("spare_bag", "Yedek poşet / file", "misc"),
    item("sweater", "Hırka / ince mont (akşam)", "misc", when=FULL),
]

TEMPLATE = {
    "id": "plaj", "name": "Plaj",
    "description": "Deniz günü için güneş koruma, yüzme, çocuk ve aktivite ekipmanı; akşam dönüşü unutulanlar dahil.",
    "icon": "beach_access", "color": "#00ACC1",
    "dateMode": "single", "dateLabel": "Plaj günü", "endDateLabel": None,
    "textFields": [field("place", "Plaj / yer", "İsteğe bağlı")],
    "filters": FILTERS, "sections": SECTIONS, "categories": CATEGORIES, "items": items,
}
