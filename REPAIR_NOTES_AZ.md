# Oliqarx Klub — düzəliş qeydləri

Bu arxiv layihə kökündən başlayır: `pubspec.yaml`, `lib/`, `android/` və `.github/` birbaşa ZIP-in içindədir. Əvvəlki düzəldilmiş ZIP-də layihə `oliqarx/` alt qovluğunda idi; bu, fayllar repoya səhv səviyyədə yüklənərsə GitHub Actions-da `pubspec.yaml` tapılmaması ilə nəticələnə bilərdi.

## Düzəldilənlər
- GitHub Actions üçün Flutter 3.29.3 və Java 17 addımları aydınlaşdırıldı.
- ZIP-də olmayan Gradle wrapper faylları CI zamanı təmiz Flutter Android şablonundan yaradılır; xüsusi tətbiq faylları əvəzlənmir.
- CI addımında `android/local.properties` Flutter və Android SDK yolları ilə yaradılır.
- APK artifact yolu və fayl tapılmadıqda xəta verilməsi açıq göstərildi.
- QR skan ekranında arxa kamera və ön kameranın eyni vaxtda açılmasının qarşısını almaq üçün selfie kamerası QR oxunduqdan sonra başladılır.

## Vacib məhdudiyyətlər
- Bu mühitdə Flutter SDK və internet bağlantısı olmadığından real `flutter build apk` işlədib təsdiqləmək mümkün olmadı. GitHub Actions build nəticəsi hələ yoxlanmalıdır.
- Firebase bulud funksiyaları üçün öz Firebase layihənizin Android konfiqurasiyası (`android/app/google-services.json`) lazımdır. Fayl olmadan demo/offline ekranı açıla bilər, lakin Firebase qeydiyyatı və buludda giriş-çıxış qeydi işləməz.
