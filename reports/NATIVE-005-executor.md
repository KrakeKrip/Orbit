# NATIVE-005 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-005`; ветка `task/NATIVE-005`; **starting SHA `0985c32198eefadfcdad33c8a3c2bcf4ff9a1fab`**; review/source base `a56137473b186efe5b87d4ae9c46881f092262df` (merge-base совпадает — принятый NATIVE-004, core 50 tests/iOS build PASS); дерево чистое, чужих изменений нет.
- Прочитаны AGENTS/PRODUCT/ARCHITECTURE/DESIGN/tasks/NATIVE-005.md; core/schema/TaskPlannedDate/TaskDateSheet/macOS/web не тронуты; macOS-R1/web PAUSED.
- Tooling: Xcode 27.0 (27A266a) через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `xcode-select`/signing/Apple ID не менялись.

## Изменённые файлы (ровно 3 product UI файла + README + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift` | wrapper `setPlannedInterval(plannedTime:durationMinutes:for:) -> String?` (nil при успехе + reload; иначе русское сообщение, редактор остаётся открытым); `intervalMessage` — typed-ошибки core: invalidTime/invalidDuration/incompletePair/missingDate/endOutOfRange; в `plannedDateMessage` добавлен понятный случай `endOutOfRange` (смена даты с выходом итогового времени за 1900–2199) |
| `apple/OrbitIOS/OrbitIOS/InboxScreen.swift` | `InboxSheetPresentation` enum (kind+task UUID, Identifiable) — один date/interval sheet за раз, draft каждой презентации инициализируется заново; clock-action «Время задачи: <title>» (≥44pt, только у задач с plannedDate; без даты — только calendar-action, «сегодня» автоматически не подставляется); подпись интервала «09:00–09:30» / «23:30–01:00 (+1 день)» под датой через `TaskTimeInterval.end` (не хранится, без timezone-конверсий); подпись даты/порядок/видимость/completion не менялись |
| `apple/OrbitIOS/OrbitIOS/TaskIntervalSheet.swift` (**новый**) | native Form-редактор: подписанные поля «Начало» (HH:mm) и «Длительность, мин» (keyboardType .numbersAndPunctuation, trailing alignment), видимый footer с форматом/диапазоном (00:00–23:59, 1–1440, переход через полночь) и контекстом даты; draft из сохранённых значений при каждом открытии, defaults 09:00/30 только при отсутствии интервала; «Сохранить» → одна store-операция через model, пара передаётся целиком (core — источник правил); duration-ввод конвертируется в Int безопасно (не-число/пусто → ошибка «Длительность должна быть целым числом минут.», НЕ nil/nil и не default); успех → reload + dismiss; отказ → русская ошибка, draft и sheet сохранены; «Отмена»/swipe не пишут; «Убрать время» видима только для сохранённого интервала → nil/nil, дата остаётся. A11y identifiers (interval-start/duration/save/cancel/clear/error) |
| `apple/OrbitIOS/README.md` | секция структуры/поведения интервального редактора |
| `reports/NATIVE-005-executor.md` | этот отчёт |

Не менялись: core (OrbitTask/OrbitTaskStore/TaskTimeInterval/TaskPlannedDate/TaskTitle/store location), TaskDateSheet, macOS, Xcode project/scheme, coordination docs, web.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift test` (apple/Orbit, DEVELOPER_DIR) | exit 0 — **50/50 в 6 suites** (core не менялся, все существующие сохранены) |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n5-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — **BUILD SUCCEEDED** (два прогона: до и после переноса error-секции выше кнопок для видимости) |
| Собственный временный Simulator | iPhone 17, iOS 27.0 (UDID 7564A148-…), boot/install/launch, зеркало Device Hub; после evidence — terminate, shutdown, `simctl delete` (удалён только мой device), derivedData/tmp удалены |

## GUI evidence (собственный Simulator, синтетические данные; AX-наблюдения + pixel-скриншоты)

1. **Add + date**: задача добавлена с экранной клавиатуры (набор по клавишам; iOS autocorrect заменил задуманное «Банк» на «Бачок» — rename вне scope, оставлено как есть, на функциональность не влияет), затем существующим calendar-action назначена дата (draft=сегодня) — подпись «13 Oct 2026»; после назначения даты появился clock-action «Время задачи: Бачок» (до даты отсутствовал ✓, автоматического «сегодня» нет).
2. **Interval sheet + defaults**: clock-action → sheet «Время задачи»: поля Начало=09:00, Длительность=30 (draft defaults подтверждены AX), footer с форматом/диапазоном/полночью и датой, кнопки Сохранить/Отмена, «Убрать время» отсутствует (интервала ещё нет). Скриншот `01-interval-editor.png`.
3. **Save 09:00/30**: «Сохранить» → строка «Бачок 13 Oct 2026 **09:00–09:30**» (start–derived end; end из `TaskTimeInterval.end`, не хранится); sqlite readonly: `09:00|30`. Задача осталась в «Открытых», порядок не менялся. Скриншот `02-row-with-interval.png`.
4. **Change 23:30/90 → midnight**: переоткрытие → draft из сохранённых значений (09:00/30) → изменено на 23:30/90 → Сохранить → «Бачок 13 Oct 2026 **23:30–00:00 (+1 день)**» → длительность 90 → «**23:30–01:00 (+1 день)**» ✓. **Terminate→relaunch без reinstall**: подпись и `sqlite` (23:30|90) подтверждены.
5. **Cancel-flow**: sheet → setValue Начало=01:00 → «Отмена» → строка неизменна; переоткрытие → draft снова 23:30/90 (отвергнутый draft не воскресает; открытие не пишет).
6. **Ошибки** (draft и сохранённый интервал не изменялись — sqlite подтверждён):
   - Начало=25:00 → «Начало «25:00» должно быть временем в формате ЧЧ:ММ (00:00–23:59).» Скриншот `03-invalid-time-error.png`.
   - Длительность=0 → «Длительность 0 недопустима: укажите целое число минут от 1 до 1440.»
   - Длительность=1441 (при валидном 10:00) → «Длительность 1441 недопустима…».
   - Исправление 10:00/45 → «Сохранить» успешно: sqlite `10:00|45`, sheet закрыт.
7. **«Убрать время»** (кнопка видима только у интервала): интервал очищен, **дата осталась** (sqlite `2026-10-13||`).
8. **«Убрать дату»** (существующий editor, принятая core-операция): очищены все три поля — sqlite `Бачок|||`, строка без подписей.
9. **Smoke**: повторный assign даты и интервала (после всех циклов) работает; complete/reopen круглым контролом; новая задача «Молоко» добавлена через композер. Финальный sqlite: `Бачок|2026-10-13|09:00|30` + `Молоко|||`. Скриншот `03-final-populated.png`.
10. **Keyboard/layout/a11y**: композер и sheet-поля с клавиатурой (numbers-layout через keyboardType), композер над клавиатурой; `content_size accessibility-large` — весь экран масштабируется, затем возвращён `large`. Скриншот `04-dynamic-type-accessibility-large.png`.

Скриншоты (вне product tree): `/Users/atlhnv/Codex/orbit-outputs/NATIVE-005/01-interval-editor.png`, `02-row-with-interval.png`, `03-invalid-time-error.png`, `03-final-populated.png`, `04-dynamic-type-accessibility-large.png`.

## Ограничения / не проверено

- Техника ввода в автоматизации: экранные клавиши работали нестабильно (suggestion-панель переупорядочивает AX-дерево после каждого символа), поэтому значения полей editor'а задавались через accessibility `setValue` на зеркале Device Hub — при этом **SwiftUI binding подтверждён результатом** (Сохранить применял ровно установленные значения: 09:00/30, 23:30/90, ошибки 25:00/0/1441, финальные 10:00/45 и 09:00/30 с disk-подтверждением). Ручной человеко-ввод в поля не проверялся (что не отделить от инструмента).
- Взаимодействие с graphical-элементами вне полей/кнопок (wheel DatePicker даты) в GUI не выполнялось в этом прогоне (дата назначалась кнопкой «Сохранить» с draft=сегодня); изменение даты на другую — будущие сценарии, setDate-путь покрыт core-тестами и принятой NATIVE-003.
- Заголовок тестовой задачи искажён автокоррекцией iOS («Бачок» вместо «Банк») — rename вне scope, на проверки не влияет.
- Реальный iPhone НЕ ПРОВЕРЕН; тёмная тема/RTL не проверялись; runtime save-failure (диск) не воспроизводился (без fault framework), invalid-ветки покрыты typed-ошибками через core.
- Own Simulator device удалён, derivedData/tmp удалены; личные stores/чужие simulators не трогались.

## Git

- Ветка `task/NATIVE-005`; starting SHA `0985c32198eefadfcdad33c8a3c2bcf4ff9a1fab`; обычный scoped commit (3 product файла + README + отчёт); полный latest SHA в чате.
- `git diff --check` чисто; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/чужие worktrees/CRM/localhost:3000/hooks/xcode-select не менялись. NATIVE-006/Today/календарь не начинались.

---

# Коррекция NATIVE-005-R1 — название задачи в редакторе интервала

## Статус

READY_FOR_REVIEW (только R1 [P2] из reports/NATIVE-005.md; остальной TASK не переписывался). Starting correction SHA `d3edd9abbe1f25607c8122055e953e5f27ca74cd` (coordinator review HEAD), дерево чистое.

## Изменение (один product файл)

`apple/OrbitIOS/OrbitIOS/TaskIntervalSheet.swift`: в начало Form добавлена секция «Задача» с видимым `Text(task.title)` — отдельно от generic заголовка навигации «Время задачи» и от строки «Дата». Стиль: `.body.weight(.medium)`, перенос длинных названий (`fixedSize(horizontal: false, vertical: true)`, без lineLimit/жёсткой высоты), `textSelection(.enabled)`, Dynamic Type (системный шрифт), a11y identifier `interval-task-title`. Название берётся из переданной задачи — при открытии другой задачи показывается актуальное. Поля/draft/валидация/Сохранить/Отмена/Убрать время/store/presentation — не менялись.

## Проверки

| Проверка | Результат |
| --- | --- |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-r1-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — BUILD SUCCEEDED (DerivedData удалён) |
| GUI (свой временный iPhone 17 iOS 27.0, UDID 11F5F16B-…, удалён после): задача «Банк» (короткое) | date editor (сегодня) → clock-action → interval sheet содержит секцию «Задача» с «Банк»; поля с defaults 09:00/30; Cancel закрыл без записи. Скриншот `05-r1-editor-title-bank.png` |
| GUI: задача «Сходить в магазин за продуктами и не забыть кофе» (48 символов, длинное) | date editor → interval sheet: длинное название **переносится на 2 строки и читается полностью**; в Expanded-детенте поля Начало/Длительность (09:00/30) и кнопки Сохранить/Отмена доступны; Cancel без записи. Скриншот `06-r1-long-title-editor.png`, финальный Inbox `07-r1-final-inbox.png` |
| «Правильный title после нового открытия» | редактор открывался поочерёдно для двух задач — каждый раз показано название соответствующей задачи (Банк ↔ Сходить…), перекрёстного названия не было |
| sqlite readonly после Cancel-ов | интервалы не записаны: `Банк|2026-10-13||`, `Сходить…|2026-10-13||` (открытие/Cancel не пишут) |

Core не менялся — core 50 и legacy-прогоны не повторялись (по TASK). Ввод длинного названия выполнен accessibility setValue + «Добавить задачу» (SwiftUI binding подтверждён появлением строки; тот же подтверждённый путь, что в основном отчёте для «Молоко»); экранный набор 48 символов клавишами не гонялся (tooling-ограничение suggestion-бара из основного отчёта) — на проверку читаемости/переноса не влияет.

## Ограничения / не проверено

- Реальный iPhone, тёмная тема, RTL — не проверялись (без изменений).
- Runtime save-failure/дата-смена flows — вне R1, не повторялись.

## Git

Новый обычный scoped commit (TaskIntervalSheet.swift + R1-секция отчёта); полный latest SHA в чате. Без merge/push/amend/rebase/reset/stash/deploy; NATIVE-006 не начинался; main/чужие worktrees/CRM/3000/hooks не тронуты.
