# -*- coding: utf-8 -*-
"""Mangal listesi: kullanıcının kendi sabit listesi. Sorusuz, tarihsiz, stok takipli.
Kalemler bilinçli olarak sınırlı tutulmuştur — yeni kalem EKLEMEYİN (kullanıcı isteği)."""
from common import *

FILTERS = []
SECTIONS = [sec("main", "Mangal", "outdoor_grill")]
CATEGORIES = [
    cat("fire",     "Mangal ve Ateş Ekipmanları", "outdoor_grill",     C["red"],    "main"),
    cat("food",     "Etler ve Yiyecekler",        "kebab_dining",      C["orange"], "main"),
    cat("sauce",    "Yağ, Sos ve Baharatlar",     "restaurant",        C["lime"],   "main"),
    cat("drinks",   "İçecekler ve Termoslar",     "local_drink",       C["cyan"],   "main"),
    cat("serving",  "Servis ve Mutfak Gereçleri", "table_restaurant",  C["amber"],  "main"),
    cat("table",    "Masa Düzeni ve Hijyen",      "sanitizer",         C["teal"],   "main"),
    cat("personal", "Kişisel ve Ekstra",          "checkroom",         C["grey"],   "main"),
]
def it(id, name, cat_): return item(id, name, cat_)
items = [
    # 1. Mangal & Ateş
    it("grill", "Mangal", "fire"),
    it("charcoal", "Kömür", "fire"),
    it("firestarter", "Reşo yakıtı (tutuşturucu)", "fire"),
    it("lighter", "Çakmak", "fire"),
    it("grate", "Izgara teli", "fire"),
    it("fan", "Yelpaze", "fire"),
    it("tongs", "Maşa", "fire"),
    it("grill_cleaner", "Izgara temizleme malzemesi", "fire"),
    it("skewers", "Şiş", "fire"),
    # 2. Etler & Yiyecekler
    it("chicken", "Tavuk", "food"),
    it("meatballs", "Köfte", "food"),
    it("sausage", "Sucuk", "food"),
    it("corn", "Mısır", "food"),
    it("fruit", "Meyve", "food"),
    it("nuts", "Kuru yemiş", "food"),
    # 3. Yağ, Sos & Baharat
    it("olive_oil", "Zeytinyağı", "sauce"),
    it("lemon_juice", "Limon suyu", "sauce"),
    it("butter", "Tereyağı", "sauce"),
    it("salt", "Tuz", "sauce"),
    # 4. İçecekler & Termoslar
    it("water", "Su", "drinks"),
    it("ayran", "Ayran", "drinks"),
    it("soda", "Soda", "drinks"),
    it("tea_thermos", "Çay termosu", "drinks"),
    it("coffee_thermos", "Kahve termosu", "drinks"),
    it("sugar", "Çay şekeri", "drinks"),
    # 5. Servis & Mutfak
    it("plates", "Plastik tabak", "serving"),
    it("cutlery", "Çatal, kaşık, bıçak seti", "serving"),
    it("tea_glasses", "Çay bardağı ve çay kaşığı", "serving"),
    it("cutting_board", "Kesme tahtası", "serving"),
    it("empty_bottle", "Boş su şişesi", "serving"),
    it("fridge_bags", "Buzdolabı poşeti", "serving"),
    it("cling_film", "Streç film", "serving"),
    # 6. Masa & Hijyen
    it("table_cloth", "Masa / masa örtüsü", "table"),
    it("dish_cloth", "Sofra bezi", "table"),
    it("napkins", "Peçete", "table"),
    it("soap", "Sabun", "table"),
    it("gloves", "Eldiven", "table"),
    # 7. Kişisel & Ekstra
    it("warm_clothes", "Kalın giyecek / hırka", "personal"),
]

TEMPLATE = {
    "id": "mangal", "name": "Mangal",
    "description": "Sabit mangal listesi: ekipman, yiyecek, içecek ve servis. Eksikler markete aktarılabilir.",
    "icon": "outdoor_grill", "color": "#E64A19",
    "kind": "inventory",
    "dateMode": "none", "dateLabel": "Tarih", "endDateLabel": None,
    "textFields": [],
    "filters": FILTERS, "sections": SECTIONS, "categories": CATEGORIES, "items": items,
}
