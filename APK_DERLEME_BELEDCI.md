# OLİQARX KLUB - FLUTTER 2026 APK DERLƏMƏ BƏLƏDÇİSİ

## NİYƏ KÖHNƏ KODLARDA XƏTA ALIRDINIZ?
1. **Gradle 8 & Java 17 Uyuşmazlığı:** Köhnə Android Gradle eklentiləri `buildDir` kök qovluq xətası verirdi.
2. **Kəsilmiş və Yarımçıq Kod Blokları:** `MainActivity.kt` və `admin_home_screen.dart` fayllarında `}` bağlanmamışdı.
3. **Simvol Korlanması (Encoding Corruption):** Azərbaycan hərfləri (ş, ı, ə, ğ) xarab olduğu üçün Dart analizatoru xəta verirdi.
4. **Kamera Ziddiyyəti:** Arxa QR kamera ilə ön selfie kamerası eyni vaxtda açıldıqda Android sistemi kameranı bloklayırdı.

---

## 🚀 ÜSUL 1: GITHUB ACTIONS İLƏ BULUDDA PULSUZ .APK ALMAQ (ƏN ASAN)
1. Kodları ZIP olaraq bu paneldən endirin ("Bütün Layihəni ZIP Kimi Endir").
2. GitHub-da yeni bir repo yaradın (məs: `oliqarx-klub-pdks`).
3. Faylları repoya yükləyin (Push).
4. **Actions** tabına daxil olun. Avtomatik olaraq APK derləməsi başlayacaq!
5. 2 dəqiqə sonra **Artifacts** bölməsindən hazır `oliqarxklub-release-apk` (.apk) faylını birbaşa telefonunuza yükləyin.

---

## 💻 ÜSUL 2: ÖZ KOMPÜTERİNİZDƏ DERLƏMƏK
Terminalda layihə qovluğunda bu əmrləri icra edin:

```bash
# 1. Asılılıqları təmizlə və yenidən çək
flutter clean
flutter pub get

# 2. Release APK faylını derlə
flutter build apk --release --no-tree-shake-icons
```

Hazır fayl burada yaranacaq:
`build/app/outputs/flutter-apk/app-release.apk`
