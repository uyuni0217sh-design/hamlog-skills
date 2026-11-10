# 기술 레시피

## 렌더 (내 컴퓨터)

```bash
npx hyperframes lint ./<proj>        # 렌더 전 검사
npx hyperframes render ./<proj> --output ./silent.mp4 --fps 30 --quality high > render.log 2>&1; echo RENDERDONE=$? >> render.log
```

- 렌더는 몇 분 걸려요. Claude Code에서는 백그라운드로 돌리고 `render.log`의 `RENDERDONE=0`을 확인해요.
- 디스크 여유가 1GB 아래면 HyperFrames가 렌더를 거부해요. 지난 렌더본·`npx hyperframes clean`으로 공간을 비우거나, 임시 파일을 외장 드라이브로 보내요: `--frames-cache-dir /Volumes/<외장>/hf-cache`.
- 준비물이 이상하면 `npx hyperframes doctor`로 확인해요.
- 렌더용 서버(원격 맥 등)가 따로 있으면 폴더를 `rsync`로 보내 같은 명령을 `ssh`로 돌려도 돼요. 이때 파이썬 패치·셸 스크립트는 따옴표가 깨지지 않게 파일로 보내서 실행해요.

## 스냅샷 시트

`scripts/snap_sheet.sh "66.9,67.1,67.3" out.jpg 4 ./<proj>` — 지정 시점 스냅샷을 찍어 360px 타일로 이어 붙여요.

## 인트로 디졸브

```bash
ffmpeg -ss <본편 시작점> -i silent.mp4 -an -c:v libx264 -crf 17 r.mp4
ffmpeg -i intro.mp4 -i r.mp4 -filter_complex "[0:v]settb=1/30,setpts=PTS-STARTPTS[a];[1:v]settb=1/30,setpts=PTS-STARTPTS[b];[a][b]xfade=transition=fade:duration=0.7:offset=<인트로길이-0.7>,format=yuv420p[v]" -map "[v]" out.mp4
```

인트로 자막은 투명 PNG를 `-loop 1`로 넣고 `fade=t=in/out:alpha=1`로 구간만 보이게 overlay해요.

## 속삭임 장면 끼워 넣기

1. 영상 자르는 점 V(앞 장면 마지막 깨끗한 프레임), 다시 시작점 V2(다음 장면 첫 깨끗한 프레임), 내레이션 자르는 점 P(문장 사이 쉼)를 받아쓰기·스냅샷으로 정해요.
2. V 직전 프레임을 PNG로 뽑아 `fade=t=out:d=0.5` 배경을 만들고, `whisper_wave.py <길이>`로 만든 투명 PNG 시퀀스를 overlay해요.
3. 앞부분(0~V) + 삽입 + 뒷부분(V2~, `fade=t=in:d=0.4`)을 concat. 내레이션도 0~P + 속삭임 wav + P~를 concat.

## 음악 덕킹 믹스

```bash
ffmpeg -i silent.mp4 -i narr.wav -i music.mp3 -filter_complex "[1:a]highpass=f=80,acompressor=threshold=-20dB:ratio=3:attack=5:release=80,volume=1.4,apad=whole_dur=$T[vo];[vo]asplit=2[vo1][vosc];[2:a]atrim=0:$T,asetpts=N/SR/TB,aformat=sample_rates=48000:channel_layouts=stereo,loudnorm=I=-20:TP=-2,volume=0.55,afade=t=in:st=0:d=0.5,afade=t=out:st=$FO:d=3.5[m];[m][vosc]sidechaincompress=threshold=0.02:ratio=6:attack=20:release=400[md];[vo1][md]amix=inputs=2:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11[a]" -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -movflags +faststart final.mp4
ffmpeg -i final.mp4 -vf scale=960:-2 -c:v libx264 -crf 25 -preset slow -c:a aac -b:a 128k -movflags +faststart final_폰용.mp4
```

`$T`는 영상 길이, `$FO`는 `$T-3.5`.

## 카운트업 (GSAP)

```js
const cnt = { n: 2 };
const draw = () => { const n = Math.round(cnt.n); /* 십의 자리·일의 자리 요소 textContent 갱신 */ };
tl.fromTo(cnt, { n: 2 }, { n: 20, duration: 0.75, ease: 'power1.in', onUpdate: draw, immediateRender: false }, T);
```

렌더러가 아무 시점으로 점프해도 맞게 `fromTo` + `immediateRender: false`로 써요.

## 받아쓰기 검수

```bash
ffmpeg -ss 76 -t 12 -i final_폰용.mp4 -ar 16000 -ac 1 e.wav
whisper-cli -m ~/.cc-promo-video/models/ggml-large-v3-turbo-q5_0.bin -l ko -mc 0 -f e.wav
```
