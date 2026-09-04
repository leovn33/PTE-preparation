# PTE Compass

PTE Academic 학습 준비를 위한 웹앱 — 레벨 진단, 맞춤 학습 플랜, 스킬별 연습 모듈 제공.

## 배포

이 저장소는 Vercel과 연결되어 정적 사이트로 자동 배포됩니다. `index.html` 하나로 동작하는 단일 페이지 앱입니다.

## 참고

- 기기 간 진행 상황 동기화는 Supabase RPC 함수(login_profile/get_state/save_state)로 이루어집니다. `supabase_setup.sql`을 Supabase SQL Editor에서 한 번 실행하세요.
- 프로필을 건너뛰면 브라우저 로컬 저장소(localStorage)에만 진행 상황이 저장됩니다.
