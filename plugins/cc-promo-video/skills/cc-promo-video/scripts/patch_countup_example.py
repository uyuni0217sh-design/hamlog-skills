# 뉴욕 영상 index.html의 2 -> 20 장면을 카운트업 + 0 사라짐으로 바꾼 패치(예시).
# 새 영상에서는 old_a/new_a의 선택자와 시간을 해당 장면에 맞춰 바꿔요.
p = "dark/index.html"
t = open(p).read()
old_a = """tl.to('#two .digit', { scale: 0.92, duration: 0.12, yoyo: true, repeat: 1, ease: 'power2.out' }, 67.15);
tl.fromTo('#zero', { opacity: 0, scale: 1.5, y: -50 }, { opacity: 1, scale: 1, y: 0, duration: 0.4, ease: 'back.out(2)' }, 67.2);
tl.fromTo('#lab2', { opacity: 0, x: -30 }, { opacity: 1, x: 0, duration: 0.4, ease: 'expo.out' }, 67.4);
tl.to(['#lab2', '#zero'], { opacity: 0, duration: 0.25 }, 69);"""
assert t.count(old_a) == 1, "anchor missing"
new_a = """// 2 -> 20 count-up
{ const dg = document.querySelector('#two .digit'), zr = document.querySelector('#zero'); const cnt = { n: 2 };
  const draw = () => { const n = Math.round(cnt.n); if (n < 10) { dg.textContent = String(n); zr.style.opacity = 0; } else { dg.textContent = String(Math.floor(n / 10)); zr.textContent = String(n % 10); zr.style.opacity = 1; } };
  tl.fromTo(cnt, { n: 2 }, { n: 20, duration: 0.75, ease: 'power1.in', onUpdate: draw, immediateRender: false }, 66.95); }
tl.fromTo(['#two .digit', '#zero'], { scale: 1 }, { scale: 1.08, duration: 0.1, yoyo: true, repeat: 1, ease: 'power2.out', immediateRender: false }, 67.7);
tl.fromTo('#lab2', { opacity: 0, x: -30 }, { opacity: 1, x: 0, duration: 0.4, ease: 'expo.out' }, 67.6);
tl.to('#lab2', { opacity: 0, duration: 0.25 }, 69);
// the 0 slides away softly
tl.fromTo('#zero', { x: 0, filter: 'blur(0px)' }, { opacity: 0, x: 60, filter: 'blur(14px)', duration: 0.7, ease: 'power2.inOut', immediateRender: false }, 68.85);"""
t = t.replace(old_a, new_a, 1)
open(p, "w").write(t)
print("ok")
