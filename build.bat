@echo off
REM بناء Geo Field على Windows
REM الاستخدام: build.bat C:\Qt\6.7.2\msvc2019_64

set QT_PATH=%~1
if "%QT_PATH%"=="" set QT_PATH=C:\Qt\6.7.2\msvc2019_64

echo ==^> Geo Field Windows build
echo     Qt: %QT_PATH%

if not exist "%QT_PATH%" (
  echo Error: Qt path not found: %QT_PATH%
  echo Usage: build.bat C:\Qt\6.x\msvc2019_64
  exit /b 1
)

if not exist build mkdir build
cd build

cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%QT_PATH%
if errorlevel 1 exit /b 1

cmake --build . --config Release
if errorlevel 1 exit /b 1

echo.
echo ==^> Deploying Qt runtime...
where windeployqt >nul 2>&1
if %errorlevel%==0 (
  for /r %%i in (GeoField*.exe) do windeployqt --qmldir ..\resources\qml "%%i"
)

echo.
echo ==^> Build done
dir /b *.exe 2>nul
cd ..
