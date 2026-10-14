# NATIVE-NAV-001 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-NAV-001`; ветка `task/NATIVE-NAV-001`; **starting SHA `c454d98b5d7346ab96377b1a1577df098c94c7b3`** (coordinator HEAD, `git rev-parse` совпал); дерево чистое, чужих изменений нет. База реализации `b5608d1eaace8f4d8793c5eff36ed4caa1bc0e23` — accepted NATIVE-007C, `git merge-base --is-ancestor` подтверждён.
- Прочитаны AGENTS.md, PRODUCT.md (уточнение навигации 2026-10-14: Сегодня · Входящие · Предстоящее, без вкладки «Календарь», переключатель Список/Календарь внутри раздела), ARCHITECTURE.md (Navigation/view separation 2026-10-14), DESIGN.md (лайн 55: Calendar — ВИД, не bottom tab) и `tasks/NATIVE-NAV-001.md`. Старые 007C corrections не выполнялись.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/TodayWorkspaceScreen.swift` | НОВЫЙ (разрешён единственный новый локальный файл): контейнер раздела «Сегодня» — единственный owner текущего локального дня (`TaskDaySelection.currentDay()`, refresh on appear / scene active / Timer 30s; при смене дня `model.reload()`, день уходит ВХОДОМ в оба вида) + `@State showsCalendar` (initial list; presentation-состояние, живёт в TabView-иерархии → сохраняется при Today→Входящие→Today в сессии; никогда не пишет). Композиция `if showsCalendar { CalendarDayScreen(fixedDay:…) } else { TodayScreen(day:…) }` — siblings, каждый со своим существующим NavigationStack → nested NavigationStack НЕ создаётся. Там же `TodayModeSwitcher` — компактный segmented Picker «Список/Календарь» (`fixedSize`, `minHeight 44`, identifier `today-mode-switcher`, AX label «Вид»). |
| `apple/OrbitIOS/OrbitIOS/TodayScreen.swift` | только current-day input/header: `let day: String` вместо внутреннего clock/timer/scenePhase-состояния (owner перенесён в workspace; `onAppear reload` оставлен), `var todayMode: Binding<Bool>? = nil` + `.toolbar { ToolbarItem(.navigationBarTrailing) { TodayModeSwitcher } }`. List/секции/empty/error/writeError/sheets не переписывались; retry → `model.reload()`. |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | только композиция/header: новые входы `var fixedDay: String? = nil`, `var todayMode: Binding<Bool>? = nil` (memberwise defaults — browsing-инициализация `CalendarDayScreen(model:)` не сломана, NAV002 её переиспользует). `fixedDay != nil` → шапка `fixedDayControls` (ViewThatFits: русский caption дня через `InboxRowView.dateLabel` + switcher + существующий «⋯» «Задачи дня»; БЕЗ Prev/Next/picker/«Сегодня»); `applyFixedDay()` on appear/onChange(fixedDay) синхронизирует `selectedDay` (валидация через `TaskPlannedDate.isValid`, смена дня идёт через существующий `onChange(selectedDay)` → collapse-контракт сохранён). Date-browser (`browserDayControls`) в browsing-контексте прежний. Grid/untimed/cards/toggle/menu/sheets не менялись. |
| `apple/OrbitIOS/OrbitIOS/OrbitIOSApp.swift` | удалены `Tab.calendar` и вкладка «Календарь»; tabs — Сегодня (по умолчанию, теперь `TodayWorkspaceScreen`) и Входящие. Фейковый Upcoming не создавался, Calendar не переименован. |
| `apple/OrbitIOS/README.md` | секции Today/Calendar/структура под NAV-001. |
| `reports/NATIVE-NAV-001-executor.md` | этот отчёт. |

Не менялись: InboxScreen/InboxRowView, CompactCalendarTaskRow, DayTimelineView, editors, core/model/store/projector, tests, Xcode project (новый файл подхвачен синхронизированной группой), root docs, web.

## Поведение (сверка с пунктами TASK)

1. Самостоятельной вкладки «Календарь» нет (case + tabItem удалены); Today/Inbox — реальные tabs, default Today; никакого Upcoming-подменного таба.
2. «Список / Календарь» — segmented с очевидным selected; reuse готовых view; mode — presentation state, TabView сохраняет его через переходы; switch не создаёт/не мигрирует задачи.
3. Calendar в Today = текущий локальный день (вход `fixedDay`); date browser скрыт; дата видима по-русски рядом с mode control и «⋯»; large title «Календарь» не возвращался; list — прежние большие строки, calendar — принятая 007C-геометрия.
4. Один current-day owner — workspace (appear/active/30s, accepted `TaskDaySelection`, system timezone, без custom clock); оба вида получают день входом; List membership по plannedDate не менялся; overnight segments — по принятой проекции; `listError`/`writeError` видны в обоих видах (общая модель, no silent clear).
5. CalendarDayScreen reuse без поломки browsing-контекста (дефолтный init прежний); второго grid/редактора/рендерера нет; nested NavigationStack нет (siblings); source UUID callbacks сохранены; empty list → «Добавить во Входящих» прежний, calendar empty честный.
6. Mode control — одна компактная строка/toolbar item, `minHeight 44`, identifier + AX label; card geometry/left expand icon/ellipsis/24h/lanes не менялись.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild … -derivedDataPath /tmp/orbit-nav1-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | после фикса placement (`.topbarTrailing` отсутствует в iOS-17 baseline SDK → `.navigationBarTrailing`) — exit 0, **BUILD SUCCEEDED**; первый прогон с ошибкой задокументирован выше |
| Core/web/full/legacy | НЕ повторялись (core не менялся) |
| Fixture | временный генератор на OrbitCore (`swift build`+`swiftc`, Package.swift не менял): today=2026-10-14 — 3 untimed open («Сегодня 1–3») + 1 untimed **completed** («Сегодня выполненная») + timed 09:00/60 + tiny 11:05/5; **yesterday** «Вчера», **tomorrow** «Завтра», undated «Без даты»; 9 задач; store в песочницу до первого launch; генератор удалён |
| Simulator | свой `orbit-nav1-gui` iPhone 17 Pro / iOS 27.0 UDID 9F5A3390-0FA9-4A3E-A0D7-90DBCB3D42B6, создан/deleted мной |
| Ввод | Device Hub: AX-клики + координатные (сегменты switcher) |

## GUI evidence реального запуска (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-NAV-001/`)

1. `01-today-list.png` — Today list: bottom nav ТОЛЬКО «Сегодня/Входящие» (нет «Календарь»), switcher «Список/Календарь» в nav bar (Список выбран), «Открытые»: Сегодня 1–3, С временем 09:00, Мини 11:05; «Завершённые»: Сегодня выполненная; **Вчера/Завтра/Без даты отсутствуют**.
2. `02-today-calendar.png` — после tap «Календарь»: fixed-day календарь — шапка [Список/Календарь (выбран) | 14 Oct 2026 | ⋯] **без Prev/Next/picker/«Сегодня»**; untimed-карточки Сегодня 1–3 + «Ещё 1» + gutter-chevron; сетка с блоком 09:00–10:00 и tiny 11:05; тот же UUID-набор.
3. `03-mode-kept-after-inbox.png` — Today → Входящие → Today: режим КАЛЕНДАРЬ сохранён (AX: «Меню календаря», тот же fixed-day заголовок).
4. `04-dynamic-type-axl.png` — accessibility-extra-large: switcher доступен в nav bar, large title/список масштабируются, все строки/кнопки в AX; размер возвращён на `large`.

Тот же source UUID через оба вида: complete «Сегодня 1» кругом в calendar (AX «Снова открыть: Сегодня 1», карточка muted) → switch Список: задача в «Завершённые» (AX подтверждён) → reopen в списке → снова open. Date editor: «Дата задачи: Сегодня 2» → sheet «Дата задачи» → «Отмена» — без записи. **sqlite readonly до/после** (`store-before.txt`/`store-after.txt`): 9 строк идентичны fixture (complete был возвращён reopen, Cancel не пишет, переключения видов/табов/AXL не пишут).

## UNVERIFIED (честно)

- Реальная смена system time/timezone в runtime не имитировалась (system settings не трогались): midnight-refresh проверен source-уровнем (owner `refreshDay` + `onChange(fixedDay)` → `applyFixedDay`; оба вида получают день входом) — сам переход через полночь в GUI не показан.
- Timer 30s — source + принятая механика прежнего TodayScreen; отдельного 60s-ожидания в GUI не делалось.
- Внутренний scroll expanded-untimed, grid-offset на прокрученной сетке, long-press — как в 007C UNVERIFIED (pan/long-press зеркалом не доставляются; этот код не менялся).
- Реальный iPhone, тёмная тема, RTL, VoiceOver-сессия, SE-класс/landscape — не проверялись.

## Ограничения / гигиена

- Обычные scoped коммиты (один); `git diff --check` чисто; без merge/push/amend/rebase/reset/stash/deploy.
- main/чужие worktrees/CRM/порт 3000/hooks/xcode-select/signing/Apple ID/system settings не трогались; content size возвращён на large.
- Cleanup: свой simulator удалён, `/tmp/orbit-nav1-*` удалены, Device Hub закрыт; чужие outputs не тронуты.
- Stop: Codex review; NAV002/MIN5/drag/resize/3-дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-NAV-001`; start `c454d98b5d7346ab96377b1a1577df098c94c7b3`; полный SHA итогового коммита — в чате.
