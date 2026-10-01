# -*- coding: utf-8 -*-
"""Hastane / doğum çantası: anne, bebek, refakatçi; doğum tipi ve mevsim filtreleri."""
from common import *

FILTERS = [
    filt("birthType", "Doğum Tipi", "Planlanan doğum şekli?",
         [opt("normal", "Normal doğum", "favorite"), opt("csection", "Sezaryen", "medical_services"), opt("unknown", "Belli değil", "help_outline")], "unknown"),
    filt("season", "Mevsim", "Bebek hangi mevsimde doğacak?",
         [opt("warm", "Yaz / ılık", "wb_sunny"), opt("cold", "Kış / soğuk", "ac_unit")], "warm"),
    filt("companion", "Refakatçi", "Hastanede refakatçi kalacak mı?", [opt("no", "Hayır"), opt("yes", "Evet", "people")], "yes"),
    filt("feeding", "Beslenme", "Planlanan beslenme?",
         [opt("breast", "Emzirme", "favorite"), opt("formula", "Mama", "baby_changing_station"), opt("mixed", "Karışık", "child_care")], "breast"),
    filt("siblings", "Kardeş", "Evde başka çocuk var mı?", [opt("no", "Hayır"), opt("yes", "Evet", "child_care")], "no"),
]
SECTIONS = [sec("mom", "Anne", "pregnant_woman"), sec("baby", "Bebek", "child_care"), sec("companion", "Refakatçi ve Ev", "family_restroom")]
CATEGORIES = [
    cat("docs",       "Belgeler",              "description",      C["red"],        "mom"),
    cat("mom_clothes","Anne Kıyafet",          "checkroom",        C["pink"],       "mom"),
    cat("mom_care",   "Anne Hijyen ve Bakım",  "spa",              C["purple"],     "mom"),
    cat("birth",      "Doğum Sırasında",       "favorite",         C["deeporange"], "mom"),
    cat("postpartum", "Doğum Sonrası",         "healing",          C["teal"],       "mom"),
    cat("mom_comfort","Konfor ve Elektronik",  "devices",          C["amber"],      "mom"),
    cat("baby_clothes","Bebek Kıyafet",        "child_care",       C["lightblue"],  "baby"),
    cat("baby_care",  "Bebek Bakım",           "baby_changing_station", C["cyan"],  "baby"),
    cat("feeding",    "Beslenme",              "restaurant",       C["green"],      "baby"),
    cat("going_home", "Eve Dönüş",             "directions_car",   C["indigo"],     "baby"),
    cat("comp",       "Refakatçi Çantası",     "people",           C["blue"],       "companion"),
    cat("home_prep",  "Evde Hazır Olsun",      "home",             C["brown"],      "companion"),
    cat("prep",       "Doğum Öncesi Görevler", "checklist",        C["bluegrey"],   "companion"),
]
CS = {"birthType": ["csection", "unknown"]}; NORMAL = {"birthType": ["normal", "unknown"]}
COLD = {"season": ["cold"]}; WARM = {"season": ["warm"]}; COMP = {"companion": ["yes"]}
BREAST = {"feeding": ["breast", "mixed"]}; FORMULA = {"feeding": ["formula", "mixed"]}; SIB = {"siblings": ["yes"]}
items = [
    # Belgeler
    item("id_card", "Kimlik kartı (anne ve baba)", "docs", essential=True), item("insurance_card", "Sigorta / SGK bilgileri", "docs", essential=True),
    item("hospital_file", "Gebelik takip dosyası, tahliller, ultrason raporları", "docs", essential=True),
    item("blood_type", "Kan grubu kartı", "docs"), item("birth_plan", "Doğum planı (varsa)", "docs"),
    item("marriage_cert", "Evlilik cüzdanı", "docs", note="Doğum belgesi işlemleri için istenebilir."),
    item("hospital_contract", "Hastane anlaşması / doktor iletişim", "docs"), item("payment", "Kredi kartı / nakit", "docs", essential=True),
    item("phone_list", "Aranacaklar listesi", "docs"),
    # Anne kıyafet
    item("nightgown", "Önden açılır gecelik", "mom_clothes", qty=3, unit="adet", essential=True),
    item("robe", "Sabahlık", "mom_clothes", qty=1), item("nursing_bra", "Emzirme sütyeni", "mom_clothes", qty=2, unit="adet", when=BREAST),
    item("disposable_underwear", "Tek kullanımlık / bol pamuklu külot", "mom_clothes", qty=8, unit="adet", essential=True),
    item("socks", "Çorap (kaymaz)", "mom_clothes", qty=3, unit="çift"), item("slippers", "Terlik (kaymaz)", "mom_clothes", essential=True),
    item("shower_slippers", "Duş terliği", "mom_clothes"), item("going_home_outfit", "Eve dönüş kıyafeti (bol, rahat)", "mom_clothes", essential=True),
    item("cardigan", "Hırka / şal", "mom_clothes", when=COLD), item("hairband", "Saç tokası / bandana", "mom_clothes"),
    item("high_waist_underwear", "Yüksek bel külot (dikişe değmeyen)", "mom_clothes", when=CS, qty=4, unit="adet"),
    item("compression_socks", "Varis çorabı", "mom_clothes", when=CS, note="Sezaryen sonrası doktor önerebilir."),
    # Anne bakım
    item("maternity_pads", "Lohusa pedi", "mom_care", qty=2, unit="paket", essential=True),
    item("nursing_pads", "Göğüs pedi", "mom_care", when=BREAST), item("nipple_cream", "Göğüs ucu kremi (lanolin)", "mom_care", when=BREAST),
    item("toiletries", "Diş fırçası, macun, şampuan, duş jeli", "mom_care", essential=True), item("face_wipes", "Yüz temizleme mendili", "mom_care"),
    item("lip_balm", "Dudak nemlendirici", "mom_care"), item("hair_brush", "Tarak / saç kurutma", "mom_care"),
    item("deodorant", "Deodorant", "mom_care"), item("moisturizer", "Nemlendirici", "mom_care"),
    item("perineal_spray", "Perine soğutucu sprey / oturma banyosu", "mom_care", when=NORMAL),
    item("towel", "Havlu (büyük + küçük)", "mom_care"), item("glasses_lens", "Gözlük / lens malzemesi", "mom_care"),
    item("light_makeup", "Hafif makyaj (fotoğraf için)", "mom_care"), item("wet_wipes_mom", "Islak mendil", "mom_care"),
    item("belly_band", "Karın korsesi", "mom_care", when=CS),
    # Doğum sırasında
    item("birth_ball", "Pilates topu (hastane izin veriyorsa)", "birth", when=NORMAL), item("massage_oil", "Masaj yağı", "birth", when=NORMAL),
    item("hair_ties", "Saç lastiği", "birth"), item("lollipop", "Şekerleme / lolipop (enerji)", "birth", when=NORMAL),
    item("water_bottle", "Pipetli su şişesi", "birth"), item("playlist", "Müzik listesi / kulaklık", "birth"),
    item("focus_object", "Odak nesnesi / afirmasyon kartları", "birth", when=NORMAL), item("fan", "Mini vantilatör", "birth", when=WARM),
    # Doğum sonrası
    item("painkillers", "Doktorun onayladığı ağrı kesici", "postpartum"), item("stool_softener", "Kabızlık önleyici (doktora sor)", "postpartum", when=CS),
    item("donut_pillow", "Simit yastık", "postpartum", when=NORMAL), item("nursing_pillow", "Emzirme yastığı", "postpartum", when=BREAST),
    item("breast_pump", "Süt pompası", "postpartum", when=BREAST), item("snacks", "Atıştırmalık (kuruyemiş, bar, hurma)", "postpartum"),
    item("herbal_tea", "Rezene / lohusa çayı", "postpartum", when=BREAST), item("water_big", "Büyük su şişeleri", "postpartum"),
    # Konfor / elektronik
    item("phone_charger", "Telefon şarj aleti (uzun kablo)", "mom_comfort", essential=True), item("powerbank", "Powerbank", "mom_comfort"),
    item("camera", "Fotoğraf makinesi / kamera", "mom_comfort"), item("pillow", "Kendi yastığın", "mom_comfort"),
    item("eye_mask", "Uyku maskesi / kulak tıkacı", "mom_comfort"), item("tablet_book", "Tablet / kitap", "mom_comfort"),
    item("earbuds", "Kulaklık", "mom_comfort"), item("extension_cord", "Uzatma kablosu", "mom_comfort"),
    item("blanket", "İnce battaniye", "mom_comfort", when=COLD), item("notebook", "Not defteri (sorular, süt saatleri)", "mom_comfort"),
    # Bebek kıyafet
    item("bodysuit", "Zıbın / body", "baby_clothes", qty=5, unit="adet", essential=True), item("onesie", "Tulum", "baby_clothes", qty=4, unit="adet"),
    item("hat", "Bere / şapka", "baby_clothes", qty=2, unit="adet", essential=True), item("mittens", "Eldiven (tırnak için)", "baby_clothes", qty=2, unit="çift"),
    item("baby_socks", "Bebek çorabı", "baby_clothes", qty=3, unit="çift"), item("vest", "Yelek / hırka", "baby_clothes", when=COLD, qty=1),
    item("swaddle", "Kundak / müslin örtü", "baby_clothes", qty=3, unit="adet"), item("baby_blanket", "Bebek battaniyesi", "baby_clothes", essential=True),
    item("thick_blanket", "Kalın battaniye / tulum", "baby_clothes", when=COLD), item("bib", "Ağız bezi / önlük", "baby_clothes", qty=5, unit="adet"),
    item("hospital_outfit", "Hastane çıkış kıyafeti (özel)", "baby_clothes"), item("thin_cotton", "İnce pamuklu takım", "baby_clothes", when=WARM, qty=3),
    # Bebek bakım
    item("diapers_nb", "Yenidoğan bebek bezi", "baby_care", qty=1, unit="paket", essential=True), item("wipes_baby", "Bebek ıslak mendili (kokusuz)", "baby_care", qty=2, unit="paket"),
    item("cotton_pads", "Pamuk", "baby_care"), item("diaper_cream", "Pişik kremi", "baby_care"),
    item("umbilical_care", "Göbek bakım malzemesi (hastaneye sor)", "baby_care"), item("baby_towel", "Bebek havlusu", "baby_care"),
    item("baby_shampoo", "Bebek şampuanı", "baby_care"), item("nail_file", "Bebek tırnak törpüsü", "baby_care"),
    item("changing_mat", "Alt açma örtüsü", "baby_care"), item("baby_bag", "Bebek çantası", "baby_care"),
    item("pacifier", "Emzik (kullanacaksanız)", "baby_care"), item("thermometer", "Termometre", "baby_care"),
    item("nasal_aspirator", "Burun aspiratörü", "baby_care"), item("baby_laundry_bag", "Kirli çamaşır torbası", "baby_care"),
    # Beslenme
    item("formula_nb", "Yenidoğan maması (hastaneye sor)", "feeding", when=FORMULA), item("bottles", "Biberon (küçük, yenidoğan emzik)", "feeding", when=FORMULA, qty=2),
    item("sterilizer", "Sterilizasyon poşeti / solüsyon", "feeding", when=FORMULA), item("thermos_water", "Termos (mama suyu)", "feeding", when=FORMULA),
    item("burp_cloths", "Gaz çıkarma bezi", "feeding", qty=4, unit="adet"), item("nursing_cover", "Emzirme örtüsü", "feeding", when=BREAST),
    item("milk_storage", "Süt saklama poşeti", "feeding", when=BREAST), item("feeding_log", "Beslenme takip kartı / uygulama", "feeding"),
    # Eve dönüş
    item("car_seat", "Ana kucağı (araç koltuğu) — kurulu", "going_home", essential=True, note="Hastaneden çıkışta zorunlu; önceden araca takıp deneyin."),
    item("stroller", "Bebek arabası / port bebe", "going_home"), item("car_blanket", "Araç için örtü", "going_home", when=COLD),
    item("sun_shade", "Araç güneşliği", "going_home", when=WARM), item("baby_carrier", "Kanguru / sling", "going_home"),
    # Refakatçi
    item("comp_clothes", "Yedek kıyafet (2-3 gün)", "comp", when=COMP), item("comp_toiletries", "Kişisel bakım malzemeleri", "comp", when=COMP),
    item("comp_snacks", "Atıştırmalık ve su", "comp", when=COMP), item("comp_charger", "Şarj aleti / powerbank", "comp", when=COMP),
    item("comp_pillow", "Yastık / battaniye (refakatçi koltuğu için)", "comp", when=COMP), item("comp_slippers", "Terlik", "comp", when=COMP),
    item("comp_cash", "Bozuk para / kart (otopark, kafeterya)", "comp", when=COMP), item("comp_meds", "Kendi ilaçları", "comp", when=COMP),
    item("comp_entertainment", "Kitap / kulaklık", "comp", when=COMP), item("comp_camera", "Kamera / video görevi", "comp", when=COMP),
    item("comp_car_docs", "Araç belgeleri, yakıt dolu", "comp", when=COMP),
    # Evde hazır olsun
    item("h_crib", "Beşik / yatak hazır ve kurulu", "home_prep", essential=True), item("h_diapers", "Bez stoğu (1-2 ay)", "home_prep"),
    item("h_clothes_washed", "Bebek kıyafetleri yıkanmış ve ütülü", "home_prep"), item("h_food", "Dondurulmuş hazır yemekler", "home_prep"),
    item("h_pharmacy", "Ev eczanesi (ateş düşürücü, gaz damlası, serum fizyolojik)", "home_prep", essential=True),
    item("h_changing_station", "Alt değiştirme alanı hazır", "home_prep"), item("h_bath", "Bebek küveti, havlu, termometre", "home_prep"),
    item("h_clean", "Ev temizliği yapılmış", "home_prep"), item("h_sibling_gift", "Kardeşe 'bebekten hediye'", "home_prep", when=SIB),
    item("h_sibling_care", "Kardeş için bakıcı / büyükanne planı", "home_prep", when=SIB, essential=True),
    item("h_visitors", "Ziyaretçi kuralları belirlendi", "home_prep"), item("h_pet", "Evcil hayvan planı", "home_prep"),
    # Görevler
    item("p_pack_bag", "Çantayı hazırla ve kapıya koy", "prep", daysBefore=28, essential=True),
    item("p_car_seat_install", "Ana kucağını araca tak, dene", "prep", daysBefore=21, essential=True),
    item("p_hospital_tour", "Hastane / doğumhane turu, giriş prosedürü", "prep", daysBefore=30),
    item("p_route", "Hastane rotası ve alternatif (trafik saatleri)", "prep", daysBefore=21),
    item("p_pediatrician", "Çocuk doktoru seç", "prep", daysBefore=30),
    item("p_phone_charged", "Telefonlar sürekli şarjda", "prep", daysBefore=14),
    item("p_emergency_contacts", "Acil durumda arayacak kişi planı", "prep", daysBefore=14),
    item("p_sibling_plan", "Kardeş bakım planını netleştir", "prep", when=SIB, daysBefore=21),
    item("p_freezer_meals", "Dondurucuya yemek hazırla", "prep", daysBefore=14),
    item("p_paperwork", "Doğum izni / SGK evrakları", "prep", daysBefore=30),
    item("p_name", "İsim kararı", "prep", daysBefore=14),
    item("p_fuel", "Araç deposu dolu", "prep", daysBefore=7),
]

TEMPLATE = {
    "id": "hastane", "name": "Doğum Çantası",
    "description": "Anne, bebek ve refakatçi için hastane çantası; doğum tipi ve mevsime göre.",
    "icon": "child_friendly", "color": "#D81B60",
    "dateMode": "single", "dateLabel": "Tahmini doğum tarihi", "endDateLabel": None,
    "textFields": [field("hospital", "Hastane", "")],
    "filters": FILTERS, "sections": SECTIONS, "categories": CATEGORIES, "items": items,
}
