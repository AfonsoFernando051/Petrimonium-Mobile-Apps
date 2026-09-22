"""Uso: python3 tools/rive_pet/preview.py [arquivo.riv]

Renderiza os quadros gravados pelo harness C++ (runtime oficial) em GIFs e folha de contato."""
import json, subprocess, sys, os, numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import build_wolf as B

HARNESS = os.environ.get('RIVE_HARNESS', os.path.join(B.ROOT, 'build/rive_pet/harness'))
RIV = sys.argv[1] if len(sys.argv) > 1 else B.OUT
OUTD = os.path.join(B.ROOT, 'build/rive_pet/preview'); os.makedirs(OUTD, exist_ok=True)
IMGS = [Image.open(f"{B.LAYERS}/{B.L[n]['file']}").convert('RGBA') for n, _ in B.IMAGES]
W, H = B.M['artboard']
BG = (30, 32, 38, 255)

def run(cmds):
    p = subprocess.run([HARNESS, RIV], input='\n'.join(cmds) + '\n', capture_output=True, text=True, timeout=120)
    lines = [json.loads(l) for l in p.stdout.splitlines() if l.strip()]
    if p.returncode: raise SystemExit(p.stdout + p.stderr)
    return lines

def render(draws, scale=0.5):
    canvas = Image.new('RGBA', (int(W * scale), int(H * scale)), BG)
    for d in draws:
        i, a, b, c, dd, tx, ty, op = d
        if op <= 0.003: continue
        # matriz do runtime: x' = a*x + c*y + tx ; y' = b*x + dd*y + ty  (depois escala de preview)
        A = np.array([[a, c, tx], [b, dd, ty], [0, 0, 1]]) 
        S = np.diag([scale, scale, 1]); inv = np.linalg.inv(S @ A)
        img = IMGS[i]
        layer = img.transform(canvas.size, Image.AFFINE, tuple(inv[:2].flatten()), resample=Image.BICUBIC)
        if op < 1:
            al = np.array(layer); al[..., 3] = (al[..., 3] * op).astype(np.uint8); layer = Image.fromarray(al)
        canvas.alpha_composite(layer)
    return canvas

if __name__ == '__main__':
    info = run([])
    print(info[0]); print(info[1])
    STEP = 1 / 20
    sheet_cols = []
    for i, a in enumerate(B.anims):
        dur = a.frames / 60
        cmds = ['num state 0', 'adv 0.5', f'num state {i}', 'adv 0.4']
        n = int(dur / STEP) + 1
        for k in range(n): cmds += [f'dump f{k}', f'adv {STEP}']
        frames = [render(l['draws']) for l in run(cmds)[2:]]
        frames[0].save(f'{OUTD}/{a.name}.gif', save_all=True, append_images=frames[1:], duration=int(STEP * 1000), loop=0, disposal=2)
        picks = [frames[int(t * (len(frames) - 1))] for t in (0, 0.25, 0.5, 0.75)]
        sheet_cols.append((a.name, picks))
    # reduzir movimento: pose estática por estado + interação
    statics = []
    for i, a in enumerate(B.anims):
        l = run(['bool reducedMotion 1', f'num state {i}', 'adv 0.5', 'adv 0.5', 'dump s', 'adv 1.0', 'adv 0.7', 'dump s2'])
        s1, s2 = l[2]['draws'], l[3]['draws']
        moving = max(abs(x - y) for d1, d2 in zip(s1, s2) for x, y in zip(d1, d2))
        statics.append((a.name, render(s1), moving))
    l = run(['bool interacting 1', 'adv 0.4', 'dump a', 'adv 0.75', 'dump b'])
    med = B.IMAGES.index(('medallion', 'body'))
    ms = [next(d for d in x['draws'] if d[0] == med) for x in l[2:]]
    # folha de contato
    tw, th = int(W * 0.5), int(H * 0.5)
    sheet = Image.new('RGB', (tw * 5, (th + 18) * (len(sheet_cols) + 1)), (15, 15, 18))
    dr = ImageDraw.Draw(sheet)
    for r, (name, picks) in enumerate(sheet_cols):
        dr.text((4, r * (th + 18) + 3), f'state {r}: {name}  (quadros 0 / 25 / 50 / 75%)', fill=(255, 220, 90))
        for c, im in enumerate(picks): sheet.paste(im.convert('RGB'), (c * tw, r * (th + 18) + 18))
    r = len(sheet_cols)
    dr.text((4, r * (th + 18) + 3), 'reducedMotion=true (poses estáticas)', fill=(120, 220, 255))
    for c, (name, im, mv) in enumerate(statics[:5]):
        sheet.paste(im.convert('RGB'), (c * tw, r * (th + 18) + 18))
    sheet.save(f'{OUTD}/contact_sheet.png')
    print('static movement per state (deve ser ~0):', [(n, round(m, 4)) for n, _, m in statics])
    print('medalhão com interacting=true (escala, opacidade):', [(round(m[1], 3), round(m[7], 3)) for m in ms])
    print('draw order (trás -> frente):', [B.IMAGES[d[0]][0] for d in run(['dump o'])[2]['draws']])
