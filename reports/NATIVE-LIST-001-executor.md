# NATIVE-LIST-001 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-LIST-001`; ветка `task/NATIVE-LIST-001`; **starting SHA `7e017ac61dbd0d87a207373bb8d0a2b8145287a5`** (assignment HEAD, дерево чистое). База реализации `8547b026986aa563ef31751521f23587642cb51d` — принятый NAV002, `git merge-base --is-ancestor` подтверждён.
- Прочитаны AGENTS.md (статус NAV002 DONE, назначен LIST-001), PRODUCT.md, DESIGN.md (раздел «Обычные list строки — уточнение 2026-10-14»), tasks/NATIVE-LIST-001.md. Старые corrections не выполнялись.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/InboxScreen.swift` | только shared `InboxRowView` (composer/store/open-state/CompletionButton не менялись): постоянные clock/calendar Button-иконки УДАЛЕНЫ; тело строки (title+метаданные) стало `Menu`-label — компактное native меню «Дата…» → существующий `onEditDate` и «Время и длительность…» → существующий `onEditInterval` (переиспользованы текущие callbacks/sheet presentation, нового save-flow нет). `var showsDateLabel: Bool = true` — presentation-флаг подписи даты (Inbox default true; Today/дневные секции Upcoming передают false). Подпись даты строки теперь `RussianDateCaption.label` (view-local ru_RU; системная locale не менялась); `InboxRowView.dateLabel` СОХРАНЁН — его использует caption в `TaskIntervalSheet` (editor вне scope). Подпись времени start–end/(+1 день) сохранена без изменений (`intervalLabel` не тронут). Undated: «Время и длительность — сначала назначьте дату» disabled до назначения даты, today молча не ставится. Высота ряда: вертикальный padding 6→2 (круг остаётся ≥44pt hit, тело — `frame(minHeight: 44)` + `contentShape`, no overlap). Circle независим: `CompletionButton` вне Menu, menu никогда не завершает задачу. AX: `.accessibilityLabel(task.title)` на menu (полный source title). |
| `apple/OrbitIOS/OrbitIOS/TodayScreen.swift` | только row arguments: оба `InboxRowView` вызова (Открытые/Завершённые) с `showsDateLabel: false` (дата уже в caption/заголовках раздела). |
| `apple/OrbitIOS/OrbitIOS/UpcomingListScreen.swift` | только row argument: вызов в дневных секциях с `showsDateLabel: false`. |
| `apple/OrbitIOS/README.md` | секция строк InboxScreen под LIST-001. |
| `reports/NATIVE-LIST-001-executor.md` | этот отчёт. |

Не менялись: core/model/store, editors (TaskDateSheet/TaskIntervalSheet), CompactCalendarTaskRow/CalendarDayScreen/DayTimeline/Workspace/mode controls/nav, Inbox composer, Projects/macOS/web/targets/tests/root docs. Membership/order/UUID/ranges/timers/view modes — без изменений.

## Поведение (сверка с пунктами TASK)

1. Постоянных иконок нет во всех трёх списках (общая строка); тело — tappable native Menu; circle слева независим.
2. Circle — только complete/reopen; body/menu никогда не пишет; separate hit targets без вложенных Button.
3. Undated: «Дата…» работает; time disabled с подписью до даты; после назначения даты — активен; clear-правила в существующих editors.
4. Ряды ниже (padding 2; простой ряд ≈48pt в границах 44–56), типографика .body/.footnote прежняя, AXL растит ряды естественно (без maxHeight/clipping), hit ≥44pt, no overlap.
5. Дубликаты даты скрыты в Today/дневных секциях Upcoming (флаг), Inbox сохраняет дату (теперь по-русски), время start–end/(+1 день) сохранено везде; арифметика label не менялась.
6. UUID/order/ranges/timers/mode header/empty states — прежние; menu state локальный, без кэшей/таймеров.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild … -derivedDataPath /tmp/orbit-list1-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | прогон 1: exit 0 BUILD SUCCEEDED; в GUI обнаружен tint-дефект подписей (см. UNVERIFIED/заметки) → фикс `Color.secondary`; прогон 2: **exit 0 BUILD SUCCEEDED**, reinstall + relaunch |
| Core/web/full/legacy suites, new test framework | НЕ повторялись / не добавлялись (по TASK) |
| Fixture | временный генератор на OrbitCore (вне дерева, удалён): 10 задач — Вчера, Сегодня А/Б, Сегодня с временем 09:00/60, Сегодня выполненная, очень длинное название (today), +1/+6/+7, Без даты |
| Simulator | свой `orbit-list1-gui` iPhone 17 Pro / iOS 27.0 UDID 2EB8E0D1-…-927105735DF7, создан/удалён мной |

## Инструментальная заметка (честно)

CUA-контроллер (orca computer-use) оказался жёстко остановлен моей же командой `stop()` в конце предыдущего TASK и в этой сессии не перезапускается («Start a new session»). GUI-прогон выполнен собственными одноразовыми CGEvent-инструментами (swiftc-компиляция клик/драг/замер-границ, все удалены): калибровка зеркала Device Hub по пиксельным границам (экран глобально ≈(686.5,213.5), масштаб 0.739/0.742), клики и drag-свайпы в зеркало, проверка состояний — по нативным `simctl io screenshot` устройства. Все действия и исходы подтверждены скриншотами; tooling-замена не влияла на проверяемое поведение приложения.

## GUI evidence (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-LIST-001/`)

1. `l1-01-today-compact.png` — Today: в строках НЕТ clock/calendar иконок, ряды ниже, дублирующих дат нет (caption раздела «14 окт. 2026 г.»), подпись времени «09:00–10:00» сохранена (серая), длинное название переносится на 3 строки, круги независимы.
2. `l1-02-body-menu.png` + `l1-02b-body-menu-device.png` — tap по телу «Сегодня А» → компактное native меню «Дата…» / «Время и длительность…» (оба пункта, датированная задача).
3. `l1-03-date-editor-cancel.png` — «Дата…» → существующий TaskDateSheet «Дата задачи / Сегодня А» с актуальным значением (14 October 2026) → «Отмена» — без записи (подтверждено store-дифом).
4. `l1-04-time-editor.png` — «Время и длительность…» → существующий TaskIntervalSheet «Время задачи / Сегодня с временем» с фактическими 09:00/60; закрыт swipe-вниз без записи (подпись строки не изменилась).
5. `l1-05-undated-menu.png` — Inbox «Без даты»: меню с активной «Дата…» и DISABLED «Время и длительность — сначала назначьте дату» (today молча не ставился).
6. Legit Save: «Дата…» → редактор → «Сохранить» → строка получила русскую подпись «14 окт. 2026 г.»; store: UUID 19b5f695-941d-4898-9616-010e3a8816e7 planned_date NULL→'2026-10-14' (единственная семантическая запись сессии).
7. `l1-06-dated-now-menu.png` — повторное меню той же строки: «Время и длительность…» теперь АКТИВЕН (gating снят после назначения даты).
8. Circle отдельно: тап по кругу «Плюс 1 день» → задача в «Завершённые» (меню не открывалось); повторный тап → reopen в «Открытые»; store: только Z_OPT 2→4 у того же UUID (completedAt вернулся в NULL).
9. `l1-07-upcoming-compact.png` — Upcoming: дневные секции с датами в заголовках, в строках дат-дублей нет, без иконок.
10. `l1-08-axl.png` — accessibility-extra-large: ряды/заголовки растут естественно, подписи читаемы, контролы активны, nothing clipped.

## Readonly store

`.dump` до GUI и после всех взаимодействий: ровно две ожидаемые дельты — (а) «Без даты» Z_PK=10: planned_date NULL→'2026-10-14' (легитимный Save через menu→editor, тот же UUID); (б) «Плюс 1 день» Z_PK=7: Z_OPT 2→4 (complete+reopen кругом, семантика неизменна). Date/time editor Cancel, открытие меню, переключения вкладок, AXL — записей не создали.

## UNVERIFIED / заметки

- Menu/AX-поведение VoiceOver-сессией не проверялось (AX-дерево зеркала недоступно без CUA; AX-label задан source-level: menu = полный title, circle = «действие: задача»).
- Подписи внутри Menu label: иерархические стили (`.secondary`) перекрашивались tint'ом меню в coral — заменено на семантический `Color.secondary` (задокументировано комментарием в коде); на скриншотах подписи серые.
- Реальный iPhone, тёмная тема, RTL, small-width устройство (SE-класс) — не проверялись; Dynamic Type проверен на AXL (один smoke по TASK).
- Время-редактор на half-detent показывает Save/Отмена ниже видимой зоны — принятое NAV005-поведение editor'а, LIST-001 его не менял; закрытие без записи выполнено swipe (кнопка «Отмена» в этом editor'е в GUI не кликалась).

## Ограничения / гигиена

- Scoped коммиты (код+README; отчёт); `git diff --check` чисто; дерево чистое; без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktrees/хранилища/hooks/xcode-select/signing/настройки не трогались; content size возвращён на `large`; свой simulator/temp/tools удалены.
- Stop: независимый Codex review; MIN5/Projects/drag/resize/3дня/Месяц/AI/common mode header не начинались.

## Git

- Ветка `task/NATIVE-LIST-001`; start `7e017ac61dbd0d87a207373bb8d0a2b8145287a5`; полный SHA итогового коммита — в чате.
