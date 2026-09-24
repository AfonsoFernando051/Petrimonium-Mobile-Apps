# O que o render do lobo deitado precisa ter

Briefing para gerar a arte de origem da pose `sleep` deitada do lobo. Cada
exigência abaixo veio de um defeito real: ou medido nas fatias atuais do lobo,
ou reparado à mão no rig do cão (`output/pet_wake_rig_v3/RECONSTRUCTION.md`).
Não são preferências de estilo.

## Por que a arte atual não serve

`apps/academy/assets/images/generated_wolf.png` é um lobo **sentado, de frente**,
331×434. Deformar não resolve: a fatia `wolf_torso.png` tem coleira, medalhão,
as duas patas dianteiras e a ponta do rabo **pintados dentro**, e torso, pernas
e anca foram cortados contra as camadas vizinhas — 8,6% a 14,4% do perímetro de
cada retângulo é pixel opaco, ou seja, borda reta que aparece assim que a peça
sai do lugar. A cabeça é a única fatia limpa (0,0%).

## Exigências

1. **≥1024 px, corpo inteiro, nada cortado nas bordas.** A arte atual corta as
   patas na base do quadro; isso já limita o render de hoje e não tem conserto
   a jusante.
2. **Fundo transparente de verdade** (alfa, não branco/cinza chapado). Todo o
   fatiamento depende do alfa.
3. **Nenhuma sombra projetada de uma peça sobre outra.** No cão, a sombra do
   medalhão ficou pintada na pata e teve que ser removida com uma faixa de
   reconstrução — senão ela viaja junto com a pata quando o medalhão se move.
4. **Peças articuláveis com sobreposição mínima.** O medalhão não deve cobrir a
   pata; a coleira não deve sumir sob o queixo; o rabo não deve encostar no
   quadril. Cada sobreposição vira superfície oculta a reconstruir.
5. **Mesmo personagem**: lobo prateado chibi, acentos azuis brilhantes (losango
   na testa, marcas nas bochechas, fios no rabo), coleira azul-escura com
   medalhão redondo. Mesmo render 3D macio, mesma luz, mesmas proporções.
6. **Pose**: deitado de barriga, levemente encolhido, cabeça apoiada nas patas
   dianteiras cruzadas, olhos fechados em curva suave, orelhas relaxadas e
   caídas, rabo enrolado ao lado do corpo, perna traseira dobrada sob o corpo.
   Vista 3/4 lateral, virado levemente para a esquerda. Sombra de contato suave
   apenas, sem chão.

## Gere DOIS arquivos, não um

O cão precisou de uma segunda imagem como **doador de textura oculta**: o corpo
sem cabeça, orelhas, coleira e medalhão, revelando peito e pescoço contínuos por
baixo. Sem ela, o tronco fica com um buraco onde a cabeça estava, e a cabeça não
pode levantar. Gerar as duas de uma vez evita um ciclo inteiro de ida e volta.

O doador precisa ser **o mesmo enquadramento, mesma escala, sem centralizar o
que sobrou** — ele é registrado pixel a pixel contra o original, e só as regiões
sem pixel na peça recebem a textura dele. Os RGB originais visíveis são
restaurados por cima.

## Depois que os PNGs existirem

1. `sudo apt install python3-opencv` (ou `python3.13-venv` + pip) — o slicer usa
   `cv2.inpaint`/`dilate`/`blur`; numpy e Pillow já estão no sistema.
2. Fatiamento + reconstrução de oclusão, no método do cão: máscaras
   determinísticas, doador só onde falta pixel, RGB visível preservado, teste
   automático de preservação.
3. Rig e animações em RML (`build_wolf_rml.py`), não montagem à mão no editor —
   ver `RML.md`. O `rive push` leva tudo editável para o editor.
