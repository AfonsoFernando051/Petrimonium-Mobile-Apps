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
# A RML endereça uma propriedade chaveada pelo número dela, não pelo nome
# (`rive schema Node --animatable`). Os mesmos números que build_wolf.py usa.
PROP_KEY = {'x': 13, 'y': 14, 'rot': 15, 'sx': 16, 'sy': 17, 'op': 18}

# Todo id da RML é um par numérico `cliente:objeto` e vive num namespace único no
# documento inteiro — nome não serve como id. Este alocador dá um id estável por
# chave lógica, para que o XML gerado seja determinístico entre execuções.
_IDS = {}
def ident(key):
    return _IDS.setdefault(key, '0:%d' % (len(_IDS) + 2))

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
    L = [f'{indent}<LinearAnimation{attrs(name=anim.name, fps=B.FPS, duration=anim.frames, speed=1.0, loopValue="loop" if anim.loop else "oneShot", id=ident("anim:" + anim.name))}>']
    for node, chans in tracks_of(anim, channels).items():
        L.append(f'{indent}  <KeyedObject{attrs(objectId=ident("node:" + node))}>')
        for ch, kf in chans:
            L.append(f'{indent}    <KeyedProperty{attrs(propertyKey=PROP_KEY[ch])}>')
            for f, v in kf:
                L.append(f'{indent}      <KeyFrameDouble{attrs(frame=int(f), value=round(float(v), 4), interpolationType="linear")}/>')
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
        # `file` é atributo de autoria da RML, não propriedade do core: `rive schema`
        # nunca o lista, mas é o único jeito de dar bytes ao asset.
        L.append('  <ImageAsset' + attrs(id=ident('asset:' + name), name='wolf_' + name, file=src,
                                         width=info['size'][0], height=info['size'][1]) + '/>')
    W, H = B.M['artboard']
    L.append(f'  <Artboard{attrs(name="Wolf", width=float(W), height=float(H), defaultStateMachineId=ident("sm"), styleId=ident("style"), id=ident("artboard"))}>')
    L.append(f'    <LayoutComponentStyle{attrs(name="Artboard Style", id=ident("style"))}/>')

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
                L.append(f'{indent}<Node{attrs(id=ident("node:" + name), name=name, x=x, y=y)}>')
                emit(name, indent + '  ')
                L.append(f'{indent}</Node>')
            else:
                op = 0.0 if name in B.HIDDEN else None
                L.append(f'{indent}<Image{attrs(id=ident("node:" + name), name=name, x=x, y=y, assetId=ident("asset:" + name), originX=0.5, originY=0.5, opacity=op)}/>')
    emit('artboard', '    ')

    for a in B.anims + B.statics: L += animation_xml(a)
    for a in (B.glow, B.glow_off): L += animation_xml(a, B.GLOW_CH)

    # state machine
    L.append(f'    <StateMachine{attrs(name="Companion", id=ident("sm"))}>')
    L.append(f'      <StateMachineNumber{attrs(name="state", value=0.0, id=ident("in:state"))}/>')
    L.append(f'      <StateMachineBool{attrs(name="reducedMotion", value="false", id=ident("in:reducedMotion"))}/>')
    L.append(f'      <StateMachineBool{attrs(name="interacting", value="false", id=ident("in:interacting"))}/>')

    # Posicao de cada estado no grafo do editor: duas colunas (animado / estatico),
    # uma linha por humor. So o editor usa isto; o runtime ignora.
    GRAPH = {}
    for i, m in enumerate(B.MOODS):
        GRAPH[m] = (40, 40 + i * 90)
        GRAPH[m + '_static'] = (260, 40 + i * 90)
    GRAPH['medallion_rest'] = (40, 40)
    GRAPH['medallion_glow'] = (260, 40)

    def transition(to, duration, conds, indent='          '):
        # enableEarlyExit é um bit de `flags`, escrito como atributo próprio: sem
        # ele a troca só vale depois do crossfade e toques rápidos ficam presos.
        L.append(f'{indent}<StateTransition{attrs(stateToId=ident("state:" + to), duration=duration, enableEarlyExit="true")}>')
        for c in conds:
            L.append(indent + '  ' + c)
        L.append(f'{indent}</StateTransition>')

    def num_cond(value):
        return f'<TransitionNumberCondition{attrs(inputId=ident("in:state"), opValue="equal", value=float(value))}/>'

    def bool_cond(name, equal):
        return f'<TransitionBoolCondition{attrs(inputId=ident("in:" + name), opValue="equal" if equal else "notEqual")}/>'

    L.append(f'      <StateMachineLayer{attrs(name="Mood", id=ident("layer:mood"))}>')
    L.append('        <AnyState x="-180" y="40">')
    for i, m in enumerate(B.MOODS):
        transition(m, 250, [num_cond(i), bool_cond('reducedMotion', False)])
        transition(m + '_static', 0, [num_cond(i), bool_cond('reducedMotion', True)])
    L.append('        </AnyState>')
    L.append('        <EntryState x="-180" y="-60">')
    transition('idle', 0, [], indent='          ')
    L.append('        </EntryState>')
    L.append('        <ExitState x="480" y="40"/>')
    for m in B.MOODS:
        L.append(f'        <AnimationState{attrs(x=GRAPH[m][0], y=GRAPH[m][1], animationId=ident("anim:" + m), id=ident("state:" + m))}/>')
        L.append(f'        <AnimationState{attrs(x=GRAPH[m + "_static"][0], y=GRAPH[m + "_static"][1], animationId=ident("anim:" + m + "_static"), id=ident("state:" + m + "_static"))}/>')
    L.append('      </StateMachineLayer>')

    L.append(f'      <StateMachineLayer{attrs(name="Interaction", id=ident("layer:interaction"))}>')
    L.append('        <AnyState x="-180" y="40">')
    transition('medallion_glow', 250, [bool_cond('interacting', True), bool_cond('reducedMotion', False)])
    transition('medallion_rest', 250, [bool_cond('interacting', False)])
    transition('medallion_rest', 0, [bool_cond('reducedMotion', True)])
    L.append('        </AnyState>')
    L.append('        <EntryState x="-180" y="-60">')
    transition('medallion_rest', 0, [], indent='          ')
    L.append('        </EntryState>')
    L.append('        <ExitState x="480" y="40"/>')
    L.append(f'        <AnimationState{attrs(x=GRAPH["medallion_rest"][0], y=GRAPH["medallion_rest"][1], animationId=ident("anim:medallion_rest"), id=ident("state:medallion_rest"))}/>')
    L.append(f'        <AnimationState{attrs(x=GRAPH["medallion_glow"][0], y=GRAPH["medallion_glow"][1], animationId=ident("anim:medallion_glow"), id=ident("state:medallion_glow"))}/>')
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
    # As camadas vêm do slice_wolf.py. Quando a saída dele não está no disco
    # (o slicer precisa de opencv, o projeto RML não), reaproveitamos as que já
    # estão em rml/images/ em vez de falhar — mas só se estiverem todas lá.
    if os.path.isdir(B.LAYERS):
        for name, _ in B.IMAGES:
            shutil.copy(os.path.join(B.LAYERS, B.L[name]['file']), IMG)
    else:
        faltando = [B.L[n]['file'] for n, _ in B.IMAGES if not os.path.exists(os.path.join(IMG, B.L[n]['file']))]
        if faltando:
            raise SystemExit(f'sem {B.LAYERS} e faltam camadas em {IMG}: {faltando}\nrode slice_wolf.py (pip install opencv-python numpy pillow)')
        print(f'reusando as camadas ja presentes em {IMG} ({B.LAYERS} nao existe)')
    open(os.path.join(OUT, 'scene.rml'), 'w').write(scene_xml())
    # O primeiro `rive push` grava um bloco `push:` (projectId/fileId) no
    # rive.yaml. Sobrescrever o arquivo aqui perderia esse vínculo e o push
    # seguinte criaria um arquivo novo no Rive em vez de atualizar o existente.
    yaml_path = os.path.join(OUT, 'rive.yaml')
    push_block = ''
    if os.path.exists(yaml_path):
        atual = open(yaml_path).read()
        if '\npush:' in atual:
            push_block = atual[atual.index('\npush:'):].rstrip() + '\n'
    open(yaml_path, 'w').write(RIVE_YAML + push_block)
    json.dump(spec_json(), open(os.path.join(OUT, 'wolf_spec.json'), 'w'), indent=1)
    print('ok', OUT)
