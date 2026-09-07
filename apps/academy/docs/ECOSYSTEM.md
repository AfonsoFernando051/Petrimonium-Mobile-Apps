# Papel no ecossistema — Petrimonium Academy

## Responsabilidade do produto

Academy responde: **eu entendo o que estou fazendo?** É o produto educacional
do ecossistema, com currículo progressivo, lições, perguntas, revisão,
recomendações, Financial Lab, carteira simulada, XP e progressão do Pet.

Todo dinheiro apresentado como prática é fictício e deve permanecer marcado
como simulação. Academy nunca consome patrimônio real do Wallet nem fluxo de
caixa do Health.

## O que atravessa o ecossistema

Identidade, Pet, XP/nível e Mentor são integrados pelo backend. Isso não torna
conteúdo, progresso de tela ou dados financeiros compartilhados entre apps. O
contrato canônico de claims, rotas e isolamento está em
[`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../Petrimonium-Backend/docs/INTEGRATION.md).

Fatos do cliente:

| Fato | Estado atual |
| --- | --- |
| `app_context` | `academy`, fixo em `ApiConstants.appContext` |
| Dinheiro | Somente simulado em `/api/v1/simulated-portfolios/**` |
| Currículo | Backend-authoritative; JSON e IDs vivem no backend |
| XP | Produzido por eventos de aprendizado/prática permitidos pelo backend |
| Packages compartilhados | UI, infraestrutura Flutter e gamificação |
| Navegação atual | Home, Academy, carteira simulada e Mentor |

## Regras que este app protege

- Aprendizado é o centro; gamificação e Pet sustentam o processo.
- Nível/XP é progressão motivacional, não certificação financeira.
- Erro de quiz ensina; não pune, remove XP ou envergonha.
- Simulação nunca parece dinheiro real.
- Pet não reage a lucro, preço, patrimônio ou transação.
- Mentor explica e contextualiza; não recomenda compra/venda/alocação.

## Origem e dívida conhecida

Academy e Wallet descendem do antigo app combinado `Invest-Game-V2`. Isso
explica árvores semelhantes e alguns vestígios de features com nomes de
portfólio dentro da Academy. A origem comum não autoriza copiar mudanças sem
comparar implementações nem transforma código morto/histórico em contrato.

O contexto atual do monorepo está em
[`../../../docs/PROJECT_CONTEXT.md`](../../../docs/PROJECT_CONTEXT.md); a
arquitetura do Academy está em [`ACADEMY_ENGINE.md`](ACADEMY_ENGINE.md).
