# NATIVE-ADD-002 — отчёт исполнителя (GLM)

## Статус

**READY_FOR_REVIEW** (остановка до Codex review). Один UI-результат: общая коралловая «+» и один create sheet на Inbox/Today/Upcoming в обоих видах; нижний Inbox composer удалён; спокойные empty states Сегодня.

## Назначение и база

- TASK: `tasks/NATIVE-ADD-002.md`; worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-ADD-002`; ветка `task/NATIVE-ADD-002`.
- Starting SHA назначения `5a209af59c4a8756baf99fe8fd7bba7e94bf9b35` — проверены root/branch/HEAD/clean status перед изменениями (head совпал, дерево чистое).
- База продукта 7c543fe7f459a6721338b4033243f43257e6bd35 (принятый ADD-001) — ancestor по истории ветки.
- Прочитаны AGENTS.md, DESIGN.md, tasks/NATIVE-ADD-002.md.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/TaskCreatePresentation.swift` | НОВЫЙ (единственный разрешённый): `OrbitCreateButton` — коралловый круг «+» (visual 56pt, hit ≥44pt, a11y label «Добавить задачу», identifier `create-task-fab`, скромная тень без glass-имитации); `orbitCreateAction(model:datePreset:)` — host-модификатор: кнопка живёт в реальном bottom safe area (`.safeAreaInset(edge: .bottom)` c zero-height spacer + overlay trailing/bottom 16pt) — всегда НАД native tab bar, без UIScreen/координат устройства; sheet через item-based presentation (каждое открытие — новый identity, черновик локален и уничтожается при закрытии). `TaskCreateSheet`: поле названия, видимый контекст «Дата: …»/«Без даты» (ru_RU форматирование через существующий `RussianDateCaption`), явные «Добавить»/«Отмена», keyboard submit (`.submitLabel(.done)` + `onSubmit`), авто-фокус поля. Ошибка title/store видима В ФОРМЕ (`create-error`), черновик сохраняется, retry работает; sheet закрывается только после подтверждённого успеха; guard `created` исключает дубль при повторном submit. preset фиксируется хостом в момент тапа (`datePreset()` вызывается при открытии). |
| `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift` | Добавлена `create(title:plannedDate:) -> String?` — один save через принятый `addTask(title:plannedDate:)` (никакого create→setPlannedDate); success: `writeError = nil` + общий reload, return nil (последующий read failure остаётся listError, не подменяет успех записи); failure: reload до persisted truth + пользовательское сообщение из `IOSInboxFormatting.addMessage` для sheet. `draft`/`addFromDraft()` удалены — использовались только удалённым composer (grep по iOS+core; Mac `InboxModel` — отдельный класс, не затронут). |
| `apple/OrbitIOS/OrbitIOS/InboxScreen.swift` | Composer, его `safeAreaInset`, `FocusState`, `submitDraft`/`isDraftBlank` удалены. Баннер `writeError` перенесён НАД контентом (перед списком/empty/error-view, identifier `inbox-write-error`) — не внутри modal sheet. Empty copy: «Нажмите «+», чтобы добавить первую задачу.» Host: `.orbitCreateAction(model:, datePreset: { nil })`. |
| `apple/OrbitIOS/OrbitIOS/TodayWorkspaceScreen.swift` | Host `.orbitCreateAction(model:, datePreset: { TaskDaySelection.currentDay() })` — актуальный local Gregorian today в МОМЕНТ открытия, не stale `currentDay` воркспейса. Один host на оба вида (List/Calendar получают ту же composition). `onGoToInbox` удалён. |
| `apple/OrbitIOS/OrbitIOS/UpcomingWorkspaceScreen.swift` | Host `.orbitCreateAction(model:, datePreset: { selectedDay })` — существующий владелец выбора, второй selectedDay/state owner не заводился; создание не сбрасывает selection/mode. |
| `apple/OrbitIOS/OrbitIOS/TodayScreen.swift` | `onGoToInbox` и действие «Добавить во Входящих» удалены. Empty state: «На сегодня всё» + «Можно отдохнуть — или добавить новые планы.», локальная дата сохранена. Условие empty не менялось: день только с completed остаётся списком («Завершённые» не подменяется empty state). |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | Только Today (fixed-day) контекст: при действительно пустой проекции (`timedSegments.isEmpty && untimedTaskIDs.isEmpty`) — компактная спокойная подпись «На сегодня всё» / «Можно отдохнуть — или добавить новые планы.» над ЦЕЛОЙ сеткой (grid/«⋯»/«+» доступны); browsing (Upcoming) контекст подпись не получает. Positive overnight continuation — реальный сегмент проекции (accepted core), такой день пустым не считается (гарантировано самой проверкой проекции). |
| `apple/OrbitIOS/OrbitIOS/OrbitIOSApp.swift` | Только удаление ставшего ненужным callback «Добавить во Входящих» (`TodayWorkspaceScreen(model:)` без trailing closure); tab ownership не перестраивался. |

Не менялись: OrbitCore (schema/store/tests), grid/rows/editors (`TaskDateSheet`/`TaskIntervalSheet`/`DayTimelineView`/`CompactCalendarTaskRow`), `NativeModeHeader`, mode switchers, `UpcomingListScreen.swift` (не в scope TASK), root docs, web.

## Проверки (фактические)

| Проверка | Результат |
| --- | --- |
| `xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-add002-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR=/Applications/Xcode.app) | **BUILD SUCCEEDED** (exit 0), один прогон, own DerivedData, не удалял до конца сессии |
| `git diff --check` | чисто; дерево после коммитов чистое |
| GUI-проход на СВОЁМ simulator `orbit-add002` (iPhone 17 / iOS 27.0, создан и удалён; app store — собственный sandbox контейнер приложения, чужие данные не затрагивались) | см. ниже |

### GUI-последовательность (evidence `/Users/atlhnv/Codex/orbit-outputs/NATIVE-ADD-002/`, screenshots — нативные `simctl io screenshot`, устройство 393×852pt)

1. `e01-today-list-empty-fab.png` — пустой Today List: «На сегодня всё» / «Можно отдохнуть — или добавить новые планы.», локальная дата, БЕЗ действия переключения таба, коралловый «+» справа внизу НАД tab bar. Позиция FAB по пиксельному скану device screenshot: box 990…1156 × 2158…2324 px (÷3.07) ⇒ visual ⌀≈54pt (56pt с AA), отступ справа ≈16pt, над tab bar — совпадает с реализацией; позиция идентична до и после sheet (стабильна).
2. `e02-today-calendar-empty-caption.png` — Today Calendar пустой: компактная подпись (тот же текст) над целой сеткой (hour ruler/линии на месте), «Без времени — нет задач», «+» присутствует; никакого «Добавить во Входящих».
3. `e03-create-sheet-today-filled.png` — sheet из Today List: «Новая задача», «Дата: 14 окт. 2026 г.» (preset = актуальный today в момент открытия), пустое поле → «Добавить» ОТКЛЮЧЁН (blank refusal, также через keyboard submit — ничего не создаёт).
4. `e04-today-list-one-task.png` — после ввода названия и KEYBOARD SUBMIT (Return): sheet закрылся, задача в «Открытые». Persisted store (sqlite копия из контейнера приложения): `Plan na segments | 2026-10-14 | NULL time/duration/completed | UUID 6849C123-…` — атомарный dated create, один UUID.
5. Кнопка «Добавить»: отдельная задача «Add button task» создана ТАПОМ по кнопке (после коммита текста) — store `2026-10-14`; `e05-today-list-after-add-button.png`.
6. Cancel-путь: sheet с черновиком закрыт «Отменой» — store count не изменился (1). Swipe-down путь: sheet с черновиком закрыт свайпом за grabber — store count не изменился. Никаких вставок.
7. `e06-inbox-empty-no-composer.png` / `e08-inbox-with-undated-task.png` — Входящие: composer снизу ОТСУТСТВУЕТ; создание через «+»: sheet показывает «Без даты», созданная задача ВИДИМА В СПИСКЕ БЕЗ подписи даты; store `plannedDate = NULL`.
8. `e09-create-sheet-upcoming-otherday.png` — Предстоящее: Next-day → selected 15.10; sheet показывает «Дата: 15 окт. 2026 г.»; вид «Список» и вкладка не сброшены; contextual «Сегодня» появился (selected ≠ today).
9. `e10-upcoming-list-otherday-task.png` — после создания задача в группе «15 окт. 2026 г.»; store `Sastra plan | 2026-10-15`; selected day/mode не сброшены.
10. `e11-upcoming-calendar-fab.png` — вид «Календарь» Предстоящего: selected 15.10.2026 СОХРАНЁН при смене вида, «+» на месте (5-е представление), задача «Без времени» = тот же source UUID.
11. `e12-relaunch-persistence.png` — `simctl terminate` + `launch` (новый PID): все 4 задачи на месте; Today показывает ровно 2 задачи 2026-10-14; store: `2026-10-14 ×2, 2026-10-15, NULL`.
12. `e13-ax-create-sheet.png` — AX smoke: `content_size accessibility-medium` — FAB на той же позиции (safe area), create sheet читаем, поля/кнопки крупные и работоспособные, Return-submit создал задачу (store count +1); размер возвращён в `large` (проверено `simctl ui … content_size` → `large`).
13. `e14-today-calendar-after-create.png` — создание ПРЯМО из вида Today→Календарь: store `Calendar create check | 2026-10-14`, untimed-чипы сетки обновились, подпись пустого дня исчезла (день больше не пуст) — корректно.

Инструментальная заметка: Orca/CUA недоступен; GUI выполнен одноразовыми CGEvent-инструментами (swiftc, клик/drag/клавиши/пиксельный скан, все удалены) через зеркало Device Hub с двухточечной калибровкой (FAB + выбранная таб-иконка; scale ≈1.52/1.50 px/pt, подтверждена успешными кликами). Ввод кириллицы синтетикой недоступен (симулятор игнорирует unicode-string события; смену layout делать нельзя) — названия задач в прогоне латиницей; весь остальной UI на русском. Замечание по процессу: симулятор авто-локнулся на idle (после разблокировки клики восстановились); DeviceHub требует переактивации окна перед пакетами кликов.

## UNVERIFIED / ограничения

- Реальное устройство, VoiceOver-прогон, тёмная тема, RTL — не проверялись (как и в предыдущих native TASK).
- Runtime disk failure при создании: без поддерживаемого fault framework не симулировался (разрешено TASK как UNVERIFIED); код-путь ошибки (сообщение в форме + сохранение черновика + retry) реализован, его UI-поведение подтверждено только на success-путях и на blank/title-refusal ветке.
- Пустой Inbox empty state («Нажмите «+»…») не демонстрировался скриншотом: требовал бы пустого store, а удаление задач вне scope; изменение копии верифицируется кодом.
- Тап-доставка синтетических кликов в зеркале была нестабильна (фокус окна/auto-lock) — это артефакт инструментальной среды, не приложения; каждый шаг подтверждён screenshot'ом устройства и/или store-проверкой.
- `UpcomingListScreen.emptyView` по-прежнему упоминает «добавьте задачу во Входящих» — файл вне scope TASK; отмечено для следующего docs/UI-прохода.
- Динамический тип свыше accessibility-medium, портал/Stage Manager, двойной поворот — не прогонялись.

## Гигиена

- Обычные scoped commits (2 кодовых + отчёт); без merge/push/amend/rebase/reset/stash/clean/deploy; main и чужие worktrees не трогались; xcode-select/signing/AppleID/hooks/system settings не менялись (в т.ч. input source Макa).
- Собственные ресурсы удалены: simulator `orbit-add002` (shutdown+delete), DerivedData `/tmp/orbit-add002-dd`, CGEvent-инструменты `/tmp/orbit-add002-tools`. Файлы store копировались только из контейнера СВОЕГО приложения во временный каталог.
- Projects/rename/delete/export/deviceQA/drag/resize/3days/Month/AI не начинались.

## Git

- Код: `3787000…` (shared create sheet + model create) и `1952b85…` (section host + empty states) — полные SHA в чате; база `5a209af59c4a8756baf99fe8fd7bba7e94bf9b35`.
- Отчёт: финальный commit этой ветки (SHA в чате).
