@echo off
setlocal

:: Kapanma suresini belirlemek icin kullanicidan dakika al
set /p minutes=Kac dakika sonra kapanacak? :

:: Eger -1 girildiyse iptal et
if "%minutes%"=="-1" (
    shutdown.exe /a
    if %errorlevel% equ 0 (
        echo Kapatma islemi iptal edildi.
    ) else (
        echo Iptal edilecek bir kapatma islemi bulunamadi.
    )
    pause
    exit /b
)

:: Girilen sureyi saniyeye cevir
set /a seconds=%minutes%*60

:: Kapatma komutunu zamanla
shutdown.exe /s /t %seconds%

:: Bilgiyi kullaniciya goster
echo Bilgisayar %minutes% dakika sonra kapanacak.
echo Kapatmayi iptal etmek icin bu dosyayi tekrar calistirin ve -1 girin.
pause
endlocal
