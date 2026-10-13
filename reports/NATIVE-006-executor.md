# NATIVE-006 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-006`; ветка `task/NATIVE-006`; **starting SHA `5add26ef4aff9f9e8b70bd730a921af8d2641175`**; review/source base `800b189adc9442d980cb8fb5080aa5e42efa0ff7` (merge-base совпадает — принятый NATIVE-005, core 50 + R1); дерево чистое, чужих изменений нет.
- Прочитаны AGENTS/PRODUCT/ARCHITECTURE/DESIGN/tasks/NATIVE-006.md; macOS-R1/web PAUSED, не трогались.
- Tooling: Xcode 27.0 через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `xcode-select`/signing/Apple ID/system settings не менялись.

## Изменённые файлы (3 product Swift файла + тест + README + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/TaskDaySelection.swift` (**новый**, read-only) | `tasks(onDay:in:)` — явная valid civil date + массив задач → те же объекты в исходном порядке (без мутаций/копий/новых UUID); invalid/nil день → пустой результат; completed не выбрасываются. `currentDay(from:calendar:)` — локальный Gregorian день через принятый Gregorian-pinned `TaskPlannedDate.civilDateString` (timezone supplied calendar). Без Calendar/DST-логики сверх адаптера |
| `apple/Orbit/Tests/OrbitCoreTests/TaskDaySelectionTests.swift` (**новый**) | 6 тестов: включение timed/untimed/completed; исключение nil/yesterday/tomorrow; same instances + стабильный порядок + отсутствие мутаций полей; invalid/nil день → пусто; currentDay UTC/Moscow/New York на фиксированной полночи + Buddhist calendar не ломает контракт |
| `apple/OrbitIOS/OrbitIOS/OrbitIOSApp.swift` | TabView с двумя реальными вкладками: «Сегодня» (default, sun.max) и «Входящие» (tray); обе используют ОДИН IOSInboxModel из уже открытого store; open-failure экран сохранён; `scenePhase == .active` → `model.reload()` |
| `apple/OrbitIOS/OrbitIOS/TodayScreen.swift` (**новый**) | list screen: reuse `InboxRowView` + `InboxSheetPresentation` + существующие date/interval sheets; секции «Открытые»/«Завершённые» как Inbox; заголовок «Сегодня», видимая локальная дата (`dateLabel(currentDay)`); empty state «На сегодня задач нет» с действием «Добавить во Входящих» (переключает вкладку, не создаёт/не дат); текущий день: onAppear refresh, scenePhase active refresh, Timer 30с (пересчёт дня; reload при смене дня) — без scheduler engine; без composer/quick-add |
| `apple/OrbitIOS/README.md` | секция Today-вкладки |
| `reports/NATIVE-006-executor.md` | этот отчёт |

Не менялись: core model/store/helpers (TaskPlannedDate/TaskTimeInterval/TaskTitle/TaskDaySelection только добавлен), InboxScreen/IOSInboxModel/TaskDateSheet/TaskIntervalSheet, project/scheme, coordination docs, web.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift test` (apple/Orbit, DEVELOPER_DIR) | exit 0 — **56 тестов / 7 suites** (50 существующих + 6 новых) |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n6-dd CODE_SIGNING_ALLOWED=NO build` | после фикса `onAppear { refresh() }` (refresh имел default-параметр Bool — не funcs-совместим) — exit 0, BUILD SUCCEEDED; DerivedData удалён |
| Fixture generator | временный тест удалённого после прогона файла (не коммитился): настоящий core создал `/tmp/orbit-native-006-fixture/store.sqlite` — 6 задач относительно реального today=2026-10-13: today untimed / today timed (09:30/45) / today completed / yesterday 2026-10-12 / tomorrow 2026-10-14 / undated; `fixture-info.txt` с today/yesterday/tomorrow |
| Свой Simulator | iPhone 17 iOS 27.0 (UDID 564290FD-…), install, fixture (3 файла store) в СВОЮ пустую песочницу ДО launch, launch; после evidence — terminate/shutdown/`simctl delete` (удалён только мой), derivedData/tmp/fixture удалены |

## GUI evidence (реальные действия, AX + pixel-скриншоты)

1. **Today = ровно свои 3**: «Сегодня с временем 13 Oct 2026 09:30–10:15» (timed с derived end), «Сегодня без времени 13 Oct 2026», «Сегодня завершённая» в секции Завершённые. Вчера/Завтра/Без даты — отсутствуют. Заголовок «Сегодня», дата «13 Oct 2026» видима. Tab bar с двумя вкладками (Сегодня активна). Скриншот `01-today-populated.png`.
2. **Входящие = все 6 + композер**, без клонов/перемещений (те же записи: Сегодня×3, Вчера, Завтра, Без даты). Скриншот `02-inbox-all-tasks.png`. Переключение вкладок туда-обратно — те же записи, без дублей.
3. **Complete/reopen из Today**: «Сегодня без времени» → Завершённые → Снова открыть → Открытые (AX подтверждён в обе стороны).
4. **Sheets из Today с контекстом**: interval sheet «Сегодня с временем» = title present, Начало=09:30, Длительность=45 ✓; date sheet открыта (13 Oct 2026), Cancel — закрытие без записи.
5. **Clear date убирает из Today, остаётся в Inbox**: «Сегодня без времени» → Убрать дату (Sheet Grabber → Expanded → кнопка) — исчезла из Today; затем то же для timed и completed → Today: **empty state «На сегодня задач нет» + «Добавить во Входящих»**. sqlite readonly: все три `ZPLANNEDDATE` пусты, задачи не удалены. Скриншот `03-empty-state.png`.
6. **Empty-state action**: клик «Добавить во Входящих» → активная вкладка Inbox с композером; новая задача «Новая из Inbox» добавлена композером — **без автодаты** (sqlite `ZPLANNEDDATE` пуст), только во Входящих.
7. **Re-assign возвращает в Today**: date editor «Сегодня без времени» → Сохранить (draft=сегодня) → вкладка Сегодня снова показывает задачу.
8. **Relaunch persistence**: terminate→launch — sqlite и GUI: «Сегодня без времени 13 Oct 2026» в Today, остальные на местах. Скриншот `04-today-after-relaunch.png`.
9. **a11y-large**: `content_size accessibility-large` — скриншот `05-accessibility-large.png`, затем `large` возвращён.

## Midnight/timezone lifecycle

Реальная смена системного времени/зоны не выполнялась и не заявляется (по TASK). Детерминированное покрытие: `currentDay` на фиксированных инстансах/зонах (UTC/Moscow/New York/Buddhist) в `TaskDaySelectionTests`; source wiring: day вычисляется заново в `refresh()` (onAppear / scenePhase active / Timer 30с) и передаётся в selection при каждом рендере — «сегодня» не хранится навсегда и не пишется в задачи.

## Ограничения / не проверено

- Реальная смена системного времени/часового пояса устройства не выполнялась (deterministic-тесты + wiring вместо неё, по TASK).
- Часовая сетка/overdue/deadline/recurrence/quick-add с датой — сознательно отсутствуют (NATIVE-007+).
- Ввод текста в автоматизации — accessibility setValue (binding подтверждён добавлением «Новая из Inbox»); экранный набор клавишами в этом прогоне не использовался.
- Реальный iPhone, тёмная тема, RTL не проверялись.
- Own Simulator device удалён; derivedData/fixture/tmp удалены; бэкапов fixture не требуется (генерация воспроизводима тестом-скриптом из history), никаких личных stores не тронуто.

## Git

- Ветка `task/NATIVE-006`; starting SHA `5add26ef4aff9f9e8b70bd730a921af8d2641175`; обычные scoped коммиты; полный latest SHA в чате.
- `git diff --check` чисто; SQLite/WAL fixture в коммит не входил; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/чужие worktrees/CRM/3000/hooks не менялись. NATIVE-007/сетка/3 дня/Месяц не начинались.
