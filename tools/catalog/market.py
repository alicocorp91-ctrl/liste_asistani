# -*- coding: utf-8 -*-
"""Market listesi: pratik, sorusuz, tarihsiz. Öneriler seçimsiz gelir; kullanıcı işaretler veya hızlı ekler."""
from common import *

FILTERS = []
SECTIONS = [sec("main", "Alışveriş", "shopping_cart")]
CATEGORIES = [
    cat("produce",   "Meyve ve Sebze",            "eco",              C["green"],      "main"),
    cat("meat",      "Et, Tavuk, Balık",          "set_meal",         C["red"],        "main"),
    cat("dairy",     "Süt Ürünleri ve Kahvaltılık","egg",             C["amber"],      "main"),
    cat("bakery",    "Ekmek ve Unlu Mamuller",    "bakery_dining",    C["brown"],      "main"),
    cat("pantry",    "Bakliyat, Makarna, Pirinç", "rice_bowl",        C["orange"],     "main"),
    cat("canned",    "Konserve ve Soslar",        "inventory_2",      C["deeporange"], "main"),
    cat("spices",    "Baharat, Yağ, Temel Gıda",  "restaurant",       C["lime"],       "main"),
    cat("snacks",    "Atıştırmalık",              "cookie",           C["pink"],       "main"),
    cat("drinks",    "İçecek",                    "local_drink",      C["cyan"],       "main"),
    cat("frozen",    "Dondurulmuş",               "ac_unit",          C["lightblue"],  "main"),
    cat("cleaning",  "Temizlik",                  "cleaning_services",C["blue"],       "main"),
    cat("paper",     "Kağıt Ürünleri",            "receipt_long",     C["bluegrey"],   "main"),
    cat("personal",  "Kişisel Bakım",             "soap",             C["teal"],       "main"),
    cat("other",     "Diğer",                     "category",         C["grey"],       "main"),
]
def m(id, name, cat_, qty=1, unit="adet", when=None, note=None):
    return item(id, name, cat_, when=when, qty=qty, unit=unit, note=note)

items = [
    # Meyve sebze
    m("tomato", "Domates", "produce", 1, "kg"), m("cucumber", "Salatalık", "produce", 1, "kg"),
    m("pepper", "Biber", "produce", 500, "g"), m("onion", "Soğan", "produce", 2, "kg"),
    m("potato", "Patates", "produce", 2, "kg"), m("garlic", "Sarımsak", "produce", 1, "adet"),
    m("lemon", "Limon", "produce", 4, "adet"), m("parsley", "Maydanoz", "produce", 1, "demet"),
    m("dill", "Dereotu", "produce", 1, "demet"), m("lettuce", "Marul / kıvırcık", "produce", 1, "adet"),
    m("spinach", "Ispanak", "produce", 500, "g"), m("carrot", "Havuç", "produce", 500, "g"),
    m("zucchini", "Kabak", "produce", 500, "g"), m("eggplant", "Patlıcan", "produce", 1, "kg"),
    m("mushroom", "Mantar", "produce", 250, "g"), m("greenbeans", "Taze fasulye", "produce", 500, "g"),
    m("apple", "Elma", "produce", 1, "kg"), m("banana", "Muz", "produce", 1, "kg"),
    m("orange", "Portakal", "produce", 1, "kg"), m("grape", "Üzüm", "produce", 500, "g"),
    m("strawberry", "Çilek", "produce", 500, "g"), m("watermelon", "Karpuz", "produce", 1, "adet"),
    m("avocado", "Avokado", "produce", 2, "adet"), m("ginger", "Zencefil", "produce", 1, "adet"),
    # Et
    m("chicken_breast", "Tavuk göğsü", "meat", 1, "kg"), m("chicken_thigh", "Tavuk but", "meat", 1, "kg"),
    m("ground_beef", "Kıyma", "meat", 500, "g"), m("beef_cubes", "Kuşbaşı", "meat", 500, "g"),
    m("steak", "Biftek / antrikot", "meat", 500, "g"), m("fish", "Balık", "meat", 1, "kg"),
    m("salmon", "Somon", "meat", 500, "g"), m("sausage", "Sucuk", "meat", 1, "adet"),
    m("salami", "Salam / jambon", "meat", 200, "g"), m("pastirma", "Pastırma", "meat", 100, "g"),
    m("meatballs", "Hazır köfte", "meat", 500, "g"),
    # Süt & kahvaltı
    m("milk", "Süt", "dairy", 1, "L"), m("yogurt", "Yoğurt", "dairy", 1, "kg"),
    m("white_cheese", "Beyaz peynir", "dairy", 500, "g"), m("kasar", "Kaşar peyniri", "dairy", 400, "g"),
    m("cream_cheese", "Labne / krem peynir", "dairy", 1, "adet"), m("butter", "Tereyağı", "dairy", 250, "g"),
    m("eggs", "Yumurta", "dairy", 15, "adet"), m("olives", "Zeytin", "dairy", 500, "g"),
    m("honey", "Bal", "dairy", 1, "kavanoz"), m("jam", "Reçel", "dairy", 1, "kavanoz"),
    m("tahini_pekmez", "Tahin / pekmez", "dairy", 1, "adet"), m("ayran", "Ayran", "dairy", 1, "L"),
    m("kefir", "Kefir", "dairy", 1, "L"), m("cream", "Krema", "dairy", 1, "adet"),
    m("plant_milk", "Bitkisel süt (badem / yulaf)", "dairy", 1, "L"),
    # Ekmek
    m("bread", "Ekmek", "bakery", 2, "adet"), m("whole_bread", "Tam buğday ekmeği", "bakery", 1, "adet"),
    m("lavash", "Lavaş / tortilla", "bakery", 1, "paket"), m("simit", "Simit / poğaça", "bakery", 4, "adet"),
    m("toast_bread", "Tost ekmeği", "bakery", 1, "paket"), m("flour", "Un", "bakery", 2, "kg"),
    m("yeast", "Maya", "bakery", 1, "paket"), m("baking_powder", "Kabartma tozu / vanilya", "bakery", 1, "paket"),
    # Kiler
    m("rice", "Pirinç", "pantry", 1, "kg"), m("bulgur", "Bulgur", "pantry", 1, "kg"),
    m("pasta", "Makarna", "pantry", 2, "paket"), m("noodle", "Şehriye / erişte", "pantry", 1, "paket"),
    m("lentil_red", "Kırmızı mercimek", "pantry", 1, "kg"), m("lentil_green", "Yeşil mercimek", "pantry", 500, "g"),
    m("chickpea", "Nohut", "pantry", 1, "kg"), m("beans", "Kuru fasulye", "pantry", 1, "kg"),
    m("oats", "Yulaf", "pantry", 500, "g"), m("couscous", "Kuskus", "pantry", 1, "paket"),
    m("breakfast_cereal", "Kahvaltılık gevrek", "pantry", 1, "paket"),
    # Konserve & sos
    m("tomato_paste", "Salça", "canned", 1, "kavanoz"), m("canned_tomato", "Konserve domates", "canned", 2, "adet"),
    m("canned_corn", "Konserve mısır", "canned", 2, "adet"), m("canned_tuna", "Ton balığı", "canned", 3, "adet"),
    m("pickles", "Turşu", "canned", 1, "kavanoz"), m("ketchup", "Ketçap", "canned", 1, "adet"),
    m("mayo", "Mayonez", "canned", 1, "adet"), m("mustard", "Hardal", "canned", 1, "adet"),
    m("soy_sauce", "Soya sosu", "canned", 1, "adet"), m("pesto", "Pesto / makarna sosu", "canned", 1, "kavanoz"),
    m("peanut_butter", "Fıstık ezmesi", "canned", 1, "kavanoz"),
    # Baharat & yağ
    m("olive_oil", "Zeytinyağı", "spices", 1, "L"), m("sunflower_oil", "Ayçiçek yağı", "spices", 2, "L"),
    m("salt", "Tuz", "spices", 1, "paket"), m("black_pepper", "Karabiber", "spices", 1, "paket"),
    m("red_pepper", "Pul biber", "spices", 1, "paket"), m("cumin", "Kimyon", "spices", 1, "paket"),
    m("mint_dry", "Nane (kuru)", "spices", 1, "paket"), m("thyme", "Kekik", "spices", 1, "paket"),
    m("sugar", "Şeker", "spices", 1, "kg"), m("powdered_sugar", "Pudra şekeri", "spices", 1, "paket"),
    m("vinegar", "Sirke", "spices", 1, "adet"), m("bouillon", "Bulyon", "spices", 1, "paket"),
    m("cinnamon", "Tarçın", "spices", 1, "paket"),
    # Atıştırmalık
    m("chips", "Cips", "snacks", 1, "paket"), m("crackers", "Kraker", "snacks", 1, "paket"),
    m("biscuits", "Bisküvi", "snacks", 2, "paket"), m("chocolate", "Çikolata", "snacks", 2, "adet"),
    m("nuts", "Kuruyemiş", "snacks", 250, "g"), m("dried_fruit", "Kuru meyve", "snacks", 250, "g"),
    m("popcorn", "Patlamış mısır", "snacks", 1, "paket"), m("wafer", "Gofret", "snacks", 3, "adet"),
    # İçecek
    m("water", "Su", "drinks", 1, "koli"), m("soda_water", "Maden suyu", "drinks", 6, "adet"),
    m("tea", "Çay", "drinks", 1, "kg"), m("coffee", "Kahve", "drinks", 1, "paket"),
    m("turkish_coffee", "Türk kahvesi", "drinks", 1, "paket"), m("juice", "Meyve suyu", "drinks", 1, "L"),
    m("cola", "Gazlı içecek", "drinks", 1, "adet"), m("herbal_tea", "Bitki çayı", "drinks", 1, "kutu"),
    # Dondurulmuş
    m("frozen_veg", "Dondurulmuş sebze", "frozen", 1, "paket"), m("frozen_fries", "Dondurulmuş patates", "frozen", 1, "paket"),
    m("frozen_pastry", "Dondurulmuş börek / mantı", "frozen", 1, "paket"), m("ice_cream", "Dondurma", "frozen", 1, "adet"),
    m("frozen_pizza", "Dondurulmuş pizza", "frozen", 1, "adet"),
    # Temizlik
    m("dish_soap", "Bulaşık deterjanı", "cleaning", 1, "adet"), m("dishwasher_tabs", "Bulaşık makinesi tableti", "cleaning", 1, "paket"),
    m("laundry_det", "Çamaşır deterjanı", "cleaning", 1, "adet"), m("softener", "Yumuşatıcı", "cleaning", 1, "adet"),
    m("bleach", "Çamaşır suyu", "cleaning", 1, "adet"), m("surface_cleaner", "Yüzey temizleyici", "cleaning", 1, "adet"),
    m("glass_cleaner", "Cam temizleyici", "cleaning", 1, "adet"), m("sponge", "Sünger", "cleaning", 1, "paket"),
    m("trash_bags", "Çöp poşeti", "cleaning", 1, "rulo"), m("bathroom_cleaner", "Banyo / kireç temizleyici", "cleaning", 1, "adet"),
    m("floor_cleaner", "Yer temizleyici", "cleaning", 1, "adet"), m("descaler", "Kireç önleyici", "cleaning", 1, "adet"),
    # Kağıt
    m("toilet_paper", "Tuvalet kağıdı", "paper", 1, "paket"), m("paper_towel", "Kağıt havlu", "paper", 1, "paket"),
    m("napkins", "Peçete", "paper", 1, "paket"), m("cling_film", "Streç film", "paper", 1, "adet"),
    m("foil", "Alüminyum folyo", "paper", 1, "adet"), m("baking_paper", "Pişirme kağıdı", "paper", 1, "adet"),
    m("freezer_bags", "Buzdolabı poşeti", "paper", 1, "paket"),
    # Kişisel bakım
    m("shampoo", "Şampuan", "personal", 1, "adet"), m("shower_gel", "Duş jeli", "personal", 1, "adet"),
    m("soap", "Sabun", "personal", 1, "adet"), m("toothpaste", "Diş macunu", "personal", 1, "adet"),
    m("toothbrush", "Diş fırçası", "personal", 1, "adet"), m("deodorant", "Deodorant", "personal", 1, "adet"),
    m("razor", "Tıraş bıçağı", "personal", 1, "paket"), m("pads", "Ped", "personal", 1, "paket"),
    m("cotton", "Pamuk / kulak çubuğu", "personal", 1, "paket"), m("hand_soap", "Sıvı el sabunu", "personal", 1, "adet"),
    m("wet_wipes", "Islak mendil", "personal", 1, "paket"), m("face_cream", "Yüz kremi", "personal", 1, "adet"),
    # Diğer
    m("batteries", "Pil", "other", 1, "paket"), m("light_bulb", "Ampul", "other", 1, "adet"),
    m("matches", "Kibrit / çakmak", "other", 1, "adet"), m("candles", "Mum", "other", 1, "paket"),
]

TEMPLATE = {
    "id": "market", "name": "Market",
    "description": "Haftalık alışveriş için miktar ve birimli, reyon sırasına göre düzenlenmiş liste.",
    "icon": "shopping_cart", "color": "#43A047",
    "kind": "inventory",
    "dateMode": "none", "dateLabel": "Tarih", "endDateLabel": None,
    "preselect": False, "quickAdd": True,
    "textFields": [],
    "filters": FILTERS, "sections": SECTIONS, "categories": CATEGORIES, "items": items,
}
