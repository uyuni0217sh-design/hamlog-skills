# hamlog-skills

햄로그가 실제 작업에 쓰는 Claude Code 스킬 모음이에요.

## cc-promo-video — 클코 홍보영상

편집 프로그램 없이 Claude Code에게 말로 시켜 강의·워크숍·행사 홍보 영상(4:3, 1440×1080)을 만드는 스킬이에요.
시안 고르기 → 대본 확정 → HyperFrames 화면 → 내레이션 → 렌더 → 음악 덕킹 믹스까지 한 흐름으로 가요.

### 설치

Claude Code에서 두 줄을 입력해요.

```
/plugin marketplace add uyuni0217sh-design/hamlog-skills
/plugin install cc-promo-video@hamlog-skills
```

설치 후 "홍보 영상 만들어줘"라고 말하면 스킬이 켜져요.

### 처음 쓸 때

준비물(Node.js 22+, FFmpeg, HyperFrames, 파이썬 Pillow, whisper 받아쓰기)이 있는지 확인하고, 없는 것만 설치해요. Claude가 알아서 돌리지만 직접 돌려도 돼요.

- 맥에 Homebrew가 없으면 비밀번호가 필요해서 설치 명령만 알려 줘요. 그 한 줄은 직접 실행해 주세요.
- 받아쓰기 모델(약 550MB)과 목소리 설정은 `~/.cc-promo-video/`에 저장돼서 업데이트해도 남아요.
- 내레이션 목소리는 처음에 고르게 물어봐요: 일레븐랩스 내 클론 목소리 / 일레븐랩스 라이브러리 목소리 / 직접 녹음. 일레븐랩스 API 키는 파일에 적지 않고 환경 변수 `ELEVENLABS_API_KEY`로 써요.

### 업데이트

```
/plugin marketplace update hamlog-skills
```

### 글꼴

에이투지체(A2Z)가 들어 있어요. SIL Open Font License 1.1이에요(`assets/fonts/OFL.txt`). 원본: https://github.com/Freesentation/A2Z
