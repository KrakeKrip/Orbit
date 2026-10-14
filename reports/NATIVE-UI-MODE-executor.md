# NATIVE-UI-MODE — отчёт исполнителя (GLM)

## Статус

R1 READY_FOR_REVIEW (независимый Codex review — следующая стадия). Исходный R0-отчёт сохранён ниже без изменений как история.

## R1 — коррекция NEEDS_FIXES (2026-10-14, задачи reports/NATIVE-UI-MODE.md + tasks/NATIVE-UI-MODE-R1.md)

**Честное признание по R0:** общий `NativeModeHeader` реально использовался только двумя списковыми экранами; календари рисовали собственные HStack-композиции, а главный критерий (одинаковая ФИЗИЧЕСКАЯ позиция контрола при переключении вида) выполнен не был — списки имели inline navigation title над header, пустой navigation bar календаря схлопывался, и контрол «прыгал» на высоту бара (~44pt), в Upcoming дополнительно отличался inset. Это зафиксировано review R1 [P2] и подтверждено моими же ui-01…ui-04.

**Исправление (минимальное, без новых компонентов):**

| Файл | Изменение |
| --- | --- |
| `TodayScreen.swift` | По прямому уточнению пользователя: navigation title «Сегодня» и область под ним убраны полностью; `.toolbar(.hidden, for: .navigationBar)`. Mode-строка — первая строка прямо под safe area. Локальная дата списка («14 окт. 2026 г.») сохранена; имя нижней вкладки не менялось (OrbitIOSApp не тронут). |
| `UpcomingListScreen.swift` | Та же политика no-title/no-bar — иначе в Upcoming остался бы тот же прыжок (title был только в списке). Date controls/контекстная «Сегодня»/callbacks не менялись. |
| `CalendarDayScreen.swift` | `.toolbar(.hidden, for: .navigationBar)` вместо схлопывающегося пустого бара. `dayControls` больше не добавляет внешнюю band-обёртку: fixed-day и browsing ветки ведут с общего `NativeModeHeader` (fixed-day: trailing = caption + «⋯»; browsing: `browsingModeHeader` = `NativeModeHeader` с `UpcomingModeSwitcher` + «⋯», ниже отдельная band дата-строки — зеркально списку Upcoming). Удалены устаревшие `modeControl`/`browsingTopRow`/`browsingModeControl`; двойные paddings вокруг mode row устранены (у каждого ряда ровно один padding, insets из `NativeModeHeader`). ViewThatFits-адаптив «Сегодня»/caption сохранён в прежней форме. |
| `NativeModeHeader.swift` | Только комментарий (теперь реально все 4 вида, trailing-использование календарями). Код не менялся. |

README сознательно НЕ правился (не в scope R1): секции Today/Upcoming описывают «inline-заголовок» — устарело, отметить при следующем docs-проходе.

**Проверки:** один build own DerivedData `/tmp/orbit-uimode-r1-dd` (DEVELOPER_DIR, CODE_SIGNING_ALLOWED=NO) — **BUILD SUCCEEDED**. Свой simulator `orbit-r1` (iPhone 17 Pro / iOS 27.0, удалён). Fixture — задача создана самим app GUI (композер Инбокса → меню строки → «Дата…» → «Сохранить», draft = сегодня), без прямых записей store. Orca/CUA недоступен — CGEvent-инструменты (одноразовые, удалены), зеркало Device Hub (та же калибровка origin 686.5/213.5, scale 0.7388/0.742, подтверждена сканом окна). Скриншоты — нативные `simctl io screenshot`.

**Objective evidence позиции (пиксельный скан capсулы переключателя на device screenshots 3x):**

| Скриншот | capsule px | device pt |
| --- | --- | --- |
| `r1-01-today-list.png` | y 228…318, x 52…524 | y 76…108, x 17.3…174.7 |
| `r1-02-today-calendar.png` | y 228…318, x 52…524 | y 76…108, x 17.3…174.7 |
| `r1-03-upcoming-list.png` | y 228…, x 52…530 | y 76…, x 17.3… |
| `r1-04-upcoming-calendar.png` | y 228…, x 52…530 | y 76…, x 17.3… |

Top-edge переключателя идентичен во всех четырёх видах (в R0 разница составляла ~127px ≈ 44pt). В R0-отчёте размещение описывалось как «same relative content-row» — это была ошибка формулировки: фактическая позиция зависела от navigation bar; теперь подтверждено абсолютными пикселями, а не заявлением.

**GUI-последовательность (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-UI-MODE/`, одно устройство/размер/шрифт):** Today List (`r1-01`) → «Календарь» (`r1-02`, caption+«⋯» trailing, карточка и ruler на месте) → вкладка «Предстоящее» (`r1-03`, mode row + дата-строка) → «Календарь» (`r1-04`, тот же контрол + «⋯», дата-строка в той же позиции) → смена вкладки сохраняет mode (`r1-05`: «Сегодня» остался в Календаре) → возврат в List обоих разделов (`r1-06`, `r1-07`) → AX smoke `accessibility-large` (`r1-08`: header не обрезан, date controls помещаются), content size возвращён на `large` (проверено `simctl ui … content_size`).

**State:** workspace @State mode/day не менялись; на экране один Picker на раздел; без nested NavigationStack; sheets работают (date sheet открыт в ходе GUI-прогона). Контекстная «Сегодня» в Upcoming не менялась (день = сегодня — скрыта, как и в базе).

**UNVERIFIED (честно):** реальный iPhone, тёмная тема, RTL, VoiceOver-прогон; Dynamic Type — только одна точка accessibility-large на шапке Upcoming list; поведение при скролле списков (навбар скрыт, панель остаётся топ-строкой — скролл-состояние не снималось отдельно). CUA/AX-дерево недоступно — доступность по скриншотам.

**Гигиена:** обычный scoped commit; `git diff --check` чисто; дерево чистое; без merge/push/amend/rebase/reset/stash/clean/deploy; main/чужие worktrees/hooks/xcode-select/signing/настройки/системные часы не трогались. Собственные ресурсы удалены (simulator/derived data/CGEvent-инструменты/пробы), Device Hub закрыт. Жесты/Projects/3days/Month/AI не начинались.

**Git R1:** код — `a9a46316a58dcdeee19c6efc5f1ac5366aa9fc5b`; отчёт — см. чат. Старт R1 `449c8134f2a2fb521e8087b2fe6a409cd6728c6b`, исходный executor HEAD `f3b9ce957d2b640db26f7685707f6f882ff825a6`.

---

# Исходный R0-отчёт (история, 2026-10-14)

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
