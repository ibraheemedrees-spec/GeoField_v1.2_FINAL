# بناء Geo Field

## 1) GitHub Actions (تلقائي)

الملف: `.github/workflows/build.yml`

1. ارفع المشروع على GitHub
2. من تبويب **Actions** راقب البناء
3. بعد النجاح حمّل الـ Artifact:
   - `GeoField-Windows`
   - `GeoField-Linux`

التشغيل اليدوي: Actions → Build Geo Field → Run workflow

Android معطّل افتراضياً (`if: false`). فعّله بعد ضبط Qt Android SDK.

## 2) بناء محلي – Windows

```bat
build.bat C:\Qt\6.7.2\msvc2019_64
```

أو من Qt Creator: افتح المجلد → Configure → Build.

## 3) بناء محلي – Linux

```bash
chmod +x build.sh
./build.sh $HOME/Qt/6.7.2/gcc_64
```

## المتطلبات

- Qt 6.5+ مع وحدات: SerialPort, Positioning, QuickControls2
- CMake 3.16+
- Ninja (مستحسن)
- Windows: MSVC أو MinGW حسب نسخة Qt
- Android: JDK 17 + Android SDK/NDK عبر Qt Maintenance Tool
