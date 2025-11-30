# InnoFlow 샘플 앱 모음

InnoFlow를 사용한 실제 예제 애플리케이션들입니다.

## 📱 사용 가능한 샘플 앱

### 1. CounterApp

**가장 간단한 예제** - Effect가 없는 기본적인 카운터 앱

- 카운터 증가/감소
- 카운터 리셋
- 증감 단위 설정

**학습 포인트**:
- `@Reducer` 매크로 기본 사용법
- Effect가 없는 Feature 구현
- `@dynamicMemberLookup` 활용

[자세히 보기 →](./CounterApp/README.md)

---

### 2. TodoApp

**실전 예제** - 비동기 Effect를 사용한 Todo 관리 앱

- Todo CRUD (생성/읽기/수정/삭제)
- 완료 상태 토글
- 필터링 (전체/미완료/완료)
- 데이터 영속성 (UserDefaults)
- 비동기 데이터 로딩

**학습 포인트**:
- 비동기 Effect 처리
- 의존성 주입 패턴
- 프로토콜 기반 서비스 설계
- SOLID 원칙 적용

[자세히 보기 →](./TodoApp/README.md)

---

## 🎯 각 샘플 앱의 특징

### CounterApp
```
복잡도: ⭐
Effect 사용: ❌
의존성 주입: ❌
```

### TodoApp
```
복잡도: ⭐⭐⭐
Effect 사용: ✅
의존성 주입: ✅
```

---

## 🚀 실행 방법

각 샘플 앱은 독립적으로 실행 가능합니다:

1. Xcode에서 프로젝트 열기
2. 원하는 샘플 앱의 타겟 선택
3. 시뮬레이터 또는 실제 기기에서 실행

---

## 📚 학습 순서 추천

1. **CounterApp**부터 시작하여 기본 개념 이해
2. **TodoApp**으로 실전 패턴 학습
3. 자신만의 앱에 적용

---

## 🔍 코드 분석

각 샘플 앱은 SOLID 원칙을 준수하며, InnoFlow의 모범 사례를 보여줍니다:

- ✅ Single Responsibility: 각 컴포넌트가 명확한 책임
- ✅ Open/Closed: 프로토콜 기반 확장 가능한 설계
- ✅ Liskov Substitution: 프로토콜 구현체 교체 가능
- ✅ Interface Segregation: 최소한의 인터페이스
- ✅ Dependency Inversion: 프로토콜에 의존

---

**더 많은 예제가 필요하신가요?** 이슈를 등록해주세요!



