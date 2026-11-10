#!/bin/bash
# 사용: snap_sheet.sh "t1,t2,..." out.jpg [열수] [프로젝트폴더]
# 지정한 시점의 장면을 찍어 360px 타일 한 장으로 이어 붙여요. 내 컴퓨터에서 돌려요.
set -e
PROJ="${4:-.}"
TMP="$(mktemp -d)"
npx --yes hyperframes snapshot "$PROJ" --at "$1" --no-end -o "$TMP" > /dev/null 2>&1
f=( $(ls "$TMP"/frame-*.png | sort -V) )
ins=(); for x in "${f[@]}"; do ins+=(-i "$x"); done
n=${#f[@]}; cols=${3:-4}
fc=""; for ((i=0;i<n;i++)); do fc+="[$i]scale=360:-1[a$i];"; done
for ((i=0;i<n;i++)); do fc+="[a$i]"; done
fc+="xstack=inputs=$n:layout="
lay=""; for ((i=0;i<n;i++)); do c=$((i%cols)); r=$((i/cols)); lay+="$((c*360))_$((r*270))|"; done
fc+="${lay%|}"
ffmpeg -v error -y "${ins[@]}" -filter_complex "$fc" -q:v 3 "$2"
rm -rf "$TMP"
echo "snapped → $2"
