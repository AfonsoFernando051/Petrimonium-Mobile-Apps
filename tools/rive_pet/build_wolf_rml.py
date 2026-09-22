"""Uso: python3 tools/rive_pet/build_wolf_rml.py  (depois de slice_wolf.py)

Gera um projeto da Rive CLI (RML) equivalente ao wolf.riv que `build_wolf.py`
escreve — mesmo rig, mesmas animações e a mesma state machine `Companion` —
para que tudo abra *editável* no editor do Rive:

    rive tools/rive_pet/rml --verify     # valida a sintaxe
    rive tools/rive_pet/rml              # preview com hot reload
    rive login && rive push              # manda para o arquivo da conta (editor)

Saída em tools/rive_pet/rml/: rive.yaml, scene.rml, images/ e wolf_spec.json
(o mesmo conteúdo em JSON neutro, caso algum nome de atributo da RML precise
ser ajustado — confira com `rive schema <Tipo>` e regenere por aqui).
"""
import json, os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_wolf as B          # rig, animações e poses vêm daqui (fonte única)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'rml')
IMG = os.path.join(OUT, 'images')
PROP = {'x': 'x', 'y': 'y', 'rot': 'rotation', 'sx': 'scaleX', 'sy': 'scaleY', 'op': 'opacity'}

def esc(v):
    return str(v).replace('&', '&amp;').replace('<', '&lt;').replace('"', '&quot;')

def attrs(**kw):
    return ''.join(f' {k}="{esc(v)}"' for k, v in kw.items() if v is not None)

def tracks_of(anim, channels=None):
    """[(node, canal, [(frame, valor)])] já 'assado' em keyframes lineares."""
    if channels is None:
        baked = anim.keys()
    else:
        baked = {c: B.bake(anim.tracks[c], anim.frames) for c in channels}
    out = {}
    for (node, ch), kf in baked.items():
        out.setdefault(node, []).append((ch, kf))
    return out

def animation_xml(anim, channels=None, indent='    '):
    L = [f'{indent}<LinearAnimation{attrs(name=anim.name, fps=B.FPS, duration=anim.frames, speed=1.0, loopValue=1 if anim.loop else 0)}>']
    for node, chans in tracks_of(anim, channels).items():
        L.append(f'{indent}  <KeyedObject{attrs(objectId=node)}>')
        for ch, kf in chans:
            L.append(f'{indent}    <KeyedProperty{attrs(propertyKey=PROP[ch])}>')
            for f, v in kf:
                L.append(f'{indent}      <KeyFrameDouble{attrs(frame=int(f), value=round(float(v), 4), interpolationType=1)}/>')
            L.append(f'{indent}    </KeyedProperty>')
        L.append(f'{indent}  </KeyedObject>')
    L.append(f'{indent}</LinearAnimation>')
    return L

def scene_xml():
    L = ['<?xml version="1.0" encoding="UTF-8"?>',
         '<!-- Gerado por tools/rive_pet/build_wolf_rml.py — não edite à mão:',
         '     ajuste o gerador (ou o spec) e rode de novo, senão o editor e o',
         '     Python saem de sincronia. Contrato do app: state machine `Companion`,',
         '     input `state` = PetAnimationState.index (0 idle, 1 celebrate, 2 think,',
         '     3 sleep, 4 victory, 5 happy), bools `reducedMotion` e `interacting`. -->',
         '<Rive version="1" kind="fragment">']
    # assets
    for name, _ in B.IMAGES:
        info = B.L[name]
        src = 'images/' + info['file']
        L.append('  <ImageAsset' + attrs(id=name, name='wolf_' + name, src=src,
                                         width=info['size'][0], height=info['size'][1]) + '/>')
    W, H = B.M['artboard']
    L.append(f'  <Artboard{attrs(name="Wolf", width=float(W), height=float(H), defaultStateMachine="Companion")}>')

    # rig: nós de pivô e imagens (ordem do arquivo = da frente para trás)
    children = {}
    for n in B.NODES: children.setdefault(B.parent_of(n), []).append(('node', n))
    for n, p in B.IMAGES: children.setdefault(p, []).append(('image', n))
    # Ordem de desenho: como no editor, o primeiro filho fica na FRENTE. Cada nó
    # herda o rank da sua imagem mais à frente, para grupo e imagem se
    # intercalarem na ordem certa (ex.: head_root antes da coleira).
    front = {n: i for i, (n, _) in enumerate(B.IMAGES)}
    def rank(kind, name):
        if kind == 'image': return front[name]
        return min([rank(k, c) for k, c in children.get(name, [])] or [len(front)])
    for k in children: children[k].sort(key=lambda kn: rank(*kn))
    def emit(parent, indent):
        for kind, name in children.get(parent, []):
            x, y = B.local_pos(name)
            if kind == 'node':
                L.append(f'{indent}<Node{attrs(id=name, name=name, x=x, y=y)}>')
                emit(name, indent + '  ')
                L.append(f'{indent}</Node>')
            else:
                op = 0.0 if name in B.HIDDEN else None
                L.append(f'{indent}<Image{attrs(id=name, name=name, x=x, y=y, assetId=name, originX=0.5, originY=0.5, opacity=op)}/>')
    emit('artboard', '    ')

    for a in B.anims + B.statics: L += animation_xml(a)
    for a in (B.glow, B.glow_off): L += animation_xml(a, B.GLOW_CH)

    # state machine
    L.append('    <StateMachine name="Companion">')
    L.append('      <StateMachineNumber name="state" value="0"/>')
    L.append('      <StateMachineBool name="reducedMotion" value="false"/>')
    L.append('      <StateMachineBool name="interacting" value="false"/>')
    L.append('      <StateMachineLayer name="Mood">')
    L.append('        <EntryState><StateTransition stateToId="idle"/></EntryState>')
    L.append('        <AnyState>')
    for i, m in enumerate(B.MOODS):
        # `flags="32"` = enableEarlyExit: sem isso a troca só vale depois do crossfade
        L.append(f'          <StateTransition{attrs(stateToId=m, duration=250, flags=32)}>')
        L.append(f'            <TransitionNumberCondition{attrs(inputId="state", opValue="equal", value=float(i))}/>')
        L.append('            <TransitionBoolCondition inputId="reducedMotion" opValue="notEqual"/>')
        L.append('          </StateTransition>')
        L.append(f'          <StateTransition{attrs(stateToId=m + "_static", duration=0, flags=32)}>')
        L.append(f'            <TransitionNumberCondition{attrs(inputId="state", opValue="equal", value=float(i))}/>')
        L.append('            <TransitionBoolCondition inputId="reducedMotion" opValue="equal"/>')
        L.append('          </StateTransition>')
    L.append('        </AnyState>')
    for m in B.MOODS:
        L.append(f'        <AnimationState{attrs(name=m, animationId=m)}/>')
        L.append(f'        <AnimationState{attrs(name=m + "_static", animationId=m + "_static")}/>')
    L.append('        <ExitState/>')
    L.append('      </StateMachineLayer>')
    L.append('      <StateMachineLayer name="Interaction">')
    L.append('        <EntryState><StateTransition stateToId="medallion_rest"/></EntryState>')
    L.append('        <AnyState>')
    L.append(f'          <StateTransition{attrs(stateToId="medallion_glow", duration=250, flags=32)}>')
    L.append('            <TransitionBoolCondition inputId="interacting" opValue="equal"/>')
    L.append('            <TransitionBoolCondition inputId="reducedMotion" opValue="notEqual"/>')
    L.append('          </StateTransition>')
    L.append(f'          <StateTransition{attrs(stateToId="medallion_rest", duration=250, flags=32)}>')
    L.append('            <TransitionBoolCondition inputId="interacting" opValue="notEqual"/>')
    L.append('          </StateTransition>')
    L.append(f'          <StateTransition{attrs(stateToId="medallion_rest", duration=0, flags=32)}>')
    L.append('            <TransitionBoolCondition inputId="reducedMotion" opValue="equal"/>')
    L.append('          </StateTransition>')
    L.append('        </AnyState>')
    L.append('        <AnimationState name="medallion_rest" animationId="medallion_rest"/>')
    L.append('        <AnimationState name="medallion_glow" animationId="medallion_glow"/>')
    L.append('        <ExitState/>')
    L.append('      </StateMachineLayer>')
    L.append('    </StateMachine>')
    L.append('  </Artboard>')
    L.append('</Rive>')
    return '\n'.join(L) + '\n'

def spec_json():
    """Mesmo conteúdo em JSON neutro: rig + keyframes, para regerar/ajustar."""
    rig = []
    for n in B.NODES:
        x, y = B.local_pos(n); rig.append({'type': 'node', 'name': n, 'parent': B.parent_of(n), 'x': x, 'y': y})
    for n, p in B.IMAGES:
        x, y = B.local_pos(n)
        rig.append({'type': 'image', 'name': n, 'parent': p, 'x': x, 'y': y, 'file': B.L[n]['file'],
                    'size': B.L[n]['size'], 'originX': 0.5, 'originY': 0.5,
                    'opacity': 0.0 if n in B.HIDDEN else 1.0})
    def anim(a, channels=None):
        return {'name': a.name, 'fps': B.FPS, 'duration': a.frames, 'loop': a.loop,
                'tracks': [{'node': node, 'property': PROP[ch], 'keys': [[int(f), round(float(v), 4)] for f, v in kf]}
                           for node, chans in tracks_of(a, channels).items() for ch, kf in chans]}
    return {'artboard': {'name': 'Wolf', 'width': B.M['artboard'][0], 'height': B.M['artboard'][1]},
            'drawOrderFrontToBack': [n for n, _ in B.IMAGES],
            'rig': rig,
            'animations': [anim(a) for a in B.anims + B.statics] + [anim(B.glow, B.GLOW_CH), anim(B.glow_off, B.GLOW_CH)],
            'stateMachine': {'name': 'Companion', 'inputs': [{'name': 'state', 'type': 'number'},
                                                             {'name': 'reducedMotion', 'type': 'bool'},
                                                             {'name': 'interacting', 'type': 'bool'}],
                             'moodOrder': B.MOODS, 'crossfadeMs': 250}}

RIVE_YAML = '''# Projeto da Rive CLI para o pet lobo do Petrimonium.
#   rive tools/rive_pet/rml --verify   # valida
#   rive tools/rive_pet/rml            # preview com hot reload
#   rive login && rive push            # envia para o arquivo da conta (abre no editor)
name: wolf-companion
version: 1
sources:
  - scene.rml
'''

if __name__ == '__main__':
    os.makedirs(IMG, exist_ok=True)
    for name, _ in B.IMAGES:
        shutil.copy(os.path.join(B.LAYERS, B.L[name]['file']), IMG)
    open(os.path.join(OUT, 'scene.rml'), 'w').write(scene_xml())
    open(os.path.join(OUT, 'rive.yaml'), 'w').write(RIVE_YAML)
    json.dump(spec_json(), open(os.path.join(OUT, 'wolf_spec.json'), 'w'), indent=1)
    print('ok', OUT)
