# Papel no ecossistema — Petrimonium Wallet

## Responsabilidade do produto

Wallet responde: **como está meu patrimônio e o que ele está fazendo?** É o
produto de organização, monitoramento e interpretação de investimentos reais.
Não é corretora, não executa ordens e não transforma oscilação de mercado em
recompensa.

Wallet não lê o fluxo de caixa do Health como saldo investível e não apresenta
a carteira simulada da Academy como patrimônio real.

## O que atravessa o ecossistema

Identidade, Pet, XP/nível e Mentor são integrados pelo backend. Isso não torna
dados financeiros compartilhados entre apps. O contrato canônico de claims,
rotas e isolamento está em
[`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../Petrimonium-Backend/docs/INTEGRATION.md).

Fatos do cliente:

| Fato | Estado atual |
| --- | --- |
| `app_context` | `wallet`, fixo em `ApiConstants.appContext` |
| Dinheiro | Patrimônio real em rotas exclusivas do Wallet |
| Execução | Não executa compra/venda; acompanha dados informados/sincronizados |
| XP | Lê o ledger compartilhado; resultado financeiro não concede XP |
| Packages compartilhados | UI, infraestrutura Flutter e gamificação |
| Navegação atual | Home/portfólio, Proventos quando aplicável e Mentor |

## Regras que este app protege

- Perda/ganho é informação, não urgência ou espetáculo.
- Aporte, lucro, dividendo, trade e tamanho do patrimônio não geram XP nem
  celebração do Pet.
- O Mentor pode explicar métricas e riscos, mas não emitir instruções
  determinísticas.
- Dados reais ficam no contexto Wallet; nenhum atalho de deep link ou estado
  local contorna o backend.

## Origem e dívida conhecida

Wallet e Academy descendem do antigo app combinado `Invest-Game-V2`. Ainda há
estruturas semelhantes e alguns modelos educacionais usados para interpretação
de indicadores. Compare usos reais antes de remover ou extrair: um nome
"Academy" no Wallet pode ser um vestígio morto ou uma ponte educacional válida.

Não existe deep link operacional entre os apps hoje. CTAs entre produtos devem
ficar explicitamente indisponíveis ou degradar com segurança até existir uma
integração de sistema operacional e fallback de loja.

### Referência histórica "Stage 5"

Alguns comentários importados ainda citam o antigo `ECOSYSTEM.md` "Stage 5".
Essa referência significa a separação do shell Wallet: remoção da aba Academy
e do onboarding educacional do fluxo Wallet, deixando apenas pontes
educacionais deliberadas. É contexto histórico, não uma etapa futura ativa.

O contexto atual do monorepo está em
[`../../../docs/PROJECT_CONTEXT.md`](../../../docs/PROJECT_CONTEXT.md) e as
regras de compartilhamento em
[`../../../docs/MOBILE_ARCHITECTURE.md`](../../../docs/MOBILE_ARCHITECTURE.md).
