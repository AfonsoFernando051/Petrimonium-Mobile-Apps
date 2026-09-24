# Levar o lobo para o editor do Rive (RML + Rive CLI)

O `.riv` que `build_wolf.py` gera é **só a saída de runtime** — o editor do Rive não reimporta um
`.riv`, por isso o arquivo `WolfCompanion-v1` mostra apenas as camadas e uma `Timeline 1` vazia.
O caminho oficial para ter as animações **editáveis** no editor é a Rive CLI com RML (Rive Markup
Language): o projeto é texto, a CLI compila, e `rive push` manda para um arquivo da sua conta.

`build_wolf_rml.py` gera esse projeto a partir da **mesma** especificação usada no gerador Python,
então editor e código não divergem.

```bash
# as camadas: do slicer (precisa de opencv) OU reconstruídas do rml/ versionado
python3 tools/rive_pet/slice_wolf.py               # ao trocar a arte de origem
python3 tools/rive_pet/restore_layers_manifest.py  # quando só falta o manifesto
python3 tools/rive_pet/build_wolf_rml.py           # gera tools/rive_pet/rml/

# a CLI (já instalada em ~/.rive/bin, que precisa estar no PATH)
curl -fsSL https://releases.rive.app/cli/install.sh | sh
rive doctor

rive tools/rive_pet/rml --verify            # valida a sintaxe
rive tools/rive_pet/rml                     # preview com hot reload
rive login
rive push                                   # envia para um arquivo da sua conta
```

Depois do `push`, abra o arquivo no editor: artboard `Wolf`, as 6 timelines (idle, celebrate,
think, sleep, victory, happy), as 6 poses estáticas, o brilho do medalhão e a state machine
`Companion`.

## O que o projeto contém

- `rive.yaml` — configuração do projeto.
- `scene.rml` — assets, rig (nós de pivô + imagens), animações e a state machine.
- `images/` — as 21 camadas PNG.
- `wolf_spec.json` — o mesmo conteúdo em JSON neutro (rig, keyframes, state machine). Se algum
  nome de elemento/atributo da RML não bater com o schema da CLI, corrija o gerador usando
  `rive schema <Tipo>` / `rive docs` e regenere — o spec continua sendo a fonte.

## A sintaxe RML, conferida contra o schema real

O gerador emitia uma RML inventada e nenhum elemento passava no `--verify`. O que
o schema exige de verdade (`rive schema <Tipo>`), e que o gerador agora faz:

- **Todo id é um par numérico `cliente:objeto`** (`0:12`). Nome não serve como id,
  e o namespace é único no documento inteiro. `ident()` no gerador aloca um id
  estável por chave lógica, para o XML sair determinístico.
- **`ImageAsset` recebe os bytes por `file=`**, não `src=`. `file` é atributo de
  autoria da RML, não propriedade do core — `rive schema` nunca o lista, em tipo
  nenhum. É o único lugar em que "procure o nome em vez de chutar" não funciona.
- **`Artboard` aponta a state machine por `defaultStateMachineId`** (o id, não o nome).
- **`KeyedProperty` endereça a propriedade pelo número**, não pelo nome:
  x=13, y=14, rotation=15, scaleX=16, scaleY=17, opacity=18
  (`rive schema Node --animatable`). São os mesmos números que `build_wolf.py` usa.
- **`AnimationState` não tem `name`** — o estado se chama como a animação que ele aponta.
- **`enableEarlyExit` é um bit de `flags`, escrito como atributo próprio**
  (`enableEarlyExit="true"`), não `flags="32"`.
- **`AnyState`, `EntryState` e `ExitState` são obrigatórios** em cada
  `StateMachineLayer`, mesmo sem uso — sem os três o layer não importa.

Duas coisas existem só para o editor e o runtime ignora, mas sem elas o arquivo
abre inutilizável: um `<LayoutComponentStyle>` no artboard (sem ele nada dentro
dele faz layout no editor) e um `x`/`y` por estado (sem eles os 14 estados abrem
empilhados no mesmo ponto do grafo).

**Build limpo é sinal fraco** — a própria doc da CLI avisa. Nome errado a CLI
pega; fiação errada, não. Confira o que saiu, não que saiu:

```bash
rive tools/rive_pet/rml --verify                  # 0 erros, 0 avisos
rive inspect tools/rive_pet/rml --summary         # "problems" vazio + contagem por tipo
rive tools/rive_pet/rml --screenshot=/tmp/wolf.png --advance=30   # renderiza de verdade
```

## O arquivo no Rive

O push criou o arquivo **2606100 `wolf-companion`** no projeto **1979092
(Ecossistema Petrimonium)**, e gravou esse vínculo no bloco `push:` do
`rive.yaml`. Dali em diante:

- `rive push tools/rive_pet/rml` atualiza **esse** arquivo (nova entrada no
  histórico de revisões), não cria outro;
- `rive pull tools/rive_pet/rml` traz de volta o que foi editado no editor.

Duas armadilhas conhecidas:

1. O push grava ~1800 ids de keyframe de volta no `scene.rml` (é assim que a
   identidade sobrevive entre builds). **Rodar `build_wolf_rml.py` de novo
   reescreve o `scene.rml` do zero e perde esses ids** — o push seguinte então
   lê tudo como apagar+criar em vez de editar. Funciona, mas descarta o
   histórico fino. Enquanto o gerador for a fonte, isso é aceitável; quando o
   editor virar a fonte, pare de regerar e use `pull`.
2. Por isso o gerador preserva o bloco `push:` ao reescrever o `rive.yaml` —
   sem isso o vínculo se perderia e o próximo push criaria um segundo arquivo.

## Contrato (não muda)

Artboard `Wolf` 500×686, state machine `Companion`, input número `state` =
`PetAnimationState.index` (0 idle, 1 celebrate, 2 think, 3 sleep, 4 victory, 5 happy), bools
`reducedMotion` (pose estática equivalente) e `interacting` (pulso do medalhão). Toda animação
chaveia a pose completa — o runtime legado (`rive 0.13.x`) não zera o que a animação seguinte não
chaveia.

Enquanto o `push` não acontecer, o asset do app continua sendo o `assets/rive/pet/wolf.riv` gerado
por `build_wolf.py`. Depois que o arquivo do editor virar a fonte, exporte de lá para esse mesmo
caminho e mantenha os dois geradores só como referência.
