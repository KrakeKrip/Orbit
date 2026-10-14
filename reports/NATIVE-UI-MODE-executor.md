# NATIVE-UI-MODE — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-UI-MODE`; ветка `task/NATIVE-UI-MODE`; **starting SHA `51c5d64a34dfab063a7aa9f9bb2ebdd458eec2ea`** (assignment HEAD, дерево чистое). База реализации `e4f304e3d5a133108bf5c870855d7d43f5e4c9dc` — принят TIME-WHEEL, `git merge-base --is-ancestor` подтверждён.
- Прочитаны AGENTS.md, DESIGN.md (разделы 71 «commonheader» и 77 «doublecontour» про будущий NATIVE-UI-MODE), tasks/NATIVE-UI-MODE.md. Старые assignments не выполнялись.
- Фактическая причина doublecontour подтверждена по source: в обоих list-экранах `TodayModeSwitcher`/`UpcomingModeSwitcher` сидели как `ToolbarItem(placement: .navigationBarTrailing)` (обёртка тулбара вокруг segmented `Picker`), а в календарях переключатель был отдельным inline `Picker` в контентной строке (`browsingModeControl` дублировал `UpcomingModeSwitcher` 1:1, включая identifier). Это inference из кода, подтверждённая скриншотами базы в принятых отчётах NAV-001/002.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/NativeModeHeader.swift` | НОВЫЙ маленький общий файл (единственный разрешённый): `NativeModeHeader<Switcher, Trailing>` — одна общая композиция верхней mode-строки: существующий segmented switcher раздела ведущим, `Spacer(minLength: 8)`, опциональный trailing, insets `.horizontal 8 / .vertical 6`, фон `.bar`; convenience-init с `Trailing == EmptyView` для списков (без fake-контента). Никакой capsules/rounded stroke/material ПОВЕРХ native segmented control — один контур. |
| `apple/OrbitIOS/OrbitIOS/TodayScreen.swift` | Удалён `.toolbar { ToolbarItem(…Trailing) … }` (источник list-only обёртки). Первой строкой content-VStack — `NativeModeHeader(switcher: TodayModeSwitcher(…))` при non-nil `todayMode` (та же привязка workspace-состояния). Заголовок `.large` → `.inline`, чтобы позиция mode-строки не зависела от высоты заголовка (large title разрешено было оставить, но тогда переключатель «прыгал» бы между large-title-сдвигом и топом календаря). Остальное (список, ошибки, empty, sheets) не тронуто. |
| `apple/OrbitIOS/OrbitIOS/UpcomingListScreen.swift` | Симметрично: `NativeModeHeader(switcher: UpcomingModeSwitcher(…))` первой строкой перед существующими `dateControls`; `.toolbar` удалён; заголовок `.inline`. Date controls/«Сегодня»/окно/группировки не менялись. |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | Только дедупликация: `browsingModeControl` вместо inline-копии `Picker` использует существующий `UpcomingModeSwitcher` (один контрол на раздел, по-прежнему identifier `upcoming-mode-switcher`). Fixed-day ветка уже использовала `TodayModeSwitcher` — не менялась. Структура строк/ViewThatFits/caption/⋯ меню не тронуты. |
| `apple/OrbitIOS/README.md` | Соответствующие секции: TodayScreen/UpcomingListScreen (новое размещение, inline-заголовок) + новый пункт `NativeModeHeader.swift`. |

Не менялись: TodayWorkspaceScreen/UpcomingWorkspaceScreen (mode/day owners, таймеры, `TodayModeSwitcher`/`UpcomingModeSwitcher` — оба остались в использовании), core/store/grid/list rows/editors/OrbitIOSApp/вкладки/targets/root docs/tests. Nested NavigationStacks не создавались, sheet presentation не затронута (все 4 экрана открывали date/interval sheets в GUI-прогоне). `TodayScreen.todayMode == nil` — прежний standalone-фоллбек (строка просто не добавляется).

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild … -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-uimode-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | **exit 0, BUILD SUCCEEDED** с первого прогона |
| Core 70 tests / web / DB / E2E | НЕ повторялись (core/web не менялись — по TASK) |
| Simulator | свой `orbit-uimode` iPhone 17 Pro / iOS 27.0 (UDID F4044511-…), создан мной, удалён после |
| Fixture | одна задача «Design review» с датой сегодня (14.10.2026) — создана САМИМ app GUI (Inbox composer → меню строки → «Дата…» → «Сохранить», draft = сегодня); без прямых записей в store |

## Инструментальная заметка

Orca/CUA-контроллер в этой сессии недоступен (`orca` не найден), GUI выполнен одноразовыми CGEvent-инструментами (swiftc, клик/клавиши, все удалены). Зеркало — Device Hub (в Xcode 27 нет Simulator.app); маппинг экрана вычислен пиксельным сканом окна и совпал с принятой TIME-WHEEL-сессией (origin 686.5/213.5, scale 0.7388/0.742), подтверждён успешными кликами (сегменты, вкладки, меню, шиты). Скриншоты — нативные `simctl io screenshot`.

## GUI evidence (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-UI-MODE/`)

1. `ui-01-today-list.png` — Today Список: inline-заголовок «Сегодня», mode-строка первой под навбаром, `Список/Календарь` ведущим, один контур, строка задачи ниже.
2. `ui-02-today-calendar.png` — Today Календарь (тот же раздел, тот же контрол): ТО ЖЕ место/размер/инсеты переключателя, trailing — caption «14 окт. 2026 г.» и существующее «⋯» меню; untimed-карточка и ruler не смещают контрол.
3. `ui-03-upcoming-list.png` — Upcoming Список: та же mode-строка (identifier `upcoming-mode-switcher`), под ней прежние date controls `< 14.10.2026 >`; контекстная «Сегодня» скрыта (день = сегодня), caption диапазона и дневная секция с задачей.
4. `ui-04-upcoming-calendar.png` — Upcoming Календарь: тот же переключатель в той же строке (trailing «⋯»), ниже прежние date controls — нет двойного `Picker`, нет toolbar-обёртки.
5. `ui-05-axl-upcoming-calendar.png` — AX-крупный шрифт (`content_size accessibility-large`): контрол доступен/не обрезан, date controls помещаются, ruler читаем; content size возвращён на `large` (проверено `simctl ui … content_size` → `large`).
6. `ui-06-mode-persist-today-calendar.png` — после Список→Календарь→вкладка→вкладка: «Сегодня» остался в Календаре, Upcoming остался в своём Календаре — mode/tab/day state сохраняется, как раньше (workspace @State не менялись).

## Наблюдение (платформенное, не регресс композиции)

У CalendarDayScreen нет navigationTitle, и пустой nav bar платформенно может схлопываться (например, после переключений вкладок/шитов) — вся контентная область вместе с mode-строкой смещается вверх на высоту бара; в свежеоткрытом экране бар развёрнут. Это поведение принятой базы (пустой бар без title), влияет на весь экран одинаково и не зависит от композиции переключателя; в пределах одного экранного состояния List/Calendar строка одинаковая (ведущая, те же insets/высота/стиль). Отмечено честно; исправление (фиксация высоты бара/title) — отдельное решение за пределами этого TASK.

## UNVERIFIED (честно)

- Реальный iPhone, тёмная тема, RTL, VoiceOver-сессия — не проверялись.
- Dynamic Type проверен одной точкой `accessibility-large` на одном экране (Upcoming calendar); остальные AX-размеры и list-экраны на AX — нет.
- Позиция переключателя при прокрутке списка (свёрнутый навбар со scroll) скриншотом не показана — косвенно видна в ui-02/04/06 (схлопнутый бар).
- CUA/AX-дерево недоступно — доступность контролей проверена визуально по скриншотам, VoiceOver-прогоном не подтверждена.

## Ограничения / гигиена

- Обычные scoped коммиты; `git diff --check` чисто; дерево чистое; без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktrees/hooks/xcode-select/signing/настройки не трогались.
- Собственные ресурсы удалены: simulator `orbit-uimode`, derived data `/tmp/orbit-uimode-dd`, CGEvent-инструменты, временные сканы/пробы; Device Hub закрыт. Скриншоты — вне product tree.
- Start wheel 0..59 не трогался; жесты/Projects/3days/Month/AI/other polish не начинались.

## Git

- Ветка `task/NATIVE-UI-MODE`; start `51c5d64a34dfab063a7aa9f9bb2ebdd458eec2ea`; коммит кода — `2c33ac32182a0dd70458409d2d2b1516e1defd6b`; коммит отчёта — см. чат.
