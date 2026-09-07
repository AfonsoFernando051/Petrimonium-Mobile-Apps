# Petrimonium — product vision

## Document role

This is the source of truth for what the Petrimonium mobile ecosystem is and
why its three products exist. Architecture and feature documents must remain
consistent with it.

Petrimonium is not one financial super-app. It is an ecosystem of three
separate products used by the same person:

| Product | Question it answers | Financial context |
| --- | --- | --- |
| **Health** | How is my month, and what remains after known commitments? | Real cash flow |
| **Wallet** | How is my patrimony, and what is it doing? | Real investments |
| **Academy** | Do I understand what I am doing? | Education and simulated money |

Cash flow comes before patrimony, and education supports both. These are
different user journeys, navigation models and release lines, not tabs of a
single application.

## 2. Shared ecosystem promise

The person should recognize the same Petrimonium identity across all three
products without losing the safety of clear product boundaries. Four concepts
connect the experience through the backend:

1. one account and identity;
2. one Pet identity;
3. one XP/level ledger;
4. one Mentor service with strictly context-specific intelligence.

This does not make financial data shared. Health cash flow, Wallet patrimony
and Academy simulations remain isolated. The canonical enforcement contract is
[`../../Petrimonium-Backend/docs/INTEGRATION.md`](../../Petrimonium-Backend/docs/INTEGRATION.md).

## 3. Petrimonium Academy

Academy is learning-first:

> **Learn -> Practice -> Progress -> Grow**

It provides a structured curriculum, short interactive lessons, supportive
quizzes, simulations, review and contextual tutoring. XP and Pet progression
make learning visible and emotionally engaging; they are not proof of
financial competence.

Academy uses only fictitious money. Every simulation must remain clearly and
persistently identified as simulated. Real holdings, bank balances and Health
cash flow do not belong in an Academy session.

## 4. Petrimonium Wallet

Wallet helps a person organize, monitor and understand real investment
patrimony. Its value is clarity, trust and educational interpretation — not
trading excitement.

Wallet is not a broker, does not execute orders and does not turn returns,
dividends, deposits or portfolio size into rewards. Market movement can be
explained, but never celebrated or punished by the Pet.

## 5. Petrimonium Health

Health helps a person understand real day-to-day cash flow: accounts, income,
expenses, transfers, recurrence, cards, invoices and monthly projection.

Health is not a bank, does not connect to banks in the current product scope
and does not infer that investment patrimony is available monthly cash. Country,
currency and language are explicit choices. Changing a currency symbol is not
currency conversion.

## 6. Pet identity and progression

The visible Pet is the person's companion across the ecosystem. Internally,
keep three concepts separate:

```text
Mentor intelligence  — backend-owned reasoning and safety
Pet identity         — backend-owned species, name and shared state
Pet experience       — Flutter presentation, reactions and animation adapters
```

The Pet represents identity, learning and approved behavior. It never dies,
degrades, shames a wrong answer or reacts to wealth and financial outcomes.
Species is a personal identity choice, never a risk-profile classification.

## 7. Mentor

The Mentor is a contextual education and reflection tool. It may explain a
concept, help review a mistake, clarify a metric or turn context into a useful
question. It must not act as a licensed adviser, predict prices, guarantee
returns or issue deterministic instructions such as "buy", "sell" or "put
70% here".

The backend decides what context a Mentor conversation may access. The mobile
apps present the conversation, disclose why a suggestion appears and preserve
the distinction between educational explanation and financial advice.

## 8. Experience hierarchy

Each product's Home surface answers its primary question before secondary
signals. Academy shows the next learning action and progress before simulated
portfolio detail; Wallet shows understandable patrimony context without
manufactured urgency; Health shows the month's cash-flow picture and next
useful action. The Pet supports that hierarchy rather than competing with it.

## 9. Knowledge progress versus game level

Knowledge progress measures curriculum completion/mastery. XP level is a
motivational progression shared with the Pet. A high game level is not proof,
certification or advice about financial competence. Product copy and Mentor
responses must keep the two concepts distinct.

## 10. Learn-to-practice connection

Academy concepts may help a person interpret a simulated exercise or, through
a deliberately designed product bridge, understand a Wallet/Health concept.
The bridge carries educational meaning, never trusted financial values or
authorization. Each destination fetches its own allowed data.

## 11. Financial safety boundary

Petrimonium provides education, organization, tracking and simulation. It does
not execute investments or payments, issue trading signals, guarantee returns
or act as an autonomous adviser. Financial outcomes never become XP or Pet
reward signals.

## Product and design principles

- Make the next meaningful action clear; avoid competing primary actions.
- Prefer calm, trustworthy interpretation over urgency and spectacle.
- Treat mistakes as learning opportunities, never punishment.
- Keep progress legible: knowledge progress is different from XP level.
- Use the companion to support the task, not to obscure it.
- Preserve accessibility, reduced motion and readable contrast.
- Add features only when they strengthen understanding, organization,
  reflection, progression or long-term trust.

## Explicit non-goals

Without a new reviewed product and legal decision, Petrimonium is not:

- a bank or payment processor;
- a brokerage or order-execution platform;
- a source of trading signals or guaranteed returns;
- an autonomous investment adviser;
- a mechanism that rewards wealth, profit or risky behavior.

## Guiding question

> Does this help the person understand or organize their financial life while
> preserving product boundaries and avoiding unhealthy financial incentives?
