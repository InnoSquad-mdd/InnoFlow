# 샘플 앱 실행 가이드

Xcode 프로젝트가 생성되었습니다! 이제 샘플 앱을 실행할 수 있습니다.

## 🚀 실행 방법

### CounterApp 실행

1. **Xcode에서 프로젝트 열기**
   ```
   Examples/CounterApp/CounterApp.xcworkspace
   ```
   ⚠️ **중요**: `.xcodeproj`가 아닌 `.xcworkspace`를 열어야 합니다!

2. **스킴 선택**
   - 상단 툴바에서 "CounterApp" 스킴 선택
   - 시뮬레이터 또는 실제 기기 선택

3. **빌드 및 실행**
   - `Cmd + R` 또는 ▶️ 버튼 클릭

### TodoApp 실행

1. **Xcode에서 프로젝트 열기**
   ```
   Examples/TodoApp/TodoApp.xcworkspace
   ```
   ⚠️ **중요**: `.xcodeproj`가 아닌 `.xcworkspace`를 열어야 합니다!

2. **스킴 선택**
   - 상단 툴바에서 "TodoApp" 스킴 선택
   - 시뮬레이터 또는 실제 기기 선택

3. **빌드 및 실행**
   - `Cmd + R` 또는 ▶️ 버튼 클릭

## 📦 프로젝트 구조

각 샘플 앱은 다음과 같은 구조로 되어 있습니다:

```
CounterApp/
├── CounterApp.xcworkspace      # 워크스페이스 (이것을 열어야 함!)
├── CounterApp.xcodeproj/        # Xcode 프로젝트
├── CounterApp/                  # 앱 타겟
│   └── CounterAppApp.swift      # 앱 진입점
└── CounterAppPackage/           # Swift Package
    └── Sources/
        └── CounterAppFeature/
            └── ContentView.swift # Feature 및 View 코드
```

## 🔧 문제 해결

### "No such module 'InnoFlow'" 오류

1. Xcode에서 `File > Packages > Reset Package Caches` 실행
2. `File > Packages > Resolve Package Versions` 실행
3. 프로젝트 클린: `Product > Clean Build Folder` (Shift + Cmd + K)
4. 다시 빌드: `Product > Build` (Cmd + B)

### 패키지 의존성 문제

프로젝트가 InnoFlow 패키지를 찾지 못하는 경우:

1. `CounterAppPackage/Package.swift` 또는 `TodoAppPackage/Package.swift` 확인
2. 의존성 경로가 올바른지 확인:
   ```swift
   .package(path: "../../../InnoFlow")
   ```
3. 워크스페이스를 닫고 다시 열기

### 빌드 오류

1. **Swift 버전 확인**: Xcode 16.0 이상 필요
2. **플랫폼 확인**: iOS 18.4 이상 타겟
3. **매크로 지원**: `@Reducer` 매크로가 제대로 확장되는지 확인
   - Build Settings에서 "Enable Macros" 확인

## 📝 참고사항

- 각 프로젝트는 **로컬 InnoFlow 패키지**를 의존성으로 사용합니다
- Swift Package Manager를 통해 자동으로 연결됩니다
- 워크스페이스(`.xcworkspace`)를 사용하는 이유는 Swift Package를 포함하기 때문입니다

## ✅ 확인 사항

프로젝트가 제대로 설정되었는지 확인:

1. ✅ `.xcworkspace` 파일이 존재하는가?
2. ✅ Package.swift에 InnoFlow 의존성이 추가되었는가?
3. ✅ ContentView.swift에 InnoFlow import가 있는가?
4. ✅ 앱 타겟이 CounterAppFeature/TodoAppFeature 패키지를 의존하는가?

모든 항목이 확인되면 빌드 및 실행이 가능합니다!

---

**문제가 계속되면**: 이슈를 등록하거나 프로젝트를 다시 생성해보세요.



