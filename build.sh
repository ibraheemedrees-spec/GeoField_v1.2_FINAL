#!/usr/bin/env bash
# بناء Geo Field محلياً (Linux / macOS)
# الاستخدام: ./build.sh [/path/to/Qt]

set -e
QT_PATH="${1:-$HOME/Qt/6.7.2/gcc_64}"
BUILD_DIR="build"

echo "==> Geo Field build"
echo "    Qt: $QT_PATH"

if [ ! -d "$QT_PATH" ]; then
  echo "Error: Qt path not found: $QT_PATH"
  echo "Usage: ./build.sh /path/to/Qt/6.x/gcc_64"
  exit 1
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$QT_PATH"

cmake --build . -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

echo ""
echo "==> Build done"
echo "    Binary: $BUILD_DIR/GeoField (or similar)"
ls -la GeoField* 2>/dev/null || ls -la
