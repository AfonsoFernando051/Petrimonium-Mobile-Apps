"""Uso: python3 tools/rive_pet/build_wolf.py  (depois de slice_wolf.py)

Gera wolf.riv (contrato Companion) a partir das camadas fatiadas.

Estrutura:
  Artboard "Wolf" 500x686, state machine "Companion" (default)
  Inputs: state (number, índice de PetAnimationState), reducedMotion (bool), interacting (bool)
  PetAnimationState (Academy e Wallet): 0 idle, 1 celebrate, 2 think, 3 sleep, 4 victory, 5 happy
  Layer "Mood": Any -> <anim> se state==i && !reducedMotion ; Any -> <anim>_static se state==i && reducedMotion
  Layer "Interaction": brilho do medalhão enquanto a folha de interação está aberta (sem reduceMotion)
Toda animação chaveia TODAS as propriedades animadas (pose completa), porque o runtime
legado (rive 0.13) não reseta propriedades que uma animação não chaveia.
"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from riv import Writer

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
LAYERS = os.environ.get('WOLF_LAYERS', os.path.join(ROOT, 'build/rive_pet/wolf_layers'))
OUT = os.environ.get('WOLF_OUT', os.path.join(ROOT, 'assets/rive/pet/wolf.riv'))
M = json.load(open(f'{LAYERS}/wolf_layers.json'))
L = M['layers']
FPS = 60

# ---------------- rig (coordenadas absolutas no artboard) ----------------
BODY = (287.0, 675.0)                     # pivô do corpo (respiração / pulo)
HEAD = tuple(L['head']['pivot'])          # base do pescoço
TAIL = tuple(L['tail']['pivot'])
EAR_L = tuple(L['ear_left']['pivot'])
EAR_R = tuple(L['ear_right']['pivot'])

# nós: nome -> (pai, posição absoluta)
NODES = {
    'body':      ('artboard', BODY),
    'tail_root': ('body', TAIL),
    'head_root': ('body', HEAD),
    'ear_left_root':  ('head_root', EAR_L),
    'ear_right_root': ('head_root', EAR_R),
}
# imagens em ordem da FRENTE para TRÁS (o runtime desenha o último do arquivo primeiro)
IMAGES = [
    ('eyebrow_left', 'head_root'), ('eyebrow_right', 'head_root'),
    ('eye_left_happy', 'head_root'), ('eye_right_happy', 'head_root'),
    ('eye_left_closed', 'head_root'), ('eye_right_closed', 'head_root'),
    ('eye_left', 'head_root'), ('eye_right', 'head_root'),
    ('mouth_open', 'head_root'), ('muzzle', 'head_root'), ('head', 'head_root'),
    ('ear_left', 'ear_left_root'), ('ear_right', 'ear_right_root'),
    ('medallion', 'body'), ('collar', 'body'),
    ('front_leg_left', 'body'), ('front_leg_right', 'body'),
    ('torso', 'body'), ('rear_haunch', 'body'), ('tail', 'tail_root'),
    ('ground_shadow', 'artboard'),
]
HIDDEN = set(M['hidden_by_default'])

def abs_pos(name):
    return NODES[name][1] if name in NODES else tuple(L[name]['center'])
def parent_of(name):
    return NODES[name][0] if name in NODES else dict(IMAGES)[name]
def local_pos(name):
    x, y = abs_pos(name); p = parent_of(name)
    if p == 'artboard': return x, y
    px, py = abs_pos(p); return x - px, y - py

# ---------------- propriedades animadas e pose base ----------------
PROPS = {'x': 'x', 'y': 'y', 'rot': 'rotation', 'sx': 'scaleX', 'sy': 'scaleY', 'op': 'opacity'}
CHANNELS = [
    ('body', 'y'), ('body', 'sx'), ('body', 'sy'),
    ('head_root', 'rot'), ('head_root', 'y'),
    ('ear_left_root', 'rot'), ('ear_right_root', 'rot'),
    ('tail_root', 'rot'),
    ('eye_left', 'sy'), ('eye_right', 'sy'), ('eye_left', 'op'), ('eye_right', 'op'),
    ('eye_left_closed', 'op'), ('eye_right_closed', 'op'),
    ('eye_left_happy', 'op'), ('eye_right_happy', 'op'),
    ('mouth_open', 'op'), ('muzzle', 'op'),
    ('eyebrow_left', 'y'), ('eyebrow_right', 'y'),
    ('ground_shadow', 'sx'), ('ground_shadow', 'op'),
]
def base(node, ch):
    if ch in ('x', 'y'): return local_pos(node)[0 if ch == 'x' else 1]
    if ch == 'rot': return 0.0
    if ch in ('sx', 'sy'): return 1.0
    if ch == 'op': return 0.0 if node in HIDDEN else 1.0

def ease(t): return 0.5 - 0.5 * math.cos(math.pi * t)       # ease-in-out
deg = math.radians

class Anim:
    """Animação = pose base + deslocamentos; cada canal é uma lista de (frame, valor, curva)."""
    def __init__(s, name, frames, loop=True):
        s.name, s.frames, s.loop, s.tracks = name, frames, loop, {}
    def key(s, node, ch, pts, rel=True, curve='ease'):
        b = base(node, ch) if rel else 0.0
        s.tracks[(node, ch)] = [(f, b + v, curve) for f, v in pts]
        return s
    def keys(s):
        out = {}
        for node, ch in CHANNELS:
            pts = s.tracks.get((node, ch), [(0, base(node, ch), 'hold')])
            out[(node, ch)] = bake(pts, s.frames)
        return out
    def value_at(s, node, ch, f):
        return sample(s.tracks.get((node, ch), [(0, base(node, ch), 'hold')]), f)

def sample(pts, f):
    if f <= pts[0][0]: return pts[0][1]
    for (f0, v0, _), (f1, v1, c) in zip(pts, pts[1:]):
        if f0 <= f <= f1:
            t = 0 if f1 == f0 else (f - f0) / (f1 - f0)
            if c == 'hold': t = 0.0 if f < f1 else 1.0
            elif c == 'ease': t = ease(t)
            return v0 + (v1 - v0) * t
    return pts[-1][1]

def bake(pts, frames, step=3):
    """Converte curvas em keyframes lineares a cada `step` frames (o runtime interpola linear)."""
    if len(pts) == 1: return [(0, pts[0][1]), (frames, pts[0][1])]
    fs = set(range(0, frames + 1, step)) | {p[0] for p in pts} | {frames}
    # frames de 'hold' precisam de chave imediatamente antes da troca
    for (f0, _, _), (f1, _, c) in zip(pts, pts[1:]):
        if c == 'hold' and f1 - 1 > f0: fs.add(f1 - 1)
    out = [(f, sample(pts, f)) for f in sorted(fs) if 0 <= f <= frames]
    # remove chaves redundantes (colineares)
    slim = [out[0]]
    for i in range(1, len(out) - 1):
        (fa, va), (fb, vb), (fc, vc) = slim[-1], out[i], out[i + 1]
        if abs((vb - va) - (vc - va) * (fb - fa) / (fc - fa)) > 1e-4: slim.append(out[i])
    slim.append(out[-1])
    return slim

def blink(a, at, both=True):
    """Piscar rápido (squash do olho + troca para olho fechado) começando no frame `at`."""
    for side in ('left', 'right'):
        a.key(f'eye_{side}', 'sy', [(0, 0), (at, 0), (at + 3, -0.85), (at + 6, -0.85), (at + 9, 0), (a.frames, 0)])
        a.key(f'eye_{side}', 'op', [(0, 0), (at + 2, 0), (at + 3, -1), (at + 6, -1), (at + 7, 0), (a.frames, 0)], curve='linear')
        a.key(f'eye_{side}_closed', 'op', [(0, 0), (at + 2, 0), (at + 3, 1), (at + 6, 1), (at + 7, 0), (a.frames, 0)], curve='linear')
    return a

def wave(n, period, amp, phase=0.0, step=None):
    """Senoide amostrada — retorna [(frame, valor)] fechando o loop em n frames."""
    step = step or max(2, period // 8)
    return [(f, amp * math.sin(2 * math.pi * (f / period) + phase)) for f in range(0, n + 1, step)] + \
           ([(n, amp * math.sin(2 * math.pi * (n / period) + phase))] if n % step else [])

def smile_eyes(a):
    for side in ('left', 'right'):
        a.key(f'eye_{side}', 'op', [(0, -1)]); a.key(f'eye_{side}_happy', 'op', [(0, 1)])
    return a
def open_mouth(a):
    a.key('mouth_open', 'op', [(0, 1)]); a.key('muzzle', 'op', [(0, -1)]); return a

# ---------------- animações ----------------
anims = []

# 0 idle — presença neutra: respiração, cauda lenta, piscar, orelha.
a = Anim('idle', 240)
a.key('body', 'sy', [(0, 0), (60, 0.012), (120, 0), (180, 0.012), (240, 0)])
a.key('head_root', 'rot', [(0, 0), (120, deg(1.2)), (240, 0)])
a.key('tail_root', 'rot', [(0, 0), (60, deg(4)), (120, 0), (180, deg(-3)), (240, 0)])
a.key('ear_right_root', 'rot', [(0, 0), (150, 0), (155, deg(7)), (160, 0), (165, deg(4)), (170, 0), (240, 0)])
blink(a, 196)
anims.append(a)

# 1 celebrate — progresso educacional: orelhas abertas, aceno de cabeça, boca aberta, cauda.
a = Anim('celebrate', 90)
a.key('ear_left_root', 'rot', [(0, deg(-8)), (45, deg(-11)), (90, deg(-8))])
a.key('ear_right_root', 'rot', [(0, deg(8)), (45, deg(11)), (90, deg(8))])
a.key('head_root', 'y', [(0, 0), (22, -6), (45, 0), (67, -6), (90, 0)])
a.key('head_root', 'rot', [(0, 0), (45, deg(2)), (90, 0)])
a.key('tail_root', 'rot', wave(90, 30, deg(10)), curve='linear')
a.key('body', 'sy', [(0, 0.01)])
open_mouth(a)
anims.append(a)

# 2 think — cabeça inclinada, sobrancelha levantada, pisca devagar.
a = Anim('think', 180)
a.key('head_root', 'rot', [(0, deg(-5)), (90, deg(-6)), (180, deg(-5))])
a.key('eyebrow_right', 'y', [(0, -7), (90, -9), (180, -7)])
a.key('eyebrow_left', 'y', [(0, 2)])
a.key('ear_left_root', 'rot', [(0, deg(-3))]); a.key('ear_right_root', 'rot', [(0, deg(5))])
a.key('tail_root', 'rot', [(0, 0), (90, deg(2)), (180, 0)])
a.key('body', 'sy', [(0, 0), (90, 0.008), (180, 0)])
blink(a, 140)
anims.append(a)

# 3 sleep — olhos fechados, cabeça baixa, respiração lenta, orelhas relaxadas.
a = Anim('sleep', 300)
for side in ('left', 'right'):
    a.key(f'eye_{side}', 'op', [(0, -1)]); a.key(f'eye_{side}_closed', 'op', [(0, 1)])
a.key('head_root', 'rot', [(0, deg(3)), (150, deg(4)), (300, deg(3))])
a.key('head_root', 'y', [(0, 8), (150, 10), (300, 8)])
a.key('ear_left_root', 'rot', [(0, deg(-10))]); a.key('ear_right_root', 'rot', [(0, deg(10))])
a.key('body', 'sy', [(0, 0), (150, 0.02), (300, 0)])
a.key('body', 'sx', [(0, 0), (150, 0.006), (300, 0)])
a.key('eyebrow_left', 'y', [(0, 3)]); a.key('eyebrow_right', 'y', [(0, 3)])
anims.append(a)

# 4 victory — marco (nível/evolução): pequeno pulo, orelhas em pé, boca aberta, cauda.
a = Anim('victory', 72)
a.key('body', 'y', [(0, 0), (18, -12), (36, 0), (54, -12), (72, 0)])
a.key('body', 'sy', [(0, -0.015), (6, 0.01), (30, 0.005), (36, -0.015), (42, 0.01), (66, 0.005), (72, -0.015)])
a.key('ground_shadow', 'sx', [(0, 0), (18, -0.12), (36, 0), (54, -0.12), (72, 0)])
a.key('ground_shadow', 'op', [(0, 0), (18, -0.35), (36, 0), (54, -0.35), (72, 0)])
a.key('ear_left_root', 'rot', [(0, deg(-12))]); a.key('ear_right_root', 'rot', [(0, deg(12))])
a.key('head_root', 'rot', [(0, 0), (18, deg(-2)), (36, 0), (54, deg(2)), (72, 0)])
a.key('tail_root', 'rot', wave(72, 24, deg(14)), curve='linear')
a.key('eyebrow_left', 'y', [(0, -4)]); a.key('eyebrow_right', 'y', [(0, -4)])
open_mouth(a)
anims.append(a)

# 5 happy — reação ao toque: olhos sorrindo, boca aberta, cabeça inclinada, cauda.
a = Anim('happy', 54)
smile_eyes(a); open_mouth(a)
a.key('head_root', 'rot', [(0, 0), (14, deg(6)), (40, deg(6)), (54, deg(4))])
a.key('ear_left_root', 'rot', [(0, deg(-6))]); a.key('ear_right_root', 'rot', [(0, deg(6))])
a.key('tail_root', 'rot', wave(54, 18, deg(12)), curve='linear')
a.key('body', 'sy', [(0, 0), (10, 0.015), (20, 0), (54, 0)])
anims.append(a)

MOODS = [x.name for x in anims]      # índice == PetAnimationState.index

# poses estáticas (reduzir movimento): 1 frame com a pose característica de cada humor
POSE_FRAME = {'idle': 0, 'celebrate': 0, 'think': 0, 'sleep': 0, 'victory': 36, 'happy': 20}
statics = []
for src in anims:
    s = Anim(src.name + '_static', 1, loop=False)
    f = POSE_FRAME[src.name]
    for node, ch in CHANNELS:
        v = src.value_at(node, ch, f)
        s.tracks[(node, ch)] = [(0, v, 'hold')]
    statics.append(s)

# camada de interação — medalhão pulsa enquanto a folha de interação está aberta
glow = Anim('medallion_glow', 90)
glow_off = Anim('medallion_rest', 1, loop=False)
GLOW_CH = [('medallion', 'sx'), ('medallion', 'sy'), ('medallion', 'op')]
glow.tracks[('medallion', 'sx')] = [(0, 1, 'ease'), (45, 1.07, 'ease'), (90, 1, 'ease')]
glow.tracks[('medallion', 'sy')] = [(0, 1, 'ease'), (45, 1.07, 'ease'), (90, 1, 'ease')]
glow.tracks[('medallion', 'op')] = [(0, 1, 'ease'), (45, 0.8, 'ease'), (90, 1, 'ease')]
for c in GLOW_CH: glow_off.tracks[c] = [(0, 1.0, 'hold')]

# ---------------- escrita do arquivo ----------------
def build():
    w = Writer()
    w.add('Backboard')
    order = IMAGES
    for i, (name, _) in enumerate(order):
        info = L[name]
        w.add('ImageAsset', name=f'wolf_{name}', assetId=i, width=float(info['size'][0]), height=float(info['size'][1]))
        w.add('FileAssetContents', bytes=open(f"{LAYERS}/{info['file']}", 'rb').read())
    w.add('Artboard', name='Wolf', width=float(M['artboard'][0]), height=float(M['artboard'][1]),
          defaultStateMachineId=0)
    # índices de componentes: 0 = artboard; nós primeiro (pais antes de filhos), depois imagens
    comp = ['artboard'] + list(NODES) + [n for n, _ in order]
    idx = {n: i for i, n in enumerate(comp)}
    for n in NODES:
        x, y = local_pos(n)
        w.add('Node', name=n, parentId=idx[parent_of(n)], x=x, y=y)
    for i, (n, p) in enumerate(order):
        x, y = local_pos(n)
        props = dict(name=n, parentId=idx[p], x=x, y=y, assetId=i, originX=0.5, originY=0.5)
        if n in HIDDEN: props['opacity'] = 0.0
        w.add('Image', **props)

    def write_anim(a, channels=None):
        w.add('LinearAnimation', name=a.name, fps=FPS, duration=a.frames, speed=1.0, loopValue=1 if a.loop else 0)
        if channels is None:
            tracks = a.keys()
        else:
            tracks = {c: bake(a.tracks[c], a.frames) for c in channels}
        by_node = {}
        for (node, ch), kf in tracks.items(): by_node.setdefault(node, []).append((ch, kf))
        for node, chans in by_node.items():
            w.add('KeyedObject', objectId=idx[node])
            for ch, kf in chans:
                pk = {'x': 13, 'y': 14, 'rot': 15, 'sx': 16, 'sy': 17, 'op': 18}[ch]
                w.add('KeyedProperty', propertyKey=pk)
                for f, v in kf:
                    w.add('KeyFrameDouble', frame=int(f), interpolationType=1, value=float(v))

    anim_index = {}
    for a in anims + statics:
        anim_index[a.name] = len(anim_index); write_anim(a)
    for a in (glow, glow_off):
        anim_index[a.name] = len(anim_index); write_anim(a, GLOW_CH)

    # state machine
    w.add('StateMachine', name='Companion')
    w.add('StateMachineNumber', name='state', value=0.0)          # input 0
    w.add('StateMachineBool', name='reducedMotion', value=False)  # input 1
    w.add('StateMachineBool', name='interacting', value=False)    # input 2
    EQ, NEQ = 0, 1
    XFADE = 250  # ms
    EARLY = 32   # StateTransitionFlags.enableEarlyExit: permite interromper a transição em curso

    # camada 1: humor
    w.add('StateMachineLayer', name='Mood')
    states = MOODS + [m + '_static' for m in MOODS]
    sid = {n: 3 + i for i, n in enumerate(states)}
    w.add('AnyState')
    for i, m in enumerate(MOODS):
        w.add('StateTransition', stateToId=sid[m], duration=XFADE, flags=EARLY)
        w.add('TransitionNumberCondition', inputId=0, opValue=EQ, value=float(i))
        w.add('TransitionBoolCondition', inputId=1, opValue=NEQ)        # reducedMotion == false
        w.add('StateTransition', stateToId=sid[m + '_static'], duration=0, flags=EARLY)
        w.add('TransitionNumberCondition', inputId=0, opValue=EQ, value=float(i))
        w.add('TransitionBoolCondition', inputId=1, opValue=EQ)         # reducedMotion == true
    w.add('EntryState')
    w.add('StateTransition', stateToId=sid['idle'])
    w.add('ExitState')
    for n in states:
        w.add('AnimationState', name=n, animationId=anim_index[n])

    # camada 2: interação (brilho do medalhão)
    w.add('StateMachineLayer', name='Interaction')
    w.add('AnyState')
    w.add('StateTransition', stateToId=4, duration=XFADE, flags=EARLY)   # -> glow
    w.add('TransitionBoolCondition', inputId=2, opValue=EQ)
    w.add('TransitionBoolCondition', inputId=1, opValue=NEQ)
    w.add('StateTransition', stateToId=3, duration=XFADE, flags=EARLY)   # -> rest (não interagindo)
    w.add('TransitionBoolCondition', inputId=2, opValue=NEQ)
    w.add('StateTransition', stateToId=3, duration=0, flags=EARLY)       # -> rest (reduzir movimento)
    w.add('TransitionBoolCondition', inputId=1, opValue=EQ)
    w.add('EntryState')
    w.add('StateTransition', stateToId=3)
    w.add('ExitState')
    w.add('AnimationState', name='medallion_rest', animationId=anim_index['medallion_rest'])
    w.add('AnimationState', name='medallion_glow', animationId=anim_index['medallion_glow'])
    data = w.bytes()
    open(OUT, 'wb').write(data)
    return data

if __name__ == '__main__':
    d = build(); print(OUT, len(d), 'bytes')
