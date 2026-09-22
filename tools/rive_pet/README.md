# tools/rive_pet — geração do `wolf.riv`

Gera `assets/rive/pet/wolf.riv` de forma reproduzível a partir de `assets/images/generated_wolf.png`,
já no contrato `Companion` que `PetRiveCompanion` espera (`_CompanionRig`) — nenhuma mudança de código
é necessária para o lobo: `wolf` não está em `_kRigForSpecie`, então cai no rig padrão.

```bash
pip install opencv-python numpy pillow
python3 tools/rive_pet/slice_wolf.py   # fatia a arte em 21 camadas → build/rive_pet/wolf_layers/
python3 tools/rive_pet/build_wolf.py   # escreve assets/rive/pet/wolf.riv (determinístico)
```

## Contrato do arquivo

| Item | Valor |
|---|---|
| Artboard | `Wolf` 500×686, artboard padrão |
| State machine | `Companion` (padrão) |
| `state` (number) | `PetAnimationState.index` — 0 idle, 1 celebrate, 2 think, 3 sleep, 4 victory, 5 happy (mesma ordem na Academy e na Wallet) |
| `reducedMotion` (bool) | `true` → pose estática equivalente de cada estado (`<estado>_static`), troca imediata |
| `interacting` (bool) | `true` → medalhão pulsa suavemente (camada `Interaction`); ignorado com `reducedMotion` |

Camada `Mood`: `AnyState → <estado>` quando `state == i && !reducedMotion` (crossfade 250 ms) e
`AnyState → <estado>_static` quando `state == i && reducedMotion` (0 ms). Todas as transições têm
`enableEarlyExit`, então trocas rápidas (ex.: toque → `happy` → volta a `idle`) não ficam presas numa
transição. Valor de `state` fora do enum mantém o estado atual.

Toda animação chaveia a pose completa (todos os canais), porque o runtime legado `rive 0.13.x` não
zera propriedades que a animação seguinte não chaveia — sem isso, olhos fechados do `sleep` "vazariam"
para o `idle`.

## Tom (Wallet × Academy)

Os movimentos são contidos de propósito, para servir aos dois apps: sem confete, sem brilho de
"prêmio", pulo pequeno só em `victory`. **Quando** cada estado dispara continua sendo decisão do app
(`MascotController` / `PetMessageCatalog`) — a regra do D-007 vale lá: `celebrate`/`victory` só para
progresso educacional, nunca por valorização, dividendo, aporte ou trade.

## Verificação com o runtime oficial

`harness/main.cpp` carrega o `.riv` com o runtime C++ oficial (`rive-app/rive-runtime`), dirige a
state machine por comandos e grava cada `drawImage`; `preview.py` recompõe os quadros em GIFs e numa
folha de contato (`build/rive_pet/preview/`), e confere: poses estáticas não se movem com
`reducedMotion`, o medalhão pulsa com `interacting`, e a ordem de desenho.

```bash
git clone --depth 1 https://github.com/rive-app/rive-runtime /tmp/rive-runtime
cd /tmp/rive-runtime && for f in $(find src -name '*.cpp'); do
  g++ -std=c++17 -O1 -w -Iinclude -D_RIVE_INTERNAL_ -DYOGA_EXPORT= -c $f -o /tmp/rr_$(echo $f | tr / _).o; done
g++ -std=c++17 -O1 -w -Iinclude -D_RIVE_INTERNAL_ -c utils/no_op_factory.cpp -o /tmp/rr_noop.o
g++ -std=c++17 -O1 -w -Iinclude -D_RIVE_INTERNAL_ -c <repo>/tools/rive_pet/harness/main.cpp -o /tmp/rr_main.o
g++ -o <repo>/build/rive_pet/harness /tmp/rr_*.o -lpthread
python3 tools/rive_pet/preview.py
```

Os type/property keys usados foram conferidos contra o runtime Dart legado `rive 0.13.20` (o que o
app usa): todos existem com os mesmos números.

## Limitações

- A arte de origem tem só 331×434 px e corta as patas na base; gere uma versão ≥1024 px de corpo
  inteiro e reexecute os dois scripts para a qualidade final.
- O `.riv` é gerado por código, não pelo editor do Rive. O arquivo `WolfCompanion-v1` no Rive tem as
  mesmas camadas para ajustes visuais, mas mudanças lá não voltam para cá automaticamente.
