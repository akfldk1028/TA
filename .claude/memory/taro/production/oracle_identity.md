---
name: 오라클 (Oracle) 앱 정체성 — Android + iOS 전면 교체
description: 2026-04-16 com.example.taro_a2ui → com.clickaround.oracle 완료. keystore 만 대기
type: production
---

# 오라클 앱 정체성 (2026-04-16 교체)

## 최종 값

| 속성 | 값 |
|---|---|
| 표시 앱 명 | 오라클 |
| Android applicationId / namespace | `com.clickaround.oracle` |
| iOS bundle ID | `com.clickaround.oracle` |
| iOS RunnerTests bundle ID | `com.clickaround.oracle.RunnerTests` |
| iOS CFBundleDisplayName | `오라클` |
| iOS CFBundleName | `oracle` |
| android:label | `오라클` |
| 조직 네임스페이스 | `com.clickaround.*` (MOL 레포와 통일) |

Flutter 프로젝트 name (pubspec.yaml) 은 `taro_a2ui` 그대로 — 변경 시 generated files 광범위 영향, 스토어에 노출 안 되므로 유지.

## 변경된 파일 (2026-04-16)

### Android

- `android/app/build.gradle.kts`:
  - `namespace`, `applicationId` → `com.clickaround.oracle`
  - import `java.util.Properties` + `keystoreProperties` 로더
  - `signingConfigs { create("release") {...} }` 블록 추가 (key.properties 존재 시 값 로드)
  - `buildTypes.release.signingConfig` — key.properties 존재 시 release, 없으면 debug 폴백
- `android/app/src/main/AndroidManifest.xml`:
  - `android:label="오라클"`
  - `BLUETOOTH`, `BLUETOOTH_CONNECT` `<uses-permission>` 삭제 (Dart 사용처 0건 확인)
- `android/app/src/main/kotlin/com/clickaround/oracle/MainActivity.kt`:
  - 새 경로로 이동. `package com.clickaround.oracle` 선언
  - 기존 `com/example/taro_a2ui/MainActivity.kt` + 빈 디렉토리 삭제

### iOS

- `ios/Runner.xcodeproj/project.pbxproj`:
  - Runner target 3개 Debug/Release/Profile `PRODUCT_BUNDLE_IDENTIFIER = com.clickaround.oracle`
  - RunnerTests target 3개 `PRODUCT_BUNDLE_IDENTIFIER = com.clickaround.oracle.RunnerTests`
- `ios/Runner/Info.plist`:
  - `CFBundleDisplayName = 오라클`
  - `CFBundleName = oracle`

### 기타

- `.gitignore`: `android/key.properties`, `android/app/*.jks`, `android/app/*.keystore` 추가 (keystore 유출 방지)

### 아이콘/스플래시

`flutter_launcher_icons` + `flutter_native_splash` 실행 완료. mipmap-* / drawable-* / iOS Assets.xcassets 전부 교체됨 (git status 에 수정 표시).

## 🔴 남은 수동 작업

### 1. Release keystore 생성 (사용자 JDK 설치 필요)

```bash
cd C:/DK/TA/TA/android/app
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

비밀번호는 Password Manager 에 백업. 잃으면 Play Console 에서 새 앱으로 취급.

### 2. `android/key.properties` 작성 (gitignored)

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=app/upload-keystore.jks
```

경로는 `rootProject` (= `android/`) 기준 상대경로.

### 3. 검증 빌드

```bash
cd C:/DK/TA/TA
flutter clean
flutter pub get
flutter build apk --debug    # rename 오류 없는지
aapt dump badging build/app/outputs/flutter-apk/app-debug.apk | grep package
# → package: name='com.clickaround.oracle' 확인

flutter build appbundle --release  # keystore 연결 후 Play Store 업로드 파일
```

## 검증 스냅샷

- `flutter analyze lib/` — errors 0, info 7 (override param 이름 1개 + 기존 코드 이슈 6개). 컴파일 통과 확인 후 세션 종료.
- git 은 아직 uncommitted — 세션 시작 시 `git status` 로 확인.

## 하지 말 것

- `pubspec.yaml` 의 `name: taro_a2ui` 변경 금지 — Flutter 프로젝트 key. 바꾸면 generated 파일/import path 전부 깨짐.
- `keystore` 및 `key.properties` 커밋 금지 — .gitignore 에 이미 있음, 재확인.
- `com.example.*` 되돌리지 말 것 — Play Store 자동 거부.