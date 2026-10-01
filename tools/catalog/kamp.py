# -*- coding: utf-8 -*-
"""Kamp listesi: kamp tipi, mevsim, ulaşım ve çocuk filtreleri; gün sayısına göre miktar."""
from common import *

FILTERS = [
    filt("campType", "Kamp Tipi", "Nasıl konaklayacaksınız?",
         [opt("tent", "Çadır", "holiday_village"), opt("caravan", "Karavan / araç", "airport_shuttle"),
          opt("bungalow", "Bungalov / kamp alanı", "cabin")], "tent"),
    filt("season", "Mevsim", "Hangi mevsim?",
         [opt("summer", "Yaz", "wb_sunny"), opt("spring_autumn", "İlkbahar / Sonbahar", "eco"), opt("winter", "Kış", "ac_unit")], "summer"),
    filt("access", "Ulaşım", "Kamp yerine nasıl ulaşacaksınız?",
         [opt("car", "Araçla", "directions_car"), opt("hike", "Yürüyerek (sırt çantası)", "hiking")], "car"),
    filt("kids", "Çocuk", "Çocuk olacak mı?", [opt("no", "Hayır"), opt("yes", "Evet", "child_care")], "no"),
    filt("water", "Su Kaynağı", "Kamp alanında su / tuvalet var mı?",
         [opt("yes", "Var (tesisli)", "water_drop"), opt("no", "Yok (doğa kampı)", "forest")], "yes"),
]
SECTIONS = [sec("gear", "Ekipman", "backpack"), sec("food", "Yiyecek ve Mutfak", "restaurant"), sec("prep", "Hazırlık", "event_note")]
CATEGORIES = [
    cat("shelter",   "Barınma",                "holiday_village",   C["green"],      "gear"),
    cat("sleep",     "Uyku",                   "bed",               C["indigo"],     "gear"),
    cat("clothing",  "Giyim",                  "checkroom",         C["blue"],       "gear"),
    cat("light",     "Aydınlatma ve Enerji",   "flashlight_on",     C["amber"],      "gear"),
    cat("tools",     "Araç Gereç",             "construction",      C["deeporange"], "gear"),
    cat("nav",       "Navigasyon ve Belgeler", "explore",           C["red"],        "gear"),
    cat("hygiene",   "Hijyen ve Sağlık",       "medical_services",  C["teal"],       "gear"),
    cat("kids",      "Çocuk",                  "child_care",        C["pink"],       "gear"),
    cat("fun",       "Aktivite",               "hiking",            C["purple"],     "gear"),
    cat("kitchen",   "Mutfak Ekipmanı",        "outdoor_grill",     C["orange"],     "food"),
    cat("foodstuff", "Yiyecek",                "lunch_dining",      C["lime"],       "food"),
    cat("drinks",    "Su ve İçecek",           "local_drink",       C["cyan"],       "food"),
    cat("prepList",  "Kamp Öncesi",            "checklist",         C["bluegrey"],   "prep"),
]
TENT = {"campType": ["tent"]}; NOTENT = {"campType": ["caravan", "bungalow"]}
COLD = {"season": ["winter", "spring_autumn"]}; WINTER = {"season": ["winter"]}; SUMMER = {"season": ["summer"]}
HIKE = {"access": ["hike"]}; CAR = {"access": ["car"]}; KIDS = {"kids": ["yes"]}; NOWATER = {"water": ["no"]}
items = [
    # Barınma
    item("tent", "Çadır", "shelter", when=TENT, essential=True), item("tent_pegs", "Çadır kazığı (yedekli)", "shelter", when=TENT),
    item("mallet", "Tokmak", "shelter", when={"campType": ["tent"], "access": ["car"]}), item("footprint", "Çadır altı örtüsü / branda", "shelter", when=TENT),
    item("tarp", "Tente / tarp + ip", "shelter"), item("guy_lines", "Yedek ip / paracord", "shelter"),
    item("tent_repair", "Çadır tamir kiti", "shelter", when=TENT), item("caravan_hookup", "Karavan elektrik / su bağlantı seti", "shelter", when={"campType": ["caravan"]}),
    item("leveling_blocks", "Karavan denge takozu", "shelter", when={"campType": ["caravan"]}),
    item("awning", "Karavan tentesi", "shelter", when={"campType": ["caravan"]}),
    # Uyku
    item("sleeping_bag", "Uyku tulumu", "sleep", essential=True, note="Mevsime uygun konfor sıcaklığı seçin."),
    item("sleeping_mat", "Mat / şişme yatak", "sleep", essential=True), item("pillow", "Kamp yastığı", "sleep"),
    item("liner", "Tulum içliği", "sleep", when=COLD), item("extra_blanket", "Ek battaniye", "sleep", when=COLD),
    item("pump", "Pompa (şişme yatak için)", "sleep", when=CAR), item("eye_mask_earplugs", "Uyku maskesi / kulak tıkacı", "sleep"),
    item("cot", "Kamp yatağı (karyola)", "sleep", when={"access": ["car"], "campType": ["tent"]}),
    # Giyim
    item("base_layer", "Termal içlik", "clothing", when=COLD), item("fleece", "Polar", "clothing", when=COLD, qty=1),
    item("down_jacket", "Şişme mont", "clothing", when=WINTER, essential=True), item("rain_jacket", "Yağmurluk / hardshell", "clothing", essential=True),
    item("hiking_pants", "Outdoor pantolon", "clothing", qty=(1, 0.2, 3)), item("shorts", "Şort", "clothing", when=SUMMER, qty=(1, 0.3, 4)),
    item("tshirts", "Tişört", "clothing", qty=(0, 0.7, 7)), item("socks", "Çorap (yün / outdoor)", "clothing", qty=(1, 1, 8)),
    item("underwear", "İç çamaşırı", "clothing", qty=(0, 1, 8)), item("hiking_boots", "Yürüyüş botu / ayakkabısı", "clothing", essential=True),
    item("camp_sandals", "Kamp terliği / sandalet", "clothing"), item("hat", "Şapka", "clothing"),
    item("beanie_gloves", "Bere ve eldiven", "clothing", when=COLD), item("buff", "Boyunluk / buff", "clothing"),
    item("swimsuit", "Mayo", "clothing", when=SUMMER), item("gaiters", "Tozluk", "clothing", when=WINTER),
    item("sleep_clothes", "Uyku kıyafeti", "clothing"),
    # Aydınlatma / enerji
    item("headlamp", "Kafa lambası", "light", essential=True), item("lantern", "Kamp feneri", "light"),
    item("batteries", "Yedek pil", "light"), item("powerbank", "Powerbank (büyük kapasite)", "light", essential=True),
    item("solar_panel", "Güneş paneli / şarj", "light", when={"water": ["no"]}), item("car_inverter", "Araç invertörü", "light", when=CAR),
    item("string_lights", "Dekoratif ip ışık", "light", when=CAR), item("phone_charger", "Telefon şarj kablosu", "light"),
    # Araç gereç
    item("knife", "Bıçak / çakı", "tools", essential=True), item("multitool", "Çok amaçlı alet", "tools"),
    item("axe_saw", "Balta / testere", "tools", when={"access": ["car"], "water": ["no"]}), item("shovel", "Katlanır kürek", "tools", when=NOWATER),
    item("duct_tape", "Koli bandı", "tools"), item("rope", "İp (10 m+)", "tools"),
    item("carabiners", "Karabina", "tools"), item("fire_starter", "Çakmak + kibrit + çakmaktaşı", "tools", essential=True),
    item("firewood", "Odun / kömür", "tools", when=CAR), item("trash_bags", "Çöp poşeti", "tools", essential=True),
    item("ziplock", "Kilitli poşet", "tools"), item("dry_bag", "Su geçirmez torba", "tools"),
    item("camp_chair", "Kamp sandalyesi", "tools", when=CAR), item("camp_table", "Kamp masası", "tools", when=CAR),
    item("cooler", "Buzluk", "tools", when=CAR, essential=True), item("clothesline", "Çamaşır ipi / mandal", "tools"),
    item("sewing_kit", "Dikiş seti", "tools"), item("hammock", "Hamak", "tools", when=CAR),
    item("windbreak", "Rüzgarlık paravan", "tools", when={"access": ["car"], "campType": ["tent"]}),
    item("broom", "Küçük süpürge (çadır içi)", "tools", when=TENT),
    # Navigasyon / belgeler
    item("map_compass", "Harita ve pusula", "nav", when=HIKE, essential=True), item("gps", "GPS / offline harita", "nav"),
    item("permit", "Kamp alanı rezervasyonu / izin", "nav", essential=True), item("id", "Kimlik", "nav", essential=True),
    item("cash", "Nakit para", "nav"), item("emergency_numbers", "Acil numaralar (jandarma, orman, AFAD)", "nav"),
    item("whistle", "Düdük", "nav", when=HIKE), item("car_docs", "Araç belgeleri", "nav", when=CAR),
    # Hijyen / sağlık
    item("first_aid", "İlk yardım çantası", "hygiene", essential=True), item("meds", "Kişisel ilaçlar", "hygiene", essential=True),
    item("sunscreen", "Güneş kremi", "hygiene"), item("insect_repellent", "Böcek / kene kovucu", "hygiene", essential=True),
    item("tick_remover", "Kene çıkarıcı", "hygiene"), item("toothbrush", "Diş fırçası / macun", "hygiene"),
    item("biodegradable_soap", "Doğada çözünen sabun", "hygiene"), item("wet_wipes", "Islak mendil", "hygiene"),
    item("toilet_paper", "Tuvalet kağıdı", "hygiene", essential=True), item("trowel", "Tuvalet küreği", "hygiene", when=NOWATER),
    item("quick_towel", "Hızlı kuruyan havlu", "hygiene"), item("hand_sanitizer", "El dezenfektanı", "hygiene"),
    item("lip_balm", "Dudak koruyucu", "hygiene"), item("blister", "Su toplama bandı", "hygiene", when=HIKE),
    item("aloe", "Güneş sonrası / aloe jel", "hygiene", when=SUMMER), item("hygiene_bag", "Kişisel bakım çantası", "hygiene"),
    # Çocuk
    item("kid_sleeping_bag", "Çocuk uyku tulumu", "kids", when=KIDS, essential=True), item("kid_headlamp", "Çocuk kafa lambası", "kids", when=KIDS),
    item("kid_clothes", "Yedek çocuk kıyafeti (bol)", "kids", when=KIDS, qty=(2, 1, 10), unit="takım"), item("kid_toys", "Oyuncak / kitap", "kids", when=KIDS),
    item("kid_snacks", "Çocuk atıştırmalığı", "kids", when=KIDS),
    item("kid_meds", "Çocuk ilaçları", "kids", when=KIDS, essential=True), item("kid_repellent", "Çocuk böcek kovucu", "kids", when=KIDS),
    item("kid_carrier", "Çocuk taşıma sırt çantası", "kids", when={"kids": ["yes"], "access": ["hike"]}),
    item("kid_whistle", "Çocuk düdüğü / isim bilekliği", "kids", when=KIDS),
    # Aktivite
    item("daypack", "Günlük sırt çantası", "fun"), item("trekking_poles", "Trekking batonu", "fun", when=HIKE),
    item("binoculars", "Dürbün", "fun"), item("camera", "Fotoğraf makinesi", "fun"),
    item("book_cards", "Kitap / kart oyunu", "fun"), item("fishing", "Olta takımı", "fun", when=CAR),
    item("ball", "Top / frizbi", "fun", when=CAR), item("speaker", "Hoparlör (düşük ses)", "fun", when=CAR),
    item("star_app", "Yıldız haritası uygulaması", "fun"), item("notebook", "Not defteri / kalem", "fun"),
    # Mutfak
    item("stove", "Kamp ocağı", "kitchen", essential=True), item("gas", "Gaz kartuşu / tüp", "kitchen", qty=(1, 0.3, 4), unit="adet", essential=True),
    item("pot_pan", "Tencere ve tava", "kitchen"), item("kettle", "Çaydanlık / cezve", "kitchen"),
    item("cutlery", "Çatal kaşık bıçak", "kitchen"), item("plates_cups", "Tabak ve bardak", "kitchen"),
    item("cutting_board", "Kesme tahtası", "kitchen"), item("can_opener", "Konserve açacağı", "kitchen"),
    item("spatula", "Spatula / kepçe", "kitchen"), item("grill", "Mangal / ızgara teli", "kitchen", when=CAR),
    item("foil", "Folyo", "kitchen"), item("dish_kit", "Bulaşık deterjanı, sünger, bez", "kitchen"),
    item("water_container", "Su bidonu (10-20 L)", "kitchen", when=CAR, essential=True), item("food_containers", "Saklama kabı", "kitchen"),
    item("thermos", "Termos", "kitchen"), item("lighter_kitchen", "Ocak çakmağı", "kitchen"),
    item("bear_bag", "Yiyecek asma torbası (hayvanlara karşı)", "kitchen", when=NOWATER),
    # Yiyecek
    item("breakfast", "Kahvaltılık (peynir, zeytin, yumurta, reçel)", "foodstuff"), item("bread", "Ekmek / lavaş", "foodstuff", qty=(1, 0.5, 6), unit="adet"),
    item("pasta_rice", "Makarna / pirinç / bulgur", "foodstuff", qty=(1, 0.3, 4), unit="paket"), item("canned", "Konserve (ton, fasulye, mısır)", "foodstuff", qty=(2, 1, 12), unit="adet"),
    item("soup", "Hazır çorba", "foodstuff", when=COLD, qty=(1, 0.5, 6), unit="paket"), item("meat_frozen", "Et / sucuk (dondurulmuş)", "foodstuff", when=CAR),
    item("veg", "Dayanıklı sebze (patates, soğan, domates)", "foodstuff"), item("fruit", "Meyve (elma, portakal)", "foodstuff"),
    item("nuts_dried", "Kuruyemiş / kuru meyve", "foodstuff", essential=True), item("energy_bars", "Enerji barı", "foodstuff", when=HIKE, qty=(2, 2, 20), unit="adet"),
    item("chocolate", "Çikolata / bisküvi", "foodstuff"), item("oil_spices", "Yağ, tuz, baharat", "foodstuff", essential=True),
    item("tea_coffee", "Çay / kahve / şeker", "foodstuff"), item("milk_powder", "Süt tozu / UHT süt", "foodstuff"),
    item("oats", "Yulaf / granola", "foodstuff"), item("dehydrated", "Liyofilize kamp yemeği", "foodstuff", when=HIKE),
    item("marshmallow", "Marshmallow", "foodstuff", when=KIDS), item("honey_jam", "Bal / reçel", "foodstuff"),
    # Su
    item("water", "İçme suyu", "drinks", qty=(0, 3, None), unit="L", essential=True),
    item("water_filter", "Su filtresi / arıtma tableti", "drinks", when=NOWATER, essential=True),
    item("bottles", "Matara", "drinks", qty=(1, 0, None), unit="adet"), item("hydration_bladder", "Su torbası (hidrasyon)", "drinks", when=HIKE),
    item("juice_soda", "Meyve suyu / gazoz", "drinks", when=CAR), item("electrolyte", "Elektrolit / izotonik toz", "drinks", when=SUMMER),
    # Hazırlık
    item("prep_weather", "Hava durumunu kontrol et", "prepList", daysBefore=1),
    item("prep_reservation", "Kamp alanı rezervasyonu / izin al", "prepList", daysBefore=14),
    item("prep_test_tent", "Çadırı ve ekipmanı evde kur, test et", "prepList", when=TENT, daysBefore=5),
    item("prep_charge", "Powerbank, fener, telefon şarj et", "prepList", daysBefore=0),
    item("prep_offline_map", "Offline harita indir", "prepList", daysBefore=1),
    item("prep_food_prep", "Yemekleri hazırla / marine et / dondur", "prepList", daysBefore=1),
    item("prep_inform", "Rotayı ve dönüş saatini birine bildir", "prepList", daysBefore=0),
    item("prep_car_check", "Araç kontrolü (lastik, yakıt)", "prepList", when=CAR, daysBefore=2),
    item("prep_fire_rules", "Ateş yasağı / orman kurallarını öğren", "prepList", daysBefore=3),
    item("prep_gas_check", "Gaz kartuşu / ocak çalışıyor mu kontrol et", "prepList", daysBefore=3),
    item("prep_first_aid_check", "İlk yardım çantasını tamamla", "prepList", daysBefore=3),
]

TEMPLATE = {
    "id": "kamp", "name": "Kamp",
    "description": "Çadır, karavan veya bungalov — mevsim, ulaşım ve tesis durumuna göre ekipman ve yiyecek.",
    "icon": "forest", "color": "#2E7D32",
    "kind": "inventory",
    "dateMode": "range", "dateLabel": "Gidiş", "endDateLabel": "Dönüş",
    "textFields": [field("place", "Kamp yeri", "Kazdağları")],
    "filters": FILTERS, "sections": SECTIONS, "categories": CATEGORIES, "items": items,
}
