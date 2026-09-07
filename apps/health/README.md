# Petrimonium Health

Aplicativo de saúde financeira: *como está meu mês e quanto ainda terei
disponível depois dos compromissos previstos?* O Health é um produto Flutter
independente dentro do monorepo mobile.

## Documentos

| Documento | Finalidade |
| --- | --- |
| [`../../docs/PRODUCT_VISION.md`](../../docs/PRODUCT_VISION.md) | Visão e limites do ecossistema |
| [`../../docs/MOBILE_ARCHITECTURE.md`](../../docs/MOBILE_ARCHITECTURE.md) | Regras do monorepo e dos packages |
| [`docs/ECOSYSTEM.md`](docs/ECOSYSTEM.md) | Papel atual do Health |
| [`docs/API.md`](docs/API.md) | Contrato HTTP do cliente Health |
| [`docs/FINANCIAL_RULES.md`](docs/FINANCIAL_RULES.md) | Regras monetárias específicas |
| [`../../../Petrimonium-Backend/docs/INTEGRATION.md`](../../../Petrimonium-Backend/docs/INTEGRATION.md) | Contrato canônico de integração e isolamento |

## Escopo atual

Contas, receitas, despesas, transferências, recorrências, cartões, faturas e
projeção mensal são persistidos no backend compartilhado. Não há integração
bancária, câmbio ou conversão automática nesta versão.

País (`BR`/`PT`), moeda (`BRL`/`EUR`) e idioma (`pt-BR`/`pt-PT`) são escolhas
explícitas e independentes. O backend grava a moeda nos dados financeiros e a
bloqueia após a existência de dados; o aplicativo nunca converte um valor
apenas trocando o símbolo.

## Executar

Com o backend local em `http://localhost:8081`:

```bash
cd apps/health
flutter pub get
flutter gen-l10n
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8081
```

No emulador Android, use `http://10.0.2.2:8081`.

Verificação:

```bash
flutter gen-l10n
flutter analyze
flutter test
```

## Produto e arquitetura

- Dart package: `petrimonium_health`
- Identificador nativo atual: `com.petrimonium.petrimonium_health`
- Backend context: `health` (fixo, não é flavor)
- Contexto financeiro: fluxo de caixa real

O Health nasceu com arquitetura, tema, rede e localização próprios e ainda não
depende dos packages compartilhados do monorepo. Uma futura adoção deve ser
incremental e baseada em uma abstração realmente comum aos três produtos, sem
forçar o Health ao formato histórico de Academy/Wallet.
