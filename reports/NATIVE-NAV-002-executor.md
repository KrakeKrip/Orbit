# NATIVE-NAV-002 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-NAV-002`; ветка `task/NATIVE-NAV-002`; **starting SHA `6442000f8e0097bcf3ea9cce5c4e2b6151664756`** (совпал с assignment HEAD), дерево чистое, чужих изменений нет. База реализации `be6d6abbffeefe9fc76a8fa2cbc43fb3bec86cec` — принятый NAV001.
- Прочитаны AGENTS.md, PRODUCT.md (маршрут Сегодня · Входящие · Предстоящее, отдельной вкладки «Календарь» нет), ARCHITECTURE.md (Bottom sections Today/Inbox/Upcoming, Calendar — вид, не section), DESIGN.md (навигация 2026-10-14) и `tasks/NATIVE-NAV-002.md`. Старые corrections (007C и др.) не выполнялись.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/UpcomingWorkspaceScreen.swift` | НОВЫЙ: контейнер «Предстоящее» — единственный owner `@State selectedDay` (старт `TaskDaySelection.currentDay()`, локальный Gregorian today) и `@State showsCalendar` (старт Список). День и вид — presentation-состояние: живут в TabView-иерархии → сохраняются при сменах вкладок и видов в сессии, НЕ пишутся в tasks/store/UserDefaults, независимы от Today; appear-reload модели их не сбрасывает. Композиция sibling-экранов `if showsCalendar { CalendarDayScreen(todayMode:, browsingDay:) } else { UpcomingListScreen(...) }` — nested NavigationStack нет. Там же `UpcomingModeSwitcher` (segmented, identifier `upcoming-mode-switcher`). |
| `apple/OrbitIOS/OrbitIOS/UpcomingListScreen.swift` | НОВЫЙ: список «Предстоящее» — inclusive-окно 7 дней от выбранного дня (`windowDays`: +1 день только через `TaskPlannedDate` Gregorian/noon-адаптеры с явным `gregorianNoon`-календарём; кандидат добавляется только если `isValid` → окно обрезается на 2199-12-31, дня за диапазоном не существует; ≤7 элементов, Range-конструкций нет). Группы `TaskDaySelection.tasks(onDay:)` по valid plannedDate; пустые дневные секции скрыты; большие существующие `InboxRowView`, open+completed в своей группе в порядке модели (новых list-правил нет); UUID без дублей (ForEach по source-задачам). Large title «Предстоящее», switcher в nav bar, компактные date controls (Prev/Next/picker с ru_RU locale и границами 1900–2199/«Сегодня» — пересчёт current day в момент нажатия) под шапкой, ViewThatFits-перенос на узких ширинах. Empty: «В выбранном диапазоне задач нет» + фактический диапазон, контролы доступны. `listError`/`writeError` видны (identifier `upcoming-write-error`), те же date/interval sheets. Пикер следует за внешним днём (onAppear/onChange, no-op-guard). |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | только additive browsing input/mode/caption: новый вход `var browsingDay: Binding<String>? = nil` (browsing-контекст «Предстоящего»); `@State selectedDay` → `localSelectedDay` + вычислимый `selectedDay` (binding ?? local) — экран никогда не держит второго owner дня; `select()` пишет через binding (write-through), `applyFixedDay()` трогает только local (fixed-контекст не изменился); пикер следует за показанным днём (`syncPicker`, записи равного Date — no-op → feedback loop невозможен; повторный `select` из onChange пикера идемпотентен). В browsing-шапку добавлен compact segmented switcher (identifier `upcoming-mode-switcher`, сегодня TodayModeSwitcher не тронут — `today-mode-switcher` остался в fixed-day). fixedDayCaption → `RussianDateCaption.label`. Grid/untimed/toggle/menu/sheets/Prev/Next/picker/«Сегодня» не переписывались; browsing-init без browsingDay прежний. В конце файла `RussianDateCaption` — маленький view-local ru_RU/Gregorian DateFormatter (medium) для section-подписей; системная locale не меняется, `InboxRowView.dateLabel` не тронут. |
| `apple/OrbitIOS/OrbitIOS/TodayScreen.swift` | только P3 follow-up: `dateCaption` = `RussianDateCaption.label(day)` вместо системной `InboxRowView.dateLabel` (убран английский «Oct» из Today-подписи). List/empty/error/sheets не менялись. |
| `apple/OrbitIOS/OrbitIOS/OrbitIOSApp.swift` | третья реальная вкладка: `case upcoming` + `UpcomingWorkspaceScreen(model:)` с tabItem «Предстоящее» (calendar icon), tag. Defaulttab остался Сегодня. Никакого самостоятельного «Календарь»/фейкового плейсхолдера. |
| `apple/OrbitIOS/README.md` | структура под NAV002: два новых файла, browsing-контекст CalendarDayScreen (внешний owner), русские captions. |

Не менялись: IOSInboxModel/IOSStore, InboxScreen/InboxRowView/CompletionButton, CompactCalendarTaskRow, DayTimelineView, editors (TaskDateSheet/TaskIntervalSheet), TodayWorkspaceScreen, core/model/store/projector/tests, Xcode project (новые файлы подхвачены synchronized group), root docs, web, macOS.

## Поведение (сверка с пунктами TASK)

1. Три нижние вкладки Сегодня (default) / Входящие / Предстоящее; отдельного «Календарь» нет; Upcoming — реальный экран (список из больших существующих строк + accepted DayCalendar), не переименованный Calendar и не placeholder; один shared `IOSInboxModel`/store.
2. Upcoming владеет selected civil day (старт — локальный today) и mode (старт Список) независимо от Today; состояние сессионное (по контракту не персистится); appear/active reload не сбрасывает ручной выбор; «Сегодня» пересчитывает current day в момент нажатия.
3. Список: окно 7 дней inclusive от выбранного дня по возрастанию; группы по plannedDate, строки `InboxRowView`; open/completed остаются (не фильтруются); undated/вне окна исключены; верхняя граница — окно физически не может содержать день невалиднее 2199-12-31 (каждый следующий день проходит `TaskPlannedDate.isValid`), caption показывает фактический диапазон; day arithmetic — только принятые Gregorian/noon-адаптеры с явным календарём.
4. Empty окно честное, контролы доступны; в непустом окне только непустые секции + диапазон в caption; reorder/создание/overdue не добавлены.
5. Календарь: accepted `CalendarDayScreen` в browsing-контексте показывает выбранный день; Prev/Next/picker/«Сегодня» меняют owner selection через binding; выбранная дата сохраняется при смене mode (Calendar D → List окно D..D+6; List picker D → Calendar D); за 1900–2199 выход заблокирован теми же guard'ами; сетка/untimed/menu/UUID-callbacks переиспользованы, core не менялся (carry-over проекция остаётся как принята).
6. Компактные нативные List/Calendar selector + date controls в обоих видах; no large «Календарь» title; nested NavigationStack нет; `CalendarDayScreen` принял маленький внешний binding без поломки fixed-day Today (дефолты прежние) и без второго owner; sheets/mutations через существующие callbacks, ошибки модели видны.
7. Section-подписи дат по-русски через view-local ru_RU/Gregorian (`RussianDateCaption`): «14 окт. 2026 г.» в Today (list+calendar caption), в range caption и заголовках секций Upcoming; «Oct» из NAV001 fixedDayCaption/Today dateCaption убран; системные настройки не менялись; `InboxRowView` implementation не менялся (внутристрочные подписи дат остались системными — по условиям TASK).

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild -project OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-nav2-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR=/Applications/Xcode.app/...) | exit 0, **BUILD SUCCEEDED** с первого прогона |
| Core `swift build` (Orbit package) — только для сборки временного fixture-генератора | exit 0; Package.swift/tests не менялись |
| Core/web/full/legacy suites | НЕ повторялись (core/web не менялись — по TASK) |
| Fixture | временный генератор на OrbitCore (`swiftc` + MainActor, вне дерева, удалён): 9 задач — Вчера, Сегодня А/Б, Сегодня с временем 09:00/60, Сегодня выполненная, Плюс 1, Плюс 6, Плюс 7, Без даты; записан в песочницу до первого launch |
| Simulator | свой `orbit-nav2-gui` iPhone 17 Pro / iOS 27.0, UDID 4AB7AE56-7756-4439-8AE7-AFE74EC08078, создан и удалён мной |
| Ввод | Device Hub: AX-клики по элементам зеркала + координатные (tab bar, сегменты switcher, ячейки поповера DatePicker) |

## GUI evidence реального запуска (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-NAV-002/`)

1. `01-today-list-3tabs.png` — Today list: русская дата «14 окт. 2026 г.», большие строки, нижняя навигация из ТРЁХ вкладок Сегодня/Входящие/Предстоящее (Предстоящее с calendar-иконкой, нет вкладки «Календарь»).
2. `02-upcoming-list-initial.png` — Предстоящее, Список: large title, switcher «Список/Календарь» (Список) в nav bar, date controls (‹ 14 окт. 2026 г. › + «Сегодня»), caption «14 окт. 2026 г. – 20 окт. 2026 г.», секции 14 окт (А, Б, с временем, выполненная), 15 окт (Плюс 1), 20 окт (Плюс 6); **Вчера/Плюс 7/Без даты отсутствуют** (AX подтверждает).
3. `03-upcoming-list-plus1-window.png` — после выбора 15 окт в поповере: окно 15–21 окт, секция «21 окт. 2026 г.» с «Плюс 7 дней» появилась, caption обновился (AX: «15 окт. 2026 г. – 21 окт. 2026 г.»).
4. `04-upcoming-calendar-carried-plus1.png` — переключение в Календарь: accepted Day grid, день **15 окт. перенесён из Списка**; browsing-шапка [Список/Календарь (выбран Календарь) | ‹ 15 окт. 2026 г. ›] + «Сегодня» + «⋯» на второй строке (ViewThatFits), untimed-карточка «Плюс 1 день», сетка 00:00–24:00.
5. `05-list-window-carried-16oct.png` — в календаре «Следующий день» → 16 окт, обратно в Список: caption «16 окт. 2026 г. – 22 окт. 2026 г.», только непустые секции 20/21 окт; **день сохраняется при смене mode в обе стороны**.
6. `06-today-calendar-russian-caption.png` — Today в Календаре: fixed-day контекст без browser-контролов, русская дата «14 окт. 2026 г.» рядом со switcher и «⋯» (P3-fix в Today-календаре); при этом Предстоящее осталось в Списке со своим 16 окт — **режимы разделов независимы** (AX: `today-mode-switcher` vs `upcoming-mode-switcher`).
7. `07-empty-window.png` — выбор 6 окт: окно 6–12 окт без задач — «В выбранном диапазоне задач нет» + подсказка, caption диапазона, все контролы доступны.
8. `08-dynamic-type-axl.png` — accessibility-extra-large: заголовок/строки/контролы масштабируются, date controls переносятся («Сегодня» на своей строке), ничего не обрезано; размер возвращён на `large`.

Дополнительные AX-подтверждения (зеркало Device Hub): complete «Плюс 6 дней» в Предстоящем → строка стала «Снова открыть: …»; во Входящих задача исчезла из «Открытые» (между «Плюс 1» и «Плюс 7»), секция «Завершённые» на месте; reopen выполнен там же в Предстоящем (тот же source UUID f56def58…); «Дата задачи: Сегодня А» → sheet «Дата задачи» (wheel 14 October 2026, Сохранить/Отмена/Убрать дату) → «Отмена» — без записи, список не изменился; «Сегодня» из пустого окна вернул окно 14–20 окт.

## Readonly store

`sqlite3 .dump` до GUI-прогона и после всех взаимодействий: **значения задач идентичны** (у «Плюс 6 дней» completedAt вернулся в NULL, дата/UUID/название не тронуты). Ожидаемый дельта-шум SwiftData: Z_OPT строки 7 (2→4 — ровно две целевые записи complete+reopen того же UUID) и служебные ACHANGE/ATRANSACTION-истории. Cancel, переключения вкладок/видов/дат, AXL — записей не создали. Неожиданных записей нет.

## UNVERIFIED (честно)

- **Верхняя граница 2199 в GUI не показана**: компактный DatePicker-поповер не даёт tooling-прыжка на 2199 (навигация по месяцам ≈2000+ кликов, годового jump нет; повторные усилия прекращены по указанию TASK «не тратить часы»). Источник-уровень: `windowDays` начинает с валидного дня и добавляет следующий только при `TaskPlannedDate.isValid`, окно ≤7 дней, Range-конструкций нет → RangeError/день за диапазоном невозможны по построению; Prev/Next guard'аны тем же `shiftedDay`-паттерном, что принят в 007C.
- Внутренний скролл списков/сетки и pan/long-press жесты зеркалом не доставляются: Inbox-строка «Плюс 6 дней» в «Завершённых» визуально не показана (секция и исчезновение из «Открытых» видны, факт завершения подтверждён store-дампом того же UUID); expanded-untimed scroll/long-press — как в 007C/NAV001 UNVERIFIED.
- Случайно открытый при первом запуске interval sheet (открылся сам до любых кликов, «Отмена» была вне видимой зоны half-detent) закрыт перезапуском приложения без записи (подтверждено дампом); после перезапуска Upcoming честно вернулся к today-окну (состояние сессионное по контракту).
- Реальная смена system time/timezone/midnight, реальный iPhone, тёмная тема, RTL, VoiceOver-сессия, SE-класс/landscape — не проверялись.

## Ограничения / гигиена

- Обычные scoped коммиты (код+README; отчёт отдельно); `git diff --check` чисто; без merge/push/amend/rebase/reset/stash/deploy.
- main/чужие worktrees/хранилища/порт 3000/hooks/xcode-select/signing/Apple ID/системные настройки не трогались; content size возвращён на `large`.
- Cleanup: свой simulator удалён, `/tmp/orbit-nav2-*` удалены, Device Hub-сессия управления остановлена; outputs вне дерева (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-NAV-002/`).
- Stop: независимый Codex review; MIN5/drag/resize/3дня/Месяц/AI/macOS/websync не начинались.

## Git

- Ветка `task/NATIVE-NAV-002`; start `6442000f8e0097bcf3ea9cce5c4e2b6151664756`; коммит реализации `38770ec…` (полный SHA — в чате после финального коммита отчёта).
