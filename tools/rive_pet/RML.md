# Levar o lobo para o editor do Rive (RML + Rive CLI)

O `.riv` que `build_wolf.py` gera é **só a saída de runtime** — o editor do Rive não reimporta um
`.riv`, por isso o arquivo `WolfCompanion-v1` mostra apenas as camadas e uma `Timeline 1` vazia.
O caminho oficial para ter as animações **editáveis** no editor é a Rive CLI com RML (Rive Markup
Language): o projeto é texto, a CLI compila, e `rive push` manda para um arquivo da sua conta.

`build_wolf_rml.py` gera esse projeto a partir da **mesma** especificação usada no gerador Python,
então editor e código não divergem.

```bash
python3 tools/rive_pet/slice_wolf.py        # camadas (se ainda não rodou)
python3 tools/rive_pet/build_wolf_rml.py    # gera tools/rive_pet/rml/

# instalar a CLI (macOS/Linux; no Windows use o install.ps1 da doc)
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

## Atenção: a sintaxe RML não pôde ser validada aqui

Esta sessão não alcança `releases.rive.app`, então a CLI não rodou. A estrutura segue a
documentação ("cada elemento é um tipo do Rive, cada atributo é uma propriedade dele") e os
mesmos tipos que o `.riv` já validado usa (`Artboard`, `Node`, `Image`, `LinearAnimation`,
`KeyedObject`/`KeyedProperty`/`KeyFrameDouble`, `StateMachine`, `StateMachineNumber`,
`StateMachineBool`, `StateMachineLayer`, `AnyState`/`EntryState`/`ExitState`, `AnimationState`,
`StateTransition`, `TransitionNumberCondition`, `TransitionBoolCondition`). Pontos mais prováveis
de ajuste no primeiro `--verify`:

- como o artboard aponta a state machine padrão (`defaultStateMachine`);
- como uma referência é escrita (usei `id`/`objectId`/`assetId` por nome; a doc cita IDs no
  formato `0:12`);
- nomes das propriedades chaveadas (`x`, `y`, `rotation`, `scaleX`, `scaleY`, `opacity`);
- `opValue` das condições (`equal`/`notEqual`) e `flags="32"` (enableEarlyExit) na transição.

## Contrato (não muda)

Artboard `Wolf` 500×686, state machine `Companion`, input número `state` =
`PetAnimationState.index` (0 idle, 1 celebrate, 2 think, 3 sleep, 4 victory, 5 happy), bools
`reducedMotion` (pose estática equivalente) e `interacting` (pulso do medalhão). Toda animação
chaveia a pose completa — o runtime legado (`rive 0.13.x`) não zera o que a animação seguinte não
chaveia.

Enquanto o `push` não acontecer, o asset do app continua sendo o `assets/rive/pet/wolf.riv` gerado
por `build_wolf.py`. Depois que o arquivo do editor virar a fonte, exporte de lá para esse mesmo
caminho e mantenha os dois geradores só como referência.
