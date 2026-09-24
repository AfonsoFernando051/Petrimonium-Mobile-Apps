"""Uso: python3 tools/rive_pet/restore_layers_manifest.py

Reconstrói build/rive_pet/wolf_layers/ (as camadas + wolf_layers.json) a partir
do projeto RML já versionado em tools/rive_pet/rml/.

Existe porque `rml/` é versionado e a saída do slice_wolf.py não é: sem isto,
regerar o .riv ou o projeto RML exige rodar o slicer de novo — que precisa de
opencv e refaz o corte, podendo render camadas diferentes das que o rig atual
assume. O spec RML carrega o rig inteiro, então a reconstrução é exata.

Não substitui o slice_wolf.py: para trocar a arte de origem, é o slicer que roda.
"""
import json, os, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
RML = os.path.join(HERE, 'rml')
OUT = os.environ.get('WOLF_LAYERS', os.path.join(ROOT, 'build/rive_pet/wolf_layers'))

spec = json.load(open(os.path.join(RML, 'wolf_spec.json')))
nodes = {n['name']: n for n in spec['rig']}

def absolute(name):
    """O spec guarda posição local; o manifesto do slicer guarda absoluta."""
    n = nodes[name]
    parent = n.get('parent', 'artboard')
    if parent == 'artboard':
        return [n['x'], n['y']]
    px, py = absolute(parent)
    return [px + n['x'], py + n['y']]

# O slicer grava o pivô junto da camada que ele articula; no rig ele virou um nó
# `<camada>_root` separado. Este é o mapeamento entre as duas formas.
PIVOT_NODE = {'head': 'head_root', 'tail': 'tail_root',
              'ear_left': 'ear_left_root', 'ear_right': 'ear_right_root'}

layers, hidden = {}, []
for n in spec['rig']:
    if n['type'] != 'image':
        continue
    name = n['name']
    layers[name] = {'file': n['file'], 'size': n['size'], 'center': absolute(name)}
    if name in PIVOT_NODE:
        layers[name]['pivot'] = absolute(PIVOT_NODE[name])
    if n.get('opacity', 1.0) == 0.0:
        hidden.append(name)

os.makedirs(OUT, exist_ok=True)
for info in layers.values():
    shutil.copy(os.path.join(RML, 'images', info['file']), OUT)
manifest = {'artboard': [spec['artboard']['width'], spec['artboard']['height']],
            'layers': layers, 'hidden_by_default': hidden}
json.dump(manifest, open(os.path.join(OUT, 'wolf_layers.json'), 'w'), indent=2)
print('ok', OUT, f'({len(layers)} camadas, {len(hidden)} ocultas)')
