#!/bin/bash
# cc-promo-video 준비물 확인·설치
# 있으면 건너뛰고, 없으면 설치해요. 몇 번을 다시 돌려도 괜찮아요.
# 사용: bash scripts/setup.sh            (전부)
#       bash scripts/setup.sh --no-whisper  (받아쓰기 모델 빼고)
set -u
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODEL_DIR="${CC_PROMO_HOME:-$HOME/.cc-promo-video}/models"   # 플러그인 업데이트해도 안 지워지는 곳
MODEL="$MODEL_DIR/ggml-large-v3-turbo-q5_0.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"
WANT_WHISPER=1
[ "${1:-}" = "--no-whisper" ] && WANT_WHISPER=0

ok()   { echo "  ✓ $1"; }
doit() { echo "  → $1"; }
bad()  { echo "  ✗ $1"; FAILED=1; }
FAILED=0
OS="$(uname -s)"

have() { command -v "$1" >/dev/null 2>&1; }

pkg_install() {  # pkg_install <brew이름> <apt이름>
  if have brew; then brew install "$1"
  elif have apt-get; then sudo apt-get update -qq && sudo apt-get install -y "$2"
  elif have winget; then winget install -e --id "$3"
  else return 1; fi
}

echo "[1/5] Homebrew (맥만)"
if [ "$OS" = "Darwin" ]; then
  if have brew; then ok "brew 있음"
  else
    bad "Homebrew가 없어요. 비밀번호가 필요해서 직접 설치해 주세요:"
    echo '      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo "      설치 후 이 스크립트를 다시 돌리면 나머지는 알아서 깔려요."
  fi
else ok "맥이 아니라 건너뜀"; fi

echo "[2/5] Node.js 22 이상 (HyperFrames용)"
NODE_MAJOR=0
have node && NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$NODE_MAJOR" -ge 22 ]; then ok "node $(node -v)"
else
  doit "node 설치/업데이트 (지금: ${NODE_MAJOR})"
  pkg_install node nodejs OpenJS.NodeJS || bad "node를 자동으로 못 깔았어요. https://nodejs.org 에서 LTS를 받아 주세요."
fi

echo "[3/5] FFmpeg"
if have ffmpeg && have ffprobe; then ok "$(ffmpeg -version | head -1 | cut -d' ' -f1-3)"
else
  doit "ffmpeg 설치"
  pkg_install ffmpeg ffmpeg Gyan.FFmpeg || bad "ffmpeg를 자동으로 못 깔았어요. https://ffmpeg.org/download.html"
fi

echo "[4/5] HyperFrames + 렌더용 Chrome"
if have npx; then
  if V="$(npx --yes hyperframes --version 2>/dev/null | tail -1)" && [ -n "$V" ]; then
    ok "hyperframes $V (npx로 실행, 따로 설치 필요 없음)"
    npx --yes hyperframes browser ensure >/dev/null 2>&1 && ok "렌더용 Chrome 준비됨" || bad "Chrome 다운로드 실패 — 'npx hyperframes browser ensure --force'로 다시 해 보세요"
  else bad "hyperframes 실행 실패 — 인터넷 연결을 확인해 주세요"; fi
else bad "npx가 없어요 (node 설치가 먼저예요)"; fi

echo "[5/5] 파이썬 Pillow + 받아쓰기(whisper)"
if have python3; then
  if python3 -c "import PIL" 2>/dev/null; then ok "Pillow 있음"
  else
    doit "Pillow 설치"
    python3 -m pip install --user -q pillow 2>/dev/null || python3 -m pip install --user -q --break-system-packages pillow || bad "Pillow 설치 실패: python3 -m pip install --user pillow"
  fi
else bad "python3가 없어요"; fi

if [ "$WANT_WHISPER" = 1 ]; then
  if have whisper-cli; then ok "whisper-cli 있음"
  else
    doit "whisper-cpp 설치"
    pkg_install whisper-cpp whisper-cpp none || bad "whisper-cli를 자동으로 못 깔았어요. https://github.com/ggml-org/whisper.cpp"
  fi
  if [ -s "$MODEL" ]; then ok "한국어 받아쓰기 모델 있음"
  else
    doit "받아쓰기 모델 내려받기 (약 550MB, 처음 한 번만)"
    mkdir -p "$MODEL_DIR"
    curl -L --fail -o "$MODEL.part" "$MODEL_URL" && mv "$MODEL.part" "$MODEL" && ok "모델 저장: $MODEL" || bad "모델 다운로드 실패"
  fi
else ok "받아쓰기는 건너뜀 (--no-whisper)"; fi

echo
if [ "$FAILED" = 0 ]; then echo "준비 끝. 이제 영상 만들 수 있어요."
else echo "위에 ✗ 표시된 것만 해결하고 다시 돌려 주세요."; exit 1; fi
