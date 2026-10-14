# NATIVE-MIN5 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-MIN5`; ветка `task/NATIVE-MIN5`; **starting SHA `96bef46e1d0217edbff40d359b55503f3960b107`** (assignment HEAD, дерево чистое). База реализации `12fbee7dc651128fa1aa829570180f15c2cd92be` — принят LIST001, `git merge-base --is-ancestor` подтверждён.
- Прочитаны AGENTS.md, ARCHITECTURE.md (раздел «Назначенный NATIVE-MIN5: write minimum vs legacy read»), tasks/NATIVE-MIN5.md. Старые corrections не выполнялись.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/TaskTimeInterval.swift` | новый явно названный write-минимум `minimumWritableDurationMinutes = 5` + `isWritableDuration(_:)` (целые минуты 5…1440, без округления/clamp). `minimumDurationMinutes = 1` СОХРАНЁН как read-граница; `isValidDuration` (1…1440) не изменён — комментарии/docs явно разделяют read-compatibility (legacy 1…4 остаются читаемыми) и write rule. |
| `apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift` | только `setPlannedInterval`: дополнительный precheck `isWritableDuration` ПОСЛЕ read-валидации и ДО любых property mutations/fetch/save; ошибка та же `invalidDuration`. nil/nil clear не затронут; setPlannedDate/setCompleted/tasks не менялись. |
| `apple/Orbit/Tests/OrbitCoreTests/TaskTimeIntervalTests.swift` | новый тест write gate: 5/6/7/30/1440 допустимы (минимум ≠ кратность 5), 1/4/0/-5/1441/Int.max отвергаются; read-совместимость 1…4 сохраняется, `end` с duration 1 работает. Прежние read-тесты (`isValidDuration(1)`) НЕ ослаблены. |
| `apple/Orbit/Tests/OrbitCoreTests/OrbitTaskStoreTests.swift` | (+import SwiftData) два новых теста: (1) store-записи 1/2/3/4/0 reject ДО мутации — сохранённая пара и disk reopen не изменины; 5/6/7 accept; clear работает; (2) legacy-фикстура 1 и 4 минуты создаётся через SwiftData model в изолированном test context (БЕЗ нового store-API bypass), reopen текущим core показывает исходные значения, `end`/`TaskDayProjector` дают positive segments, новый write на legacy-строку reject и ничего не меняет, legacy date move/complete/clear работают штатно и не стирают интервал. |
| `apple/OrbitIOS/OrbitIOS/TaskIntervalSheet.swift` | только footer hint: диапазон из core-констант (`minimumWritableDurationMinutes`…`maximumDurationMinutes`) — «от 5 до 1 440». |
| `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift` | только caption `invalidDuration`: «…целое число минут от 5 до 1440» из тех же core-констант (без дублирования констант). |

Не менялись: OrbitTask/schema/setPlannedDate/TaskPlannedDate/projector, CompactCalendarTaskRow/CalendarDayScreen/DayTimeline/Workspace/mode controls, editors layout, nav, Projects/macOS/web/targets/root docs.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift test` (apple/Orbit, полный native package) | **exit 0: 70 тестов / 8 сюит passed, 0 failed** (было 67 — добавлены 3 targeted теста). Прежние pure-read boundary тесты сохранены без ослабления. |
| `xcodebuild … -derivedDataPath /tmp/orbit-min5-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | **exit 0, BUILD SUCCEEDED** |
| Core/web/DB/auth/E2E/full suites, legacy migration harness | НЕ повторялись / не создавались (по TASK) |
| Fixture | временный генератор (вне дерева, удалён): «С временем 60» (today, 09:00/60 — через store API) + «Легаси 1 минута» (today, 10:00/1 — через SwiftData model, т.к. write API корректно отвергает 1) |
| Simulator | свой `orbit-min5-gui` iPhone 17 Pro / iOS 27.0 UDID 68A7F4EA-…-0922, создан/удалён мной |

## GUI evidence (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-MIN5/`)

1. Legacy read в реальном GUI: строка «Легаси 1 минута» отображалась с derived end «10:00–10:01» (не скрыта, не перезаписана) — видно в `min5-01…03` и подтверждено финальным store-дампом (duration 1, UUID 715c922b-…).
2. Editor из body-меню показывает фактические сохранённые значения и НОВЫЙ hint: `min5-editor.png`/`min5-01-duration4-reject.png` — «…длительность — целое число минут от 5 до 1 440…» (константы из core), Начало 09:00, Длительность = persisted value; UI не молча исправляет stored 1/460 при открытии.
3. Легитимный Save через существующий editor: duration 60→460 (валидное ≥5 значение) сохранился с тем же UUID 03e6bb22-… (store: ZDURATIONMINUTES 60→460, Z_OPT 3→4, plannedTime/date не тронуты), строка мгновенно обновилась до «09:00–16:40», значение пережило relaunch (`min5-03-relaunch-persisted.png`).
4. Финальный store-диф: РОВНО одна строка изменена («С временем 60» duration+Z_OPT); legacy-строка байт-в-байт идентична; никаких других записей.

## GUI-сценарий «4 → reject, → 5 accept»: UNVERIFIED-GUI (по прямому указанию пользователя)

Пользователь прервал GUI-прогон: «Забей на клавиатуру тут, все равно ща менять будем на крутилку» — ввод duration «4»/«5» в текстовое поле через synth-клики прекращён. Покрытие перенесено на уровень, где правило живёт: swift test store-тесты `writeMinimumRejectsBelowFive` (1/2/3/4/0 reject до мутации + disk reopen unchanged) и `legacyShortDurationsRemainReadable`. GUI-фактами подтверждены: editor/hint с новым диапазоном, отображение persisted значения без автокоррекции, легитимный valid Save с persistence. Попутная инструментальная пометка: при первом открытии editor курсор встал в начало поля, из-за чего синтетический ввод дал «460» вместо «4» — поведение самого приложения корректное (460 — валидное значение), это ограничение tooling, не кода.

## UNVERIFIED (честно)

- GUI-отображение ошибки invalidDuration (сценарий reject) — не показано (см. выше); текст ошибки и hint проверены source-level и hint виден на скриншотах.
- Midnight/runtime-переход, реальный iPhone, тёмная тема, VoiceOver — не проверялись.
- macOS target (OrbitMac) собран transitively при `swift build`, отдельного GUI-прогона macOS не было (core-правило общее, тесты общие).

## Ограничения / гигиена

- Обычный scoped commit; `git diff --check` чисто; дерево чистое; без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktrees/хранилища/hooks/xcode-select/signing/настройки не трогались; content size `large`; свой simulator/temp/tools удалены.
- Stop: независимый Codex review; Projects/commonheader/drag/resize/3дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-MIN5`; start `96bef46e1d0217edbff40d359b55503f3960b107`; полный SHA итогового коммита — в чате.
