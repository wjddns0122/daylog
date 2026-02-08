# 📸 @Daylog (데이로그)

> **"천천히 흐르는 당신의 하루, @Daylog"**
> _1일 1회 촬영, 6시간의 기다림이 만드는 AI 감성 기록 플랫폼_

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

---

## 🌟 Project Concept

자극적이고 빠른 콘텐츠의 홍수 속에서, `@Daylog`는 **'의도적 느림'**을 제안합니다.
찰나의 순간을 소중히 담고, 현상되는 시간을 기다리며, AI '다라(Dara)'의 따뜻한 시선으로 하루를 마무리하세요.

---

## ✨ Key Features

- **Slow Shutter:** 하루 단 한 번의 촬영 기회, 찍는 순간 시작되는 6시간의 기다림.
- **AI Dara:** Gemini 1.5 Pro 기반 이미지 분석을 통한 맞춤형 위로 문구 및 BGM 큐레이션.
- **Reasoning Disclosure:** AI가 왜 이 문구를 선택했는지, 사진의 색감과 분위기를 분석한 과정 공유.
- **Journaling:** 인화된 추억 아래 남기는 나만의 한 줄 기록.
- **Viral Share:** 인스타그램 스토리에 최적화된 감성 레이아웃 자동 생성.

## 🛠 Tech Stack

### 📱 Frontend

| Category             | Tech                                                                                                   |
| :------------------- | :----------------------------------------------------------------------------------------------------- |
| **Framework**        | <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=Flutter&logoColor=white"> |
| **State Management** | `Riverpod`, `Freezed`                                                                                  |
| **Patterns**         | `MVVM Architecture`                                                                                    |
| **Testing**          | `Golden_test` (TDD)                                                                                    |

### ☁️ Backend & AI

| Category       | Tech                                                                                                     |
| :------------- | :------------------------------------------------------------------------------------------------------- |
| **Platform**   | <img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black"> |
| **Database**   | `Cloud Firestore`                                                                                        |
| **Serverless** | `Cloud Functions` (Node.js)                                                                              |
| **AI Model**   | `Gemini 1.5 Pro` (Vertex AI)                                                                             |

### ⚙️ DevOps & QA

| Category           | Tech                                                                                                                   |
| :----------------- | :--------------------------------------------------------------------------------------------------------------------- |
| **CI/CD**          | <img src="https://img.shields.io/badge/GitHub%20Actions-2088FF?style=flat-square&logo=github-actions&logoColor=white"> |
| **Analysis**       | <img src="https://img.shields.io/badge/SonarQube-4E9BCD?style=flat-square&logo=sonarqube&logoColor=white">             |
| **Infrastructure** | <img src="https://img.shields.io/badge/GCP-4285F4?style=flat-square&logo=google-cloud&logoColor=white">                |

## 📂 Project Structure (MVVM + Riverpod)

```text
lib/
├── core/                # 공통 유틸, 테마, 상수
├── data/                # 데이터 모델(Freezed) 및 레포지토리
├── providers/           # Riverpod 상태 관리 및 비즈니스 로직
├── services/            # 외부 API 서비스 (Firebase, Gemini)
└── presentation/        # View(Screens) 및 ViewModel(Providers)
    ├── view_models/     # 각 화면별 상태 관리 로직
    ├── views/           # UI 화면 (Camera, Home, Result, Archive)
    └── widgets/         # 공통 컴포넌트
```

---

## 🤖 3. ADD (AI Driven Development) Environment

우리 팀은 AI를 단순한 도구가 아닌 **'동료 개발자'**로 대우하며 개발합니다.

| 구분               | 도구                    | 역할                                              |
| :----------------- | :---------------------- | :------------------------------------------------ |
| **Orchestrator**   | **Antigravity**         | 프로젝트 전체 구조 이해 및 자율 코딩 에이전트     |
| **Interface**      | **Gemini CLI**          | 터미널 기반 즉각적인 디버깅 및 자동화 쉘 스크립트 |
| **Design to Code** | **Figma MCP**           | 피그마 시안을 Flutter 위젯 코드로 즉시 변환       |
| **DevOps Agent**   | **GitHub MCP**          | AI가 직접 PR 생성, 코드 리뷰 및 이슈 관리         |
| **Logic Design**   | **Sequential Thinking** | 복잡한 타이머 및 AI 분석 로직의 단계별 설계       |

---

## 💬 4. Slack Collaboration & Monitoring

모든 개발 및 서비스 상황은 슬랙을 통해 실시간 공유됩니다.

- **`#0-general`**: 팀 소통 및 주요 의사결정
- **`#1-dev-git`**: GitHub 커밋, PR, 이슈 업데이트 알림
- **`#2-dev-qa`**: SonarQube 분석 리포트 및 Crashlytics 에러 로그
- **`#3-service-log`**: 유저 가입, 사진 업로드, 현상 완료 등 실시간 서비스 지표

---

## 📜 5. Conventions

### 💻 Code Convention (Effective Dart)

- **Naming:** - Classes: `PascalCase`
  - Variables/Methods: `camelCase`
  - Files: `snake_case`
- **Architecture:** MVVM 레이어를 엄격히 준수 (`View` <-> `ViewModel` <-> `Model`)
- **State:** 모든 데이터 모델은 `Freezed`를 사용한 불변 객체로 정의

### 🌿 Git Flow & PR Convention

- **Branch Strategy:** `main` <- `develop` <- `feat/feature-name`
- **Commit Message Format:** `[Type]: Subject`
  - `Feat`: 새로운 기능 추가
  - `Fix`: 버그 수정
  - `Docs`: 문서 수정
  - `Style`: 코드 포맷팅 (로직 변경 없음)
  - `Refactor`: 코드 리팩토링
- **PR Rules:** 최소 1명 이상의 AI 에이전트 혹은 팀원 승인 후 머지 가능

---

## 📄 License

This project is licensed under the **MIT License**.

Copyright © 2026 A&I 4th. All rights reserved.
