@echo off
rem APK'yi uretir ve USB ile bagli Android telefona kurar.
rem Kullanim: tools\telefona_kur.cmd   (proje klasorunden)
setlocal
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
cd /d "%~dp0.."
if not exist build mkdir build
echo [1/3] APK uretiliyor...
call godot --headless --path . --export-debug "Android" build\kebap-bandi.apk >nul 2>&1
if not exist build\kebap-bandi.apk (
  echo APK uretilemedi. Godot'yu acip Proje - Disa Aktar penceresindeki hatalara bakin.
  exit /b 1
)
echo [2/3] Telefon araniyor...
"%ADB%" devices
echo [3/3] Kuruluyor...
"%ADB%" install --no-incremental -r build\kebap-bandi.apk
if errorlevel 1 (
  echo Kurulamadi. Telefon bagli mi, USB hata ayiklama acik mi, telefondaki izin sorusuna "Izin ver" dediniz mi?
  exit /b 1
)
"%ADB%" shell monkey -p com.aysebeyza.kebapbandi 1 >nul 2>&1
echo Tamam. Oyun telefonda acildi.
