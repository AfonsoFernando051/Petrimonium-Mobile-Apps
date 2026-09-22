"""Uso: python3 tools/rive_pet/slice_wolf.py

Fatia generated_wolf.png em camadas para o rig Companion do Rive.
Coordenadas definidas no espaço da imagem original (331x434); saída escalada
para caber no artboard 500x686 do DogCompanion."""
import json, os, cv2, numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
# Os assets vivem dentro do app, nao na raiz do workspace Melos: WOLF_APP
# permite gerar para outro app (ex.: apps/wallet) sem editar o script.
APP = os.environ.get('WOLF_APP', os.path.join(ROOT, 'apps/academy'))
SRC = os.path.join(APP, 'assets/images/generated_wolf.png')
OUT = os.environ.get('WOLF_LAYERS', os.path.join(ROOT, 'build/rive_pet/wolf_layers'))
os.makedirs(OUT, exist_ok=True)
S = 1.5                      # escala original -> artboard
ART_W, ART_H = 500, 686
OFF = (2, 30)                # deslocamento do lobo dentro do artboard
FEATHER = 1.2

src = Image.open(SRC).convert('RGBA')
W, H = int(src.width * S), int(src.height * S)
img = src.resize((W, H), Image.LANCZOS)
rgba = np.array(img)

def P(pts): return [(x * S, y * S) for x, y in pts]

def poly_mask(pts):
    m = Image.new('L', (W, H), 0); ImageDraw.Draw(m).polygon(P(pts), fill=255); return m

def ellipse_mask(cx, cy, rx, ry):
    m = Image.new('L', (W, H), 0)
    ImageDraw.Draw(m).ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], fill=255)
    return m

def feather(m, r=FEATHER): return m.filter(ImageFilter.GaussianBlur(r))

def dark_mask(box, thr=95):
    """Alpha suave para traços escuros (sobrancelhas) dentro de uma caixa."""
    x0, y0, x1, y1 = [int(v * S) for v in box]
    lum = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2GRAY).astype(np.float32)
    a = np.clip((thr + 30 - lum) / 60.0, 0, 1)
    out = np.zeros((H, W), np.float32); out[y0:y1, x0:x1] = a[y0:y1, x0:x1]
    return Image.fromarray((out * 255).astype(np.uint8))

def inpaint(base_rgba, hole_mask, radius=6):
    """Preenche regiões que ficam atrás de peças móveis para não abrir buracos."""
    rgb = cv2.cvtColor(base_rgba[..., :3], cv2.COLOR_RGB2BGR)
    hole = cv2.dilate(np.array(hole_mask), np.ones((5, 5), np.uint8))
    hole = (hole > 20).astype(np.uint8) * 255
    fixed = cv2.cvtColor(cv2.inpaint(rgb, hole, radius, cv2.INPAINT_TELEA), cv2.COLOR_BGR2RGB)
    out = base_rgba.copy(); out[..., :3] = fixed
    return out

def harmonic_fill(base_rgba, hole, iters=1500):
    """Preenche `hole` resolvendo Laplace (sombreado liso, sem estrias do TELEA) + leve textura."""
    h = cv2.dilate(((np.array(hole) > 20) * 255).astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
    rgb = cv2.cvtColor(base_rgba[..., :3], cv2.COLOR_RGB2BGR)
    init = cv2.inpaint(rgb, h.astype(np.uint8) * 255, 5, cv2.INPAINT_TELEA).astype(np.float32)
    known = init.copy(); m3 = np.repeat(h[..., None], 3, 2)
    cur = init
    for _ in range(iters):
        cur = np.where(m3, cv2.blur(cur, (3, 3)), known)
    noise = cv2.GaussianBlur(rng0.normal(0, 3.0, cur.shape).astype(np.float32), (0, 0), 0.8)
    cur = np.where(m3, cur + noise, cur)
    out = base_rgba.copy(); out[..., :3] = cv2.cvtColor(np.clip(cur, 0, 255).astype(np.uint8), cv2.COLOR_BGR2RGB)
    return out
rng0 = np.random.default_rng(3)

def eye_hole(e):
    """Elipse do olho + delineado/‘flick’ escuro ao redor (senão sobra um anel preto)."""
    cx, cy, rx, ry = e
    lum = cv2.cvtColor(rgba[..., :3], cv2.COLOR_RGB2GRAY)
    near = np.array(ellipse_mask(cx, cy, rx + 16, ry + 10)) > 0
    dark = (lum < 150) & near
    m = (np.array(ellipse_mask(cx, cy, rx + 3, ry + 3)) > 0) | dark
    m = cv2.dilate(m.astype(np.uint8) * 255, np.ones((7, 7), np.uint8))
    return Image.fromarray(m)

def cut(arr, mask):
    m = np.array(mask).astype(np.float32) / 255.0
    out = arr.copy(); out[..., 3] = (arr[..., 3].astype(np.float32) * m).astype(np.uint8)
    return out

# ---------------- regiões (espaço 331x434) ----------------
HEAD = [(55,200),(62,165),(75,148),(78,120),(90,104),(110,88),(140,68),(165,50),(185,55),(205,66),
        (235,80),(255,92),(275,108),(282,140),(292,160),(302,182),(306,205),(296,222),(280,236),
        (262,250),(240,262),(200,269),(160,267),(125,259),(100,246),(80,229),(60,215)]
EAR_L = [(70,125),(64,75),(74,40),(95,12),(112,18),(136,50),(152,74),(122,102),(96,122)]
EAR_R = [(222,80),(250,44),(284,16),(297,30),(300,70),(294,112),(270,120),(242,100)]
TORSO = [(105,255),(245,255),(247,300),(257,322),(272,350),(300,362),(318,390),(324,434),
         (86,434),(86,400),(95,370),(100,345),(106,320),(112,298)]
TAIL = [(12,385),(18,352),(34,340),(56,336),(66,346),(84,352),(102,362),(112,382),(116,410),
        (108,434),(38,434),(16,420)]
LEG_L = [(96,350),(146,345),(152,400),(142,434),(86,434),(88,400)]
LEG_R = [(214,345),(260,345),(276,380),(292,434),(234,434),(214,400)]
HAUNCH = [(255,348),(302,360),(322,390),(326,434),(272,434),(262,390)]
COLLAR = [(111,262),(124,256),(136,266),(224,266),(234,256),(242,262),(242,296),(222,301),
          (198,294),(174,294),(150,298),(118,292),(111,280)]
MEDAL = [(197,282),(225,310),(197,340),(168,310)]
EYE_L = (139, 182, 32, 32)
EYE_R = (250, 184, 31, 30)
MUZZLE = (198, 227, 41, 24)
BROW_L = (114, 116, 172, 142)
BROW_R = (228, 118, 276, 144)

layers = {}

# olhos, sobrancelhas, focinho (recortes diretos)
m_eye_l = feather(ellipse_mask(*EYE_L)); m_eye_r = feather(ellipse_mask(*EYE_R))
m_mz = feather(ellipse_mask(*MUZZLE), 2.0)
m_bl = dark_mask(BROW_L); m_br = dark_mask(BROW_R)
layers['eye_left'] = cut(rgba, m_eye_l)
layers['eye_right'] = cut(rgba, m_eye_r)
layers['muzzle'] = cut(rgba, m_mz)
layers['eyebrow_left'] = cut(rgba, m_bl)
layers['eyebrow_right'] = cut(rgba, m_br)

# cabeça: preenche buracos sob olhos/sobrancelhas/focinho
holes = Image.fromarray(np.maximum.reduce([np.array(eye_hole(EYE_L)), np.array(eye_hole(EYE_R)),
                                           np.array(m_bl), np.array(m_br)]))
head_base = harmonic_fill(rgba, holes)
head_base = inpaint(head_base, ellipse_mask(MUZZLE[0], MUZZLE[1], MUZZLE[2]-6, MUZZLE[3]-6), 7)
layers['head'] = cut(head_base, feather(poly_mask(HEAD)))

# orelhas (a base fica escondida atrás da cabeça)
layers['ear_left'] = cut(rgba, feather(poly_mask(EAR_L)))
layers['ear_right'] = cut(rgba, feather(poly_mask(EAR_R)))

# tronco: preenche a faixa coberta pela cabeça para a inclinação não revelar vazio
torso_base = inpaint(rgba, Image.fromarray(np.array(poly_mask(HEAD)) & np.array(poly_mask([(100,240),(250,240),(250,262),(100,262)]))), 8)
tm = np.array(poly_mask(TORSO)) & ~np.array(poly_mask(TAIL))
layers['torso'] = cut(torso_base, feather(Image.fromarray(tm)))
layers['tail'] = cut(rgba, feather(poly_mask(TAIL)))
layers['front_leg_left'] = cut(rgba, feather(poly_mask(LEG_L)))
layers['front_leg_right'] = cut(rgba, feather(poly_mask(LEG_R)))
layers['rear_haunch'] = cut(rgba, feather(poly_mask(HAUNCH)))
layers['collar'] = cut(rgba, feather(poly_mask(COLLAR)))
layers['medallion'] = cut(rgba, feather(poly_mask(MEDAL), 1.5))

# boca aberta: focinho + boca pintada
mo = Image.fromarray(layers['muzzle']); d = ImageDraw.Draw(mo)
cx, cy = 200 * S, 240 * S
d.ellipse([cx - 11*S, cy - 5*S, cx + 11*S, cy + 9*S], fill=(70, 22, 38, 255))
d.ellipse([cx - 7*S, cy + 2*S, cx + 7*S, cy + 9*S], fill=(236, 120, 150, 255))
layers['mouth_open'] = np.array(mo)

# olhos fechados — pálpebra lisa (gradiente com a cor do pelo em volta) + arco de cílios.
# (inpaint puro deixa uma mancha borrada visível; o gradiente fica mais limpo)
rng = np.random.default_rng(7)
def lid_patch(cx, cy, rx, ry):
    X0, X1 = int((cx - rx - 8) * S), int((cx + rx + 8) * S)
    Y0, Y1 = int((cy - ry - 8) * S), int((cy + ry + 8) * S)
    def samp(x, y, r=3):
        x, y = int(x * S), int(y * S)
        return head_base[y - r:y + r, x - r:x + r, :3].reshape(-1, 3).mean(0)
    top, bot = samp(cx, cy - ry - 7), samp(cx, cy + ry + 7)
    lef, rig = samp(cx - rx - 7, cy), samp(cx + rx + 7, cy)
    arr = np.zeros((H, W, 4), np.uint8)
    ys, xs = np.mgrid[Y0:Y1, X0:X1]
    ty = ((ys - Y0) / max(1, Y1 - Y0))[..., None]; tx = ((xs - X0) / max(1, X1 - X0))[..., None]
    col = 0.55 * (top * (1 - ty) + bot * ty) + 0.45 * (lef * (1 - tx) + rig * tx)
    col = col + rng.normal(0, 2.5, col.shape)
    arr[Y0:Y1, X0:X1, :3] = np.clip(col, 0, 255).astype(np.uint8)
    m = np.array(feather(ellipse_mask(cx, cy, rx + 5, ry + 5), 4)).astype(np.float32) / 255
    arr[..., 3] = (m * 255).astype(np.uint8)
    return Image.fromarray(arr)

def closed_eye(cx, cy, rx, ry, flip=False, happy=False):
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    ink = (34, 32, 48, 255)
    if happy:   # arco para cima (^), olhos sorrindo
        box = [(cx - rx*0.7)*S, (cy - rx*0.25)*S, (cx + rx*0.7)*S, (cy + rx*0.75)*S]
        d.arc(box, 200, 340, fill=ink, width=int(4.6*S))
    else:       # arco para baixo (pálpebra fechada) com cílio
        box = [(cx - rx*0.8)*S, (cy - rx*0.55)*S, (cx + rx*0.8)*S, (cy + rx*0.4)*S]
        d.arc(box, 20, 160, fill=ink, width=int(4.4*S))
        lash_x = cx + (rx*0.78 if flip else -rx*0.78)
        d.line([(lash_x*S, (cy+1)*S), ((lash_x + (6 if flip else -6))*S, (cy-4)*S)], fill=ink, width=int(3.0*S))
    return np.array(im.filter(ImageFilter.GaussianBlur(0.5)))
layers['eye_left_closed'] = closed_eye(EYE_L[0], EYE_L[1] + 1, EYE_L[2], EYE_L[3])
layers['eye_right_closed'] = closed_eye(EYE_R[0], EYE_R[1] + 1, EYE_R[2], EYE_R[3], flip=True)
layers['eye_left_happy'] = closed_eye(EYE_L[0], EYE_L[1] + 1, EYE_L[2], EYE_L[3], happy=True)
layers['eye_right_happy'] = closed_eye(EYE_R[0], EYE_R[1] + 1, EYE_R[2], EYE_R[3], flip=True, happy=True)

# sombra no chão
sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(sh).ellipse([70*S, 418*S, 300*S, 446*S], fill=(0, 0, 0, 110))
layers['ground_shadow'] = np.array(sh.filter(ImageFilter.GaussianBlur(6)))

# pivôs sugeridos (espaço original) para rotação no Rive
PIVOTS = {'head': (190, 262), 'ear_left': (118, 100), 'ear_right': (248, 100), 'tail': (104, 418),
          'eye_left': EYE_L[:2], 'eye_right': EYE_R[:2], 'muzzle': (198, 222), 'mouth_open': (198, 222),
          'eyebrow_left': (143, 129), 'eyebrow_right': (252, 131), 'torso': (190, 430),
          'front_leg_left': (120, 350), 'front_leg_right': (238, 350), 'rear_haunch': (290, 430),
          'collar': (177, 280), 'medallion': (197, 311), 'eye_left_closed': EYE_L[:2],
          'eye_right_closed': EYE_R[:2], 'eye_left_happy': EYE_L[:2], 'eye_right_happy': EYE_R[:2], 'ground_shadow': (185, 432)}

# ordem de desenho (de trás para frente), igual à hierarquia do DogCompanion invertida
ORDER = ['ground_shadow', 'tail', 'rear_haunch', 'torso', 'front_leg_right', 'front_leg_left', 'collar',
         'medallion', 'ear_right', 'ear_left', 'head', 'muzzle', 'mouth_open', 'eye_right', 'eye_left',
         'eye_right_closed', 'eye_left_closed', 'eye_right_happy', 'eye_left_happy', 'eyebrow_right', 'eyebrow_left']

manifest = {'source': 'apps/academy/assets/images/generated_wolf.png', 'artboard': [ART_W, ART_H], 'scale': S,
            'offset': OFF, 'draw_order_back_to_front': ORDER,
            'hidden_by_default': ['mouth_open', 'eye_left_closed', 'eye_right_closed', 'eye_left_happy', 'eye_right_happy'], 'layers': {}}
for name in ORDER:
    arr = layers[name]
    a = arr[..., 3]; ys, xs = np.where(a > 4)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    Image.fromarray(arr[y0:y1, x0:x1]).save(f'{OUT}/wolf_{name}.png', optimize=True)
    px, py = PIVOTS[name]
    manifest['layers'][name] = {
        'file': f'wolf_{name}.png', 'size': [int(x1 - x0), int(y1 - y0)],
        'top_left': [int(x0 + OFF[0]), int(y0 + OFF[1])],
        'center': [round((x0 + x1) / 2 + OFF[0], 1), round((y0 + y1) / 2 + OFF[1], 1)],
        'pivot': [round(px * S + OFF[0], 1), round(py * S + OFF[1], 1)]}
json.dump(manifest, open(f'{OUT}/wolf_layers.json', 'w'), indent=2)

# verificação: remonta as camadas visíveis
comp = Image.new('RGBA', (ART_W, ART_H), (38, 38, 42, 255))
for name in ORDER:
    if name in manifest['hidden_by_default']: continue
    L = manifest['layers'][name]; comp.alpha_composite(Image.open(f'{OUT}/{L["file"]}'), tuple(L['top_left']))
comp.save(os.path.join(os.path.dirname(OUT), 'recomposed.png'))
print('ok', len(ORDER), 'layers')
