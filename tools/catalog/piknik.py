# -*- coding: utf-8 -*-
"""Piknik listesi: mangal / çocuk / konum filtreleri, kişi sayısına göre miktar."""
from common import *

FILTERS = [
    filt("group", "Grup", "Kaç kişi olacaksınız?",
         [opt("small", "2-4 kişi", "people"), opt("medium", "5-8 kişi", "groups"), opt("large", "9+ kişi", "diversity_3")], "small"),
    filt("bbq", "Mangal", "Mangal yakılacak mı?", [opt("no", "Hayır"), opt("yes", "Evet", "outdoor_grill")], "yes"),
    filt("kids", "Çocuk", "Çocuk olacak mı?", [opt("no", "Hayır"), opt("yes", "Evet", "child_care")], "no"),
    filt("place", "Konum", "Nerede?",
         [opt("park", "Park / orman", "park"), opt("beach", "Sahil", "beach_access"), opt("countryside", "Bağ / köy", "landscape")], "park"),
]
SECTIONS = [sec("main", "Piknik", "outdoor_grill")]
CATEGORIES = [
    cat("food",     "Yiyecek",              "lunch_dining",      C["orange"],     "main"),
    cat("bbq",      "Mangal ve Pişirme",    "outdoor_grill",     C["red"],        "main"),
    cat("drinks",   "İçecek",               "local_drink",       C["cyan"],       "main"),
    cat("serving",  "Servis ve Sofra",      "table_restaurant",  C["amber"],      "main"),
    cat("seating",  "Oturma ve Gölge",      "chair",             C["green"],      "main"),
    cat("fun",      "Oyun ve Eğlence",      "sports_soccer",     C["purple"],     "main"),
    cat("hygiene",  "Temizlik ve Hijyen",   "sanitizer",         C["teal"],       "main"),
    cat("safety",   "Güvenlik ve Sağlık",   "health_and_safety", C["pink"],       "main"),
    cat("kids",     "Çocuk",                "child_care",        C["deeppurple"], "main"),
    cat("misc",     "Diğer",                "category",          C["grey"],       "main"),
]
BBQ = {"bbq": ["yes"]}; KIDS = {"kids": ["yes"]}; BIG = {"group": ["medium", "large"]}
items = [
    # Yiyecek
    item("bread", "Ekmek / lavaş", "food", qty=2, unit="adet", essential=True),
    item("meat", "Et / köfte / tavuk (marine)", "food", when=BBQ, qty=1, unit="kg", essential=True),
    item("sausage", "Sucuk / sosis", "food", when=BBQ, qty=1, unit="paket"),
    item("veg_grill", "Mangallık sebze (biber, domates, patlıcan, mantar)", "food", when=BBQ),
    item("cheese", "Peynir çeşitleri", "food"), item("olives", "Zeytin", "food"),
    item("salad", "Salata malzemeleri", "food"), item("fruit", "Meyve", "food", qty=2, unit="kg"),
    item("watermelon", "Karpuz / kavun", "food", when={"place": ["beach", "countryside"]}),
    item("pastry", "Börek / poğaça", "food"), item("boiled_eggs", "Haşlanmış yumurta", "food"),
    item("sandwiches", "Sandviç / dürüm", "food", when={"bbq": ["no"]}),
    item("chips", "Cips / kraker", "food"), item("nuts", "Kuruyemiş / çekirdek", "food"),
    item("dessert", "Tatlı / kek / kurabiye", "food"), item("condiments", "Ketçap, mayonez, hardal", "food"),
    item("salt_spices", "Tuz, karabiber, pul biber", "food", essential=True),
    item("butter_oil", "Tereyağı / zeytinyağı", "food"), item("lemon", "Limon", "food"),
    item("pickles", "Turşu", "food"), item("dips", "Sos / meze (humus, cacık, ezme)", "food"),
    # Mangal
    item("grill", "Mangal", "bbq", when=BBQ, essential=True), item("charcoal", "Mangal kömürü", "bbq", when=BBQ, qty=1, unit="torba", essential=True),
    item("firestarter", "Tutuşturucu / çıra", "bbq", when=BBQ), item("lighter", "Çakmak / kibrit", "bbq", when=BBQ, essential=True),
    item("tongs", "Maşa", "bbq", when=BBQ), item("grill_grate", "Izgara teli", "bbq", when=BBQ),
    item("skewers", "Şiş", "bbq", when=BBQ), item("fan", "Yelpaze / körük", "bbq", when=BBQ),
    item("foil", "Alüminyum folyo", "bbq", when=BBQ), item("grill_brush", "Izgara fırçası", "bbq", when=BBQ),
    item("cutting_board", "Kesme tahtası", "bbq"), item("knife", "Bıçak", "bbq", essential=True),
    item("heat_gloves", "Isıya dayanıklı eldiven", "bbq", when=BBQ),
    item("water_for_fire", "Ateşi söndürmek için su", "bbq", when=BBQ, essential=True),
    item("portable_stove", "Kamp ocağı / tüp", "bbq", when={"bbq": ["no"]}),
    item("teapot", "Çaydanlık / semaver", "bbq"),
    # İçecek
    item("water", "Su", "drinks", qty=(2, 0, None), unit="büyük şişe", essential=True),
    item("tea", "Çay / demlik poşet", "drinks"), item("coffee", "Kahve", "drinks"),
    item("ayran", "Ayran", "drinks"), item("soda", "Gazlı içecek / meyve suyu", "drinks"),
    item("ice", "Buz", "drinks"), item("cooler", "Buzluk / soğutucu çanta", "drinks", essential=True),
    item("ice_packs", "Buz aküsü", "drinks"), item("thermos", "Termos", "drinks"),
    # Servis
    item("plates", "Tabak", "serving", qty=(4, 0, None), unit="adet"), item("cups", "Bardak", "serving", qty=(4, 0, None), unit="adet"),
    item("cutlery", "Çatal, kaşık, bıçak", "serving", qty=(4, 0, None), unit="takım"), item("napkins", "Peçete", "serving", qty=2, unit="paket"),
    item("tablecloth", "Masa örtüsü / muşamba", "serving"), item("serving_bowls", "Servis kabı / kase", "serving"),
    item("bottle_opener", "Açacak / tirbuşon", "serving"), item("containers", "Saklama kabı", "serving"),
    item("tray", "Tepsi", "serving"), item("tea_glasses", "Çay bardağı", "serving", qty=(4, 0, None), unit="adet"),
    # Oturma
    item("blanket", "Piknik örtüsü / battaniye", "seating", qty=(1, 0, None), essential=True),
    item("chairs", "Kamp sandalyesi", "seating", qty=(2, 0, None), unit="adet"), item("table", "Katlanır masa", "seating", when=BIG),
    item("mat", "Mat / minder", "seating"), item("umbrella", "Şemsiye / tente", "seating", when={"place": ["beach"]}),
    item("hammock", "Hamak", "seating", when={"place": ["park", "countryside"]}),
    item("gazebo", "Gölgelik / gazebo", "seating", when=BIG),
    # Eğlence
    item("ball", "Top (futbol / voleybol)", "fun"), item("badminton", "Badminton / raket seti", "fun"),
    item("cards", "İskambil / okey / tavla", "fun"), item("speaker", "Bluetooth hoparlör", "fun"),
    item("frisbee", "Frizbi", "fun"), item("book", "Kitap / dergi", "fun"),
    item("camera", "Fotoğraf makinesi", "fun"), item("kite", "Uçurtma", "fun", when=KIDS),
    # Hijyen
    item("wet_wipes", "Islak mendil", "hygiene", essential=True), item("sanitizer", "El dezenfektanı", "hygiene"),
    item("trash_bags", "Çöp poşeti", "hygiene", qty=1, unit="rulo", essential=True),
    item("paper_towel", "Kağıt havlu", "hygiene"), item("toilet_paper", "Tuvalet kağıdı", "hygiene"),
    item("soap_water", "Sabun ve el yıkama suyu", "hygiene"), item("dish_soap", "Bulaşık deterjanı / sünger", "hygiene", when=BIG),
    item("towels", "Havlu", "hygiene"),
    # Güvenlik
    item("first_aid", "İlk yardım çantası", "safety", essential=True), item("sunscreen", "Güneş kremi", "safety", essential=True),
    item("insect_repellent", "Sinek / kene kovucu", "safety"), item("bite_cream", "Böcek ısırığı kremi", "safety"),
    item("hats", "Şapka", "safety"), item("sunglasses", "Güneş gözlüğü", "safety"),
    item("painkiller", "Ağrı kesici", "safety"), item("allergy_med", "Alerji ilacı", "safety"),
    item("flashlight", "El feneri", "safety", when={"place": ["park", "countryside"]}),
    item("powerbank", "Powerbank", "safety"), item("phone_charger", "Araç şarjı", "safety"),
    # Çocuk
    item("kid_snacks", "Çocuk atıştırmalıkları", "kids", when=KIDS), item("kid_toys", "Oyuncaklar / kova kürek", "kids", when=KIDS),
    item("spare_clothes", "Yedek kıyafet", "kids", when=KIDS, essential=True),
    item("kid_sunscreen", "Çocuk güneş kremi", "kids", when=KIDS), item("kid_hat", "Çocuk şapkası", "kids", when=KIDS),
    item("bubbles", "Baloncuk / tebeşir", "kids", when=KIDS), item("kid_water_bottle", "Çocuk matarası", "kids", when=KIDS),
    item("kid_meds", "Çocuk ateş düşürücü", "kids", when=KIDS),
    item("floaties", "Kolluk / can yeleği", "kids", when={"kids": ["yes"], "place": ["beach"]}),
    # Diğer
    item("cash", "Nakit para (giriş ücreti / otopark)", "misc"), item("keys", "Anahtarlar", "misc", essential=True),
    item("bags", "Yedek poşet / torba", "misc"), item("rope", "İp / mandal", "misc"),
    item("swimsuit", "Mayo / havlu", "misc", when={"place": ["beach"]}), item("spare_shoes", "Yedek terlik / ayakkabı", "misc"),
    item("multitool", "Çakı", "misc"),
]

TEMPLATE = {
    "id": "piknik", "name": "Piknik",
    "description": "Mangaldan oyuncağa: kişi sayısı, mangal ve konuma göre piknik hazırlığı.",
    "icon": "outdoor_grill", "color": "#F57C00",
    "kind": "inventory",
    "dateMode": "single", "dateLabel": "Piknik günü", "endDateLabel": None,
    "textFields": [field("place", "Yer", "Belgrad Ormanı")],
    "filters": FILTERS, "sections": SECTIONS, "categories": CATEGORIES, "items": items,
}
