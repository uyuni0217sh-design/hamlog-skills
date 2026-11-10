#!/bin/bash
# 뉴욕 영상 v25를 조립한 실제 스크립트예요(예시). 새 영상에서는 파일명과 시간값(ID, C, V, V2, P, D)을 바꿔 써요.
# 필요한 파일: silent 렌더본, intro_v.mp4, introsub.png, shk/ 물결 자막 PNG, narr*.wav(본편 내레이션), wh.wav(속삭임), 음악 mp3
set -e
# 예시 기록이에요. 파일 이름·시점은 뉴욕 영상 기준이니 그대로 돌리지 말고 흐름만 참고해요.
cd "${1:-.}"
SRC=dark_silent25.mp4
ID=9.042; X=0.7; C=3.34
OFF=$(python3 -c "print($ID-$X)")
# 1) intro + 0.7s dissolve into main (main starts at 3.34s)
ffmpeg -v error -y -ss $C -i $SRC -an -c:v libx264 -crf 17 -preset fast r25.mp4
ffmpeg -v error -y -i intro_v.mp4 -i r25.mp4 -filter_complex "[0:v]settb=1/30,setpts=PTS-STARTPTS[a];[1:v]settb=1/30,setpts=PTS-STARTPTS[b];[a][b]xfade=transition=fade:duration=$X:offset=$OFF,format=yuv420p[v]" -map "[v]" -c:v libx264 -crf 17 -preset medium s25b.mp4
# 2) intro subtitle
ffmpeg -v error -y -i s25b.mp4 -loop 1 -t 9 -i introsub.png -filter_complex "[1:v]format=rgba,fade=t=in:st=2.85:d=0.15:alpha=1,fade=t=out:st=8.5:d=0.25:alpha=1[s];[0:v][s]overlay=0:0:eof_action=pass,format=yuv420p[v]" -map "[v]" -c:v libx264 -crf 17 -preset medium s25c.mp4
echo step12
# 3) whisper insert: video split V (clean s9 frame), resume at V2 (clean s10 frame); audio split P
V=60.76; V2=61.0; P=60.972; D=6.3
L=$(python3 -c "print(round($D+$V2-$V,3))")
ffmpeg -v error -y -ss 60.72 -i s25c.mp4 -frames:v 1 frz25.png
ffmpeg -v error -y -loop 1 -t $L -framerate 30 -i frz25.png -framerate 30 -i shk/s_%03d.png -filter_complex "[0:v]format=yuv420p,fade=t=out:st=0:d=0.5[bg];[bg][1:v]overlay=0:0:eof_action=pass,format=yuv420p[v]" -map "[v]" -t $L -r 30 -c:v libx264 -crf 17 -preset medium ins25.mp4
ffmpeg -v error -y -i s25c.mp4 -t $V -c:v libx264 -crf 17 -preset medium -r 30 pA25.mp4
ffmpeg -v error -y -ss $V2 -i s25c.mp4 -vf fade=t=in:st=0:d=0.4 -c:v libx264 -crf 17 -preset medium -r 30 pB25.mp4
printf "file pA25.mp4\nfile ins25.mp4\nfile pB25.mp4\n" > cat25.txt
ffmpeg -v error -y -f concat -safe 0 -i cat25.txt -c copy silent25.mp4
ffmpeg -v error -y -i narr21b.wav -t $P -af aformat=sample_rates=48000:channel_layouts=stereo na25.wav
ffmpeg -v error -y -ss $P -i narr21b.wav -af aformat=sample_rates=48000:channel_layouts=stereo nb25.wav
ffmpeg -v error -y -i na25.wav -i wh.wav -i nb25.wav -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1" narr25.wav
echo step3
# 4) mix
T=$(ffprobe -v error -show_entries format=duration -of csv=p=0 silent25.mp4); echo T=$T
FO=$(python3 -c "print($T-3.5)")
ffmpeg -v error -y -i silent25.mp4 -i narr25.wav -i music.mp3 -filter_complex "[1:a]highpass=f=80,acompressor=threshold=-20dB:ratio=3:attack=5:release=80,volume=1.4,apad=whole_dur=$T[vo];[vo]asplit=2[vo1][vosc];[2:a]atrim=0:$T,asetpts=N/SR/TB,aformat=sample_rates=48000:channel_layouts=stereo,loudnorm=I=-20:TP=-2,volume=0.55,afade=t=in:st=0:d=0.5,afade=t=out:st=$FO:d=3.5[m];[m][vosc]sidechaincompress=threshold=0.02:ratio=6:attack=20:release=400[md];[vo1][md]amix=inputs=2:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11[a]" -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -t $T -movflags +faststart 뉴욕워크숍_소개_v25.mp4
ffmpeg -v error -y -i 뉴욕워크숍_소개_v25.mp4 -vf scale=960:-2 -c:v libx264 -crf 25 -preset slow -c:a aac -b:a 128k -movflags +faststart 뉴욕워크숍_소개_v25_폰용.mp4
# checks: whisper insert + return, and counter section
ffmpeg -v error -y -ss 60.0 -t 8.4 -i 뉴욕워크숍_소개_v25.mp4 -vf fps=2,scale=240:-1,tile=17x1 -frames:v 1 chk25_ins.jpg
ffmpeg -v error -y -ss 66.7 -t 0.8 -i 뉴욕워크숍_소개_v25.mp4 -vf fps=10,scale=240:-1,tile=8x1 -frames:v 1 chk25_ret.jpg
ls -la *v25*
echo BUILDDONE
