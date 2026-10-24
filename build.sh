#!/bin/bash
# www/ 게임 화면을 안드로이드 앱(mom-piano.apk)으로 묶는다. 사용: ./build.sh
set -e
cd "$(dirname "$0")"
SDK=/opt/homebrew/share/android-commandlinetools
BT=$SDK/build-tools/35.0.0
JAR=$SDK/platforms/android-35/android.jar
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
# 서명 열쇠는 저장소 밖에 둔다 (잃어버리면 다음 버전을 덮어 설치할 수 없음)
KS=$HOME/.config/mom-piano/keystore.jks

rm -rf build && mkdir -p build/classes build/dex
$BT/aapt2 compile --dir android/res -o build/res.zip
$BT/aapt2 link -o build/app.apk -I $JAR --manifest android/AndroidManifest.xml -A www build/res.zip
javac -nowarn -source 11 -target 11 -classpath $JAR -d build/classes android/src/com/jmheo/mompiano/MainActivity.java
$BT/d8 --lib $JAR --min-api 24 --output build/dex $(find build/classes -name '*.class')
(cd build/dex && zip -q ../app.apk classes.dex)
$BT/zipalign -f -p 4 build/app.apk build/aligned.apk

if [ ! -f "$KS" ]; then
  mkdir -p "$(dirname "$KS")"
  keytool -genkeypair -keystore "$KS" -alias mompiano -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass mompiano -keypass mompiano -dname "CN=Mom Piano"
fi
$BT/apksigner sign --ks "$KS" --ks-pass pass:mompiano --out mom-piano.apk build/aligned.apk
$BT/apksigner verify mom-piano.apk
echo "완성: $(pwd)/mom-piano.apk ($(du -h mom-piano.apk | cut -f1))"
