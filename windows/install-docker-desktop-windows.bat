@echo off
setlocal EnableDelayedExpansion

rem =========================
rem  Yardımcı çıktı fonksiyonları
rem =========================
set "COLOR_INFO=[INFO ]"
set "COLOR_WARN=[WARN ]"
set "COLOR_ERR =[ERROR]"

rem =========================
rem  1. Yönetici yetkisi kontrolü
rem =========================
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo %COLOR_ERR% Bu betiği YONETICI olarak calistirmaniz gerekiyor.
    echo    PowerShell veya Komut Istemi simgesine sag tiklayip
    echo    "Run as administrator / Yonetici olarak calistir" secenegini kullanin.
    pause
    exit /b 1
)

rem =========================
rem  2. Temel sistem bilgisi
rem =========================
echo %COLOR_INFO% Windows surumu:
ver
echo %COLOR_INFO% Mimari: %PROCESSOR_ARCHITECTURE%

rem =========================
rem  3. winget var mi?
rem =========================
where winget >nul 2>&1
if "%errorlevel%"=="0" (
    set "HAS_WINGET=1"
    echo %COLOR_INFO% winget bulundu.
) else (
    set "HAS_WINGET=0"
    echo %COLOR_WARN% winget (Windows Package Manager) bulunamadi.
    echo    Bu betik wget ve Docker Desktop kurulumlari icin winget kullaniyor.
    echo    Lutfen Microsoft Store'dan "App Installer" uygulamasini kurun,
    echo    sonra bu betigi tekrar calistirin.
    pause
    exit /b 1
)

rem =========================
rem  4. wget kurulu mu?
rem =========================
where wget >nul 2>&1
if "%errorlevel%"=="0" (
    set "HAS_WGET=1"
    echo %COLOR_INFO% wget zaten kurulu.
) else (
    set "HAS_WGET=0"
    echo %COLOR_INFO% wget kurulu degil, kurulacak.
)

rem =========================
rem  5. Docker Desktop kurulu mu?
rem =========================
set "DOCKER_DESKTOP_EXE_SYS=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
set "DOCKER_DESKTOP_EXE_USER=%LocalAppData%\Programs\Docker\Docker\Docker Desktop.exe"

set "HAS_DOCKER_DESKTOP=0"
if exist "%DOCKER_DESKTOP_EXE_SYS%" (
    set "HAS_DOCKER_DESKTOP=1"
) else if exist "%DOCKER_DESKTOP_EXE_USER%" (
    set "HAS_DOCKER_DESKTOP=1"
)

where docker >nul 2>&1
if "%errorlevel%"=="0" (
    set "HAS_DOCKER_CLI=1"
) else (
    set "HAS_DOCKER_CLI=0"
)

if "%HAS_DOCKER_DESKTOP%"=="1" (
    echo %COLOR_INFO% Docker Desktop zaten kurulu.
) else (
    echo %COLOR_INFO% Docker Desktop kurulu degil, kurulacak.
)

rem =========================
rem  6. wget kurulumu (gerekirse)
rem =========================
if "%HAS_WGET%"=="0" (
    echo %COLOR_INFO% wget winget ile kuruluyor...
    winget install -e --id JernejSimoncic.Wget --accept-package-agreements --accept-source-agreements
    if not "%errorlevel%"=="0" (
        echo %COLOR_ERR% wget kurulumu basarisiz oldu. Cikis kodu: %errorlevel%
        pause
        exit /b 1
    )
    rem yeniden kontrol et
    where wget >nul 2>&1
    if not "%errorlevel%"=="0" (
        echo %COLOR_WARN% wget kuruldu ama PATH'e eklenmemis olabilir.
    ) else (
        echo %COLOR_INFO% wget kuruldu.
    )
)

rem =========================
rem  7. Docker Desktop kurulumu (gerekirse)
rem =========================
if "%HAS_DOCKER_DESKTOP%"=="0" (
    echo %COLOR_INFO% Docker Desktop winget ile kuruluyor...
    winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
    if not "%errorlevel%"=="0" (
        echo %COLOR_ERR% Docker Desktop kurulumu basarisiz oldu. Cikis kodu: %errorlevel%
        pause
        exit /b 1
    )
) else (
    echo %COLOR_INFO% Docker Desktop zaten kurulu, yeniden kurulmayacak.
)

rem =========================
rem  8. Docker Desktop baslatma
rem =========================
echo %COLOR_INFO% Docker Desktop baslatiliyor...

if exist "%DOCKER_DESKTOP_EXE_SYS%" (
    start "" "%DOCKER_DESKTOP_EXE_SYS%"
) else if exist "%DOCKER_DESKTOP_EXE_USER%" (
    start "" "%DOCKER_DESKTOP_EXE_USER%"
) else (
    echo %COLOR_WARN% Docker Desktop.exe bulunamadi. Gerekirse Baslat menusu uzerinden acin.
)

rem =========================
rem  9. Docker daemon hazir mi? (max 3 dakika)
rem =========================
echo %COLOR_INFO% Docker servisinin hazir hale gelmesi bekleniyor (en fazla 3 dakika)...

set /a MAX_SECONDS=180
set /a SLEEP_INTERVAL=5
set /a ELAPSED=0
set "READY=0"

:WAIT_LOOP
if %ELAPSED% GEQ %MAX_SECONDS% goto WAIT_DONE

where docker >nul 2>&1
if "%errorlevel%"=="0" (
    docker info >nul 2>&1
    if "%errorlevel%"=="0" (
        set "READY=1"
        goto WAIT_DONE
    )
)

timeout /t %SLEEP_INTERVAL% /nobreak >nul
set /a ELAPSED+=SLEEP_INTERVAL
goto WAIT_LOOP

:WAIT_DONE
if "%READY%"=="1" (
    echo %COLOR_INFO% Docker daemon calisiyor ve erisilebilir.
) else (
    echo %COLOR_WARN% Docker daemon hazir gorunmuyor.
    echo    Docker Desktop penceresini acip lisans sozlesmelerini onaylamaniz,
    echo    WSL2/Hyper-V gibi bileşenleri tamamlamaniz gerekebilir.
)

rem =========================
rem  10. Kurulum testi
rem =========================
echo %COLOR_INFO% Kurulum testi: docker --version

where docker >nul 2>&1
if "%errorlevel%"=="0" (
    docker --version
) else (
    echo %COLOR_ERR% docker komutu bulunamadi. Kurulum basarisiz ya da PATH'e eklenmemis olabilir.
    pause
    exit /b 1
)

echo.
echo %COLOR_INFO% Test icin asagidaki komutu calistirabilirsiniz:
echo    docker run hello-world
echo.
echo %COLOR_INFO% Betik tamamlandi.
pause

endlocal
exit /b 0
