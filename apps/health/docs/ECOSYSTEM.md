# Papel no ecossistema — Petrimonium Health

## Responsabilidade do produto

Health responde: **como está meu mês e quanto resta depois dos compromissos
conhecidos?** É o produto de fluxo de caixa real: contas, lançamentos,
transferências, recorrências, cartões, faturas e projeção mensal.

Fluxo de caixa não é patrimônio. O app nunca soma investimentos do Wallet ao
saldo disponível nem mistura dinheiro simulado da Academy com dados reais.

## O que atravessa o ecossistema

Identidade, Pet, XP/nível e Mentor são integrados pelo backend. O contrato
canônico de claims, rotas e isolamento está em
[`Petrimonium-Backend/docs/INTEGRATION.md`](../../../../Petrimonium-Backend/docs/INTEGRATION.md).

Fatos do cliente, verificados em 2026-09-07:

| Fato | Estado atual |
| --- | --- |
| `app_context` | `health`, fixo em `ApiConfig.appContext` |
| Rotas financeiras | `/api/v1/health/**`, exclusivas do Health |
| Mentor | Backend possui prompt Health e aceita `APP_CONTEXT_HEALTH` |
| Estado | `HealthController` + `HealthScope` |
| Rede | Implementação local em `lib/core/network/` |
| Tema/localização | Tema próprio e ARB com `gen_l10n` |
| Packages compartilhados | Ainda não consumidos pelo Health |

## Regras que este app protege

- País, moeda e idioma são escolhas independentes e explícitas.
- O símbolo nunca é trocado para simular conversão monetária.
- A moeda fica bloqueada quando já existe dado financeiro, até existir uma
  migração deliberada.
- Investimento não é saldo de conta.
- Valor de fatura, saldo ou sobra do mês não gera XP/celebração do Pet.
- Mentor usa contexto de fluxo de caixa, nunca carteira real do Wallet.

## Arquitetura própria

Health não descende do clone `Invest-Game-V2`. Tema, estado, rede e
localização diferentes são fatos do produto, não inconsistências que precisam
ser apagadas. Uma extração só é válida depois de comparar os três apps e criar
uma configuração que preserve essa experiência.

O contrato HTTP específico permanece em [`API.md`](API.md) e as regras
monetárias em [`FINANCIAL_RULES.md`](FINANCIAL_RULES.md).
