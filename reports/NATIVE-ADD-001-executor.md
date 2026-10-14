# NATIVE-ADD-001 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-ADD-001`; ветка `task/NATIVE-ADD-001`; **starting SHA `661d3a1c14a9fa23d4f2bab695bf1170fa65e5c5`** (assignment HEAD, дерево чистое). База принятого продукта `28aa41f9048991e6b2aafb571767e1aba6590c28` (UI-MODE принят), `git merge-base --is-ancestor` в рамках линейной истории — 28aa41f в списке recent commits до 661d3a1.
- Прочитаны AGENTS.md, ARCHITECTURE.md (контракты core), tasks/NATIVE-ADD-001.md. Старые assignments не выполнялись.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift` | `addTask(title:now:)` расширен до `addTask(title:now:plannedDate: String? = nil)` — backwards-compatible, все существующие вызовы title/now работают без изменений. Порядок: сначала `TaskTitle.validated`, затем `TaskPlannedDate.isValid` (невалидная строка → прежний `TaskPlannedDateError.invalid`) — ОБЕ проверки до `context.insert`/мутаций/save. `OrbitTask` создаётся сразу с нормализованным title и переданной validated civil date: один UUID/`createdAt` (из `now`), `completedAt`/`plannedTime`/`durationMinutes` = nil. Ровно один explicit `context.save()` с существующим `rollback()` + rethrow при failure. Никакого второго task/`setPlannedDate`-прохода, никаких новых валидаторов/дефолтов today/timezone/Calendar/полей; nil — прежняя undated семантика (текущий локальный день вычислит UI в ADD002). |
| `apple/Orbit/Tests/OrbitCoreTests/OrbitTaskStoreTests.swift` | +5 тестов в существующий suite `OrbitTaskStore` (группа после addTask-тестов, стиль/TempDir прежние): ① dated create — точные normalized title/`createdAt`/`plannedDate`, id единственный, completion/time/duration nil, ровно одна строка; ② implicit-default и explicit-nil — прежняя undated семантика; ③ disk reopen на том же URL — тот же UUID + дата + title/createdAt, completion/time/duration nil; ④ invalid date (`2026-13-40` → `TaskPlannedDateError.invalid`) — новая строка не появляется, существующая не меняется, valid dated retry проходит; ⑤ invalid title при переданной дате (`TaskTitleError.empty`) — аналогично, retry проходит. |

Model/schema/UI/IOSInboxModel/macOS/UI-MODE/rootdocs/test framework не менялись. Кнопка/форма не делались (ADD002 после приёмки).

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter OrbitTaskStore` (в `apple/Orbit`, scratch-path — собственный `TempDir.make()` из TestSupport: уникальные /tmp-каталоги на тест) | **exit 0 — «Test run with 30 tests in 1 suite passed after 0.166 seconds»** (25 прежних + 5 новых). Строки `CoreData: error … invalid file name` в логе — ожидаемый шум намеренного негативного теста «failed open throws and creates no store» (существовал и раньше), сам тест зелёный. |
| `xcodebuild … -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-add001-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | **BUILD SUCCEEDED** (exit 0) |
| Full core suite / web / db / auth / GUI / device | НЕ запускались по TASK (schema/UI не менялись; targeted checks зелёные без лишних повторов) |

## Ограничения / честные границы

- Runtime save-failure путь (ошибка самого `context.save()`) не покрыт fault injection — framework для этого запрещён TASK; атомарность до save обеспечена конструкцией (обе валидации до insert, один explicit save, существующий rollback), тесты проверяют конечные состояния, а не сам save-failure. Это отражено и в TASK (пункт 3).
- `Duration`/`plannedTime` при создании всегда nil по контракту TASK; интервал назначается существующим `setPlannedInterval` отдельным принятым путём.
- Реальный iPhone/tёмная тема — вне scope этого core TASK.

## Гигиена

- Обычный scoped commit; `git diff --check` чисто; дерево чистое; без merge/push/amend/rebase/reset/stash/clean/deploy; main/чужие worktrees/outputs/hooks/настройки/xcode-select/signing не трогались. Own DerivedData `/tmp/orbit-add001-dd` удалён; пользовательские store-файлы не открывались (только temp-каталоги тестов).
- ADD002 («+»/форма на экранах, вычисление текущего локального дня в UI) не начинался. Stop: Codex review.

## Git

- Ветка `task/NATIVE-ADD-001`; start `661d3a1c14a9fa23d4f2bab695bf1170fa65e5c5`; полный SHA итогового коммита — в чате.
