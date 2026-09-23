# Integração do Academy

Auditoria de 23/09/2026. Escopo: percursos do Academy e APIs que os sustentam.

## O que cada camada comprova

| Suíte | Integração exercitada | Limite |
| --- | --- | --- |
| Backend `AuthEndToEndFlowTest` | Cadastro, login, JWT por produto, refresh e logout via HTTP e banco | H2; sem login Google real |
| Backend `AcademyJourneyIntegrationTest` | HTTP → segurança JWT → casos de uso → persistência H2 | Apenas a porta externa de cotações é simulada |
| Mobile `integration_test/app_test.dart` | Navegação real, telas, controllers e armazenamento local, executados no Linux | Repositórios remotos substituídos; não conecta ao backend real |
| Testes de controllers e adapters | Contratos HTTP e persistência isolados | Não substituem os percursos acima |

## Cobertura acrescentada

No backend, seis cenários cobrem:

- Catálogo semeado → conclusão de aula → releitura do progresso; repetição sem duplicação, aula inexistente e isolamento entre alunos.
- Conclusão de simulador, repetição e isolamento por conta.
- Brasil obrigatório no Academy, preservando a preferência dos outros produtos.
- Compra, reenvio da mesma ordem, venda, rejeição de venda acima do saldo e reset confirmado; outra conta permanece intacta.
- Compra histórica com preço da data; cotação ausente ou fictícia não grava ordem nem posição.
- Tokens Wallet e Health não acessam as rotas exclusivas do Academy.

No aplicativo, três novos percursos cobrem:

- Aula iniciada na Home → conclusão → botão de retorno abre a aba Academia → progresso permanece após remontar o app.
- Falha de rede durante a conclusão → progresso local preservado → sincronização pendente recuperada ao reabrir.
- Resposta errada → instrução para corrigir → resposta certa libera conclusão, sem registrar a tentativa como perfeita.

Os cinco testes anteriores foram preservados. A preparação agora limpa as preferências entre cenários, fornece o estado atual da Home e impede chamadas acidentais à carteira remota. A navegação usa o componente atual da trilha.

## Executar

Na raiz de `Petrimonium-Backend`:

```sh
./mvnw -Dtest=AuthEndToEndFlowTest,AcademyJourneyIntegrationTest test
./mvnw test
```

Na raiz de `petrimonium-mobile`:

```sh
melos exec --scope=petrimonium_academy -- flutter test --concurrency=1
bash tooling/check_dependency_direction.sh
bash tooling/check_layering.sh
```

Em `apps/academy`, com as dependências Linux descritas em `.github/workflows/academy.yml`:

```sh
xvfb-run -a flutter test -d linux integration_test
flutter analyze
```

A suíte comum `flutter test` não inclui automaticamente `integration_test`. O CI já tem um job separado para esses percursos; a classe Java usa o sufixo `Test` e entra na execução Maven normal.

## Limites da verificação

Não é uma certificação de todas as funcionalidades. Permanecem fora desses percursos: app conectado a um backend real com PostgreSQL, dispositivos Android/iOS, login Google, serviços de cotação reais e os oito passos completos de onboarding em uma única sessão. Os passos de onboarding têm testes de widgets, mas o percurso de cadastro integrado existente começa com as etapas anteriores já concluídas.
