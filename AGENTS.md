# petrimonium-mobile — guia para Codex/Claude

Complementa [`/AGENTS.md`](../AGENTS.md) (leia-o primeiro) com o que só faz
sentido aqui: workspace Melos 6 com três apps Flutter independentes
(Academy, Wallet, Health) e três pacotes compartilhados. Leia
[`docs/MOBILE_ARCHITECTURE.md`](docs/MOBILE_ARCHITECTURE.md) antes de tocar
em `packages/` — ele carrega a regra que decide o que é compartilhado.

## Regra de dependência — checada por script, não por convenção

```
apps/academy ─┐
apps/wallet  ─┼──> petrimonium_shared_features ──> petrimonium_flutter_core
apps/health  ─┘                                └──> petrimonium_ui
```

- Nenhum pacote em `packages/` pode importar um app.
- Nenhum app pode importar outro app.
- Sem dependências circulares.

`tooling/check_dependency_direction.sh` e `tooling/check_layering.sh`
conferem isso, e rodam **sem filtro de path** em CI
(`.github/workflows/architecture.yml`) deliberadamente: uma mudança
só-em-app já quebrou essa checagem no passado ao não disparar um workflow
filtrado por `packages/**`. Se você tocar `apps/**`, rode esses dois
scripts localmente antes de terminar.

## Estrutura de uma feature

```
lib/features/<feature>/
├── domain/{entities,services}        # zero import de Flutter, zero import de data/
├── data/{datasources,repositories}
└── presentation/{controllers,screens,widgets}
```

`tooling/check_layering.sh` confere que nada em `domain/` importa widgets
Flutter ou a camada `data` (o analisador do Dart não expressa "não pode
importar deste diretório").

Nem toda feature tem hoje uma abstração de repositório em
`domain/repositories/` — `mentor`, `auth`, `onboarding` e `settings` usam
uma implementação concreta direto em `data/repositories/`.
`features/pet/domain/repositories/pet_repository.dart` (com
`pet_repository_impl.dart` em `data/`) é o padrão de referência quando a
feature precisa de um limite testável (um fake em vez de mockar a chamada
HTTP). Para features novas com lógica de domínio real, prefira esse padrão
abstrato; não é obrigatório reintroduzi-lo em toda feature existente só por
consistência.

## Gerência de estado

`ChangeNotifier` com o repositório injetado via construtor — não Bloc, não
Riverpod. Padrão:

```dart
class MentorChatController extends ChangeNotifier {
  MentorChatController({required MentorChatRepository repository})
      : _repository = repository;
  // ... notifyListeners() após cada mutação de estado
}
```

Siga esse padrão para controllers novos; não introduza um gerenciador de
estado diferente numa feature sem alinhar antes — seria uma mudança de
convenção do workspace inteiro, não uma aplicação local.

## DRY entre os três apps — a pergunta certa antes de extrair

Antes de mover algo para `packages/`, responda: *"se eu consertar ou
melhorar isto aqui, Academy, Wallet **e** Health deveriam receber a
mudança?"* Se sim, é candidato forte a pacote compartilhado. Se não, fica
no app — **dois códigos parecidos não são resposta**: Academy e Wallet
nasceram do mesmo fork, então boa parte do código idêntico existe por
razão histórica, não porque é genuinamente a mesma coisa. Ver
`docs/MOBILE_ARCHITECTURE.md`, seção "What is deliberately still
duplicated".

Também deliberado: cada app resolve e trava suas próprias dependências
(Melos 6, não 7/8/workspaces do Dart) — não proponha unificar
`pubspec.lock`/versões entre os três só para reduzir duplicação; isso
acopla ciclos de release que devem ficar independentes (ver comentário no
topo de `melos.yaml`).

## Testes

`flutter_test` + `mocktail` (não `mockito`). `test/` espelha `lib/`
arquivo por arquivo — um teste novo vai no caminho espelhado, não solto em
outro lugar. Sem golden tests hoje; não introduza sem alinhar antes, é
mudança de convenção.

## Lint e formatação

`analysis_options.yaml` na raiz é o único baseline (estende
`flutter_lints`) — não duplique uma regra já ligada lá em um
`analysis_options.yaml` de app/pacote; adicione ali só o que for
genuinamente local a esse app/pacote. `dart format --line-length 120`
antes de qualquer diff pronto — CI falha com `--set-exit-if-changed` se o
código não estiver formatado.

## Antes de considerar qualquer tarefa concluída

```
melos run verify   # analyze + test em tudo — o mínimo antes de terminar
```

Para escopo isolado a um pacote/app:
`melos exec --scope=<nome> -- flutter test`. Se tocou `packages/**` ou
`apps/**`, rode também `tooling/check_dependency_direction.sh` e
`tooling/check_layering.sh`.
