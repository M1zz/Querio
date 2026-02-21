# Querio Todo

## 완료
- [x] 데이터 유실 방지 — JSON 자동 백업 + 복구 시스템 (BackupManager)
- [x] BackupManager.swift를 Xcode 빌드 대상에 추가 (project.pbxproj 누락 수정)
- [x] iCloud CloudKit 엔타이틀먼트 파일 생성 (Querio.entitlements)
- [x] QuerioApp.swift에 SwiftData + CloudKit 설정 추가 (로컬 폴백 포함)
- [x] project.pbxproj에 엔타이틀먼트 파일 참조 추가

## 남은 작업 (수동 Xcode 설정 필요)
- [ ] Apple Developer 계정에서 iCloud CloudKit 컨테이너 `iCloud.com.querio.app` 등록
  - developer.apple.com → Certificates → Identifiers → App IDs → `com.querio.app`
  - iCloud 체크 → CloudKit 컨테이너 `iCloud.com.querio.app` 생성
- [ ] Xcode: Signing & Capabilities → iCloud 추가 → CloudKit 체크 (선택적, 수동으로도 가능)
- [ ] Development Team ID를 project.pbxproj 또는 Xcode에서 설정

## 향후 개선
- [ ] CloudKit 동기화 상태 UI 표시 (동기화 중 인디케이터)
- [ ] 충돌 해결 정책 설정
- [ ] App Store 배포 시 App Sandbox 활성화 + 데이터 마이그레이션 처리
