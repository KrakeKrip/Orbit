# NATIVE-ADD-004 — отчёт исполнителя (GLM)

## Статус

**READY_FOR_REVIEW** (остановка до Codex review). Shared create sheet: редактируемые дата/начало/длительность на нативных колёсах, whole candidate через принятый atomic addTask.

## Назначение и база

- TASK: `tasks/NATIVE-ADD-004.md`; worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-ADD-004`; ветка `task/NATIVE-ADD-004`.
- Starting SHA `5dbb4a0d3c10ecb791160da2c305fd3e1135592b` — root/branch/HEAD совпали, дерево чистое до изменений.
- База `55ca03221ae23d938b9534e8c2a93b63696f888f` (ADD-003 принят) — в истории ветки.
- Прочитаны AGENTS.md, DESIGN.md, tasks/NATIVE-ADD-004.md.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/TaskCreatePresentation.swift` | FAB/presentation/host НЕ менялись (preset-логика ADD-002 сохранена: хост вычисляет datePreset в момент открытия). `TaskCreateSheet` переписан на LOCAL draft: `draftDate: String?` (civil YYYY-MM-DD) + `pickerDate` (позиция колеса; preset только SEEDS draft — invalid preset никогда не заменяется молча на today, draft остаётся «Без даты»); wheel `DatePicker(.wheel, displayedComponents: [.date], in: 1900-01-01...2199-12-31)`, ru_RU, русская caption через `RussianDateCaption`; «Убрать дату» очищает draft и выключает пару (Add шлёт nil/nil). Время — явный `Toggle` (disabled + «Сначала выберите дату» при draftDate==nil; никакого silent today); включение пользователем → нейтральные дефолты 09:00/30 мин; «Убрать время» сохраняет дату; пара всегда whole. Колёса как принятый interval editor: start часы 0…23 / минуты 00…59 (НЕ step-5), duration часы 0…24 / минуты ТОЛЬКО 00/05/…55, минимум 5…1440 — 00ч00 и 24ч05+ → «Добавить» disabled + красный понятный hint (core остаётся финальной валидацией). Summary-строки compact, максимум ОДНА раскрытая группа (date/start/duration), открытие группы отпускает клавиатуру и сохраняет drafts. End-preview только из `TaskTimeInterval.end`, «(+1 день)» при переходе, prefix без дублей, не хранится. Форма в `ScrollView` — поля/кнопки/колёса доступны при software keyboard и AXL (навигация скроллом, никакого UIScreen/clipping). Error в форме сохраняет все drafts (retry), created-guard/одна presentation сохранены. |
| `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift` | `create(title:plannedDate:plannedTime:durationMinutes:)` — backward-compatible optional пара последними параметрами, whole candidate в принятый single-save `addTask`; без временного OrbitTask/insert и без create→setDate→setTime. Новый `IOSInboxFormatting.createMessage`: date/interval ошибки через принятые `plannedDateMessage`/`intervalMessage`, title через `addMessage`, остальное — явный store error (никогда не молча-generic). Success: `writeError=nil` + reload + return nil (последующий read failure не становится write failure). |

Не менялись: core/schema/store, existing editors (`TaskDateSheet`/`TaskIntervalSheet`), FAB hosts/workspaces/modeheader/grid/rows, root docs. Новый UI helper НЕ потребовался (всё в TaskCreatePresentation.swift; `RussianDurationText`/`RussianDateCaption` переиспользованы, не копированы).

## Проверки (фактические)

| Проверка | Результат |
| --- | --- |
| `xcodebuild … -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-add004-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | **BUILD SUCCEEDED** (первый прогон после фикса сигнатуры wheel-хелпера; один финальный build) |
| GUI-проход, СВОЙ simulator `orbit-add004` (iPhone 17 / iOS 27.0, создан и удалён; store — sandbox приложения, чужие устройства/данные не тронуты) | см. ниже; evidence `/Users/atlhnv/Codex/orbit-outputs/NATIVE-ADD-004/` |
| `git diff --check` | чисто; дерево после коммитов чистое |
| Existing core 44 tests / full core / web / db / auth / legacy | НЕ повторялись (core не менялся — по TASK) |

### GUI-последовательность (скриншоты — нативные `simctl io screenshot`; store-проверки — sqlite-копии из контейнера СВОЕГО приложения)

1. **Defaults 3 контекста:** `a01-today-defaults.png` — Today: preset = свежий local today (15 окт — симулятор перешёл полночь во время подготовки, пресет честно пересчитан, что дополнительно подтверждает «не stale»); `a02-inbox-defaults.png` — Inbox: «Без даты» + «Время» disabled + hint «Сначала выберите дату»; `a03-upcoming-defaults.png` — Upcoming после Next-day: preset = selectedDay «16 окт. 2026 г.», вид/вкладки не сброшены.
2. **Реальный date control меняет preset:** в sheet раскрыта группа «Дата», день изменён колесом 16→18; caption live «18 окт. 2026 г.»; сохранено как 2026-10-18 (store).
3. **Whole candidate 09:08 + 1 ч 40 мин:** `d11` «Начало 09:08» (минутное колесо шагом 1, «08» выбрано); `d14` «Длительность 1 ч 40 мин» + preview «Закончится в 10:48»; после «Добавить» store: `Zara ha 100 | 2026-10-18 | 09:08 | 100` — одна строка, один save; `a04` — задача в группе «18 окт.» с «09:08–10:48»; `a05-calendar-block.png` — Calendar view 18 окт: коралловый блок 09:08–10:48 в сетке.
4. **Time clear → дата осталась:** toggle ON → «Убрать время» → Add: `Date only 18 | 2026-10-18 | NULL | NULL`.
5. **Date clear → pair nil:** `Убрать дату` при включённом времени → `a06-date-cleared-pair-nil.png` («Без даты», toggle OFF, hint виден) → Add: `Undated pair | NULL | NULL | NULL`.
6. **Cancel/swipe без вставки:** черновик + «Отмена» и черновик + swipe-down — count остался 4; после swipe зеркало показывало список без sheet (FAB-скан).
7. **Blank refusal → retry:** Add (disabled) + keyboard Return с пустым полем → красное «Введите название задачи.» В ФОРМЕ (`d23`), строк нет; после ввода «Retry works» → Add → ровно одна строка `Retry works | 2026-10-18`.
8. **Overnight preview:** черновик 20 ч 05 мин при начале 09:00 → `a08-overnight-preview-plus1day.png`: «Закончится в 05:05 (+1 день)» — маркер перехода суток живой, prefix без дублей. Формально TASK предлагал 23:30/90: overnight-механика та же (`end.date != draftDate`), демонстрация выполнена на достижимом колесами кандидате — отмечено как отклонение метода, не поведения.
9. **Границы колёс:** `a07-boundary-0h00.png` — 0 ч 00: summary «недопустимая длительность», красный hint «Длительность — от 5 минут до 24 ч 00 мин.», «Добавить» disabled; фикс на «5 мин» → валидно. `a09-boundary-24h05.png` — 24 ч 05: снова disabled + hint; `a10-boundary-24h00-fixed.png` — фикс на «0 мин»: «24 ч 00 мин» валидно (максимум), hint исчез.
10. **Software keyboard + AXL:** `content_size accessibility-medium` → `a11-axl-sheet-input.png` — заголовок «All input» введён с клавиатуры, все поля/кнопки доступны и не уезжают за границы (sheet large, скролл), «Добавить» активен; размер возвращён в `large` (проверено `simctl ui … content_size`).
11. **Terminate/relaunch:** `a12-relaunch-persistence.png` + store: все 4 задачи с точными полями (`2026-10-18/09:08/100`, `2026-10-18/NULL/NULL`, `NULL×3`, `2026-10-18/NULL/NULL`); Today 15 окт честно пуст («На сегодня всё»).

Инструментальная заметка: Orca/CUA недоступен — одноразовые CGEvent-инструменты (клик/drag/клавиши/пиксельный скан, все удалены) + зеркало Device Hub (двухточечная калибровка FAB/таб-иконка; чужое зеркало чужого устройства закрыто, т.к. окно было привязано к УДАЛЁННОМУ device «unavailable» — данные не затронуты). Колёса крутились комбинацией драгов и тапов по видимым строкам; каждый шаг подтверждён скриншотом устройства и/или store. Симулятор авто-локался один раз — разблокирован, клики восстановлены.

## UNVERIFIED / ограничения

- Runtime save failure — fault framework не вводился (по TASK); error-путь в форме (сообщение + сохранение drafts + retry) подтверждён на core-refusal кейсах (blank, валидация), не на disk failure.
- Заголовки в GUI — латиницей (симулятор игнорирует unicode-ввод синтетикой; смену layout TASK запрещает); весь UI на русском.
- Пресет 23:30/90 из TASK заменён на эквивалентный overnight-кандидат 20 ч 05 мин (тот же код-путь «(+1 день)»); отдельный save-matrix не прогонялся (по TASK не требуется).
- Реальное устройство, VoiceOver, тёмная тема, RTL — вне TASK; дедлайны/напоминания/notifications/Projects/gestures/EDIT-002 не начинались.
- Колёсный ввод синтетикой флакует (инерция/фокус окна) — каждый шаг верифицирован скриншотом/store; raw store write не использовался для подмены GUI-результатов.

## Гигиена

- Один обычный scoped commit (код) + commit отчёта; без merge/push/amend/rebase/reset/stash/clean/deploy; main/чужие worktrees не трогались; xcode-select/signing/hooks/systemsettings не менялись.
- Cleanup только собственных ресурсов: simulator `orbit-add004` (shutdown+delete), DerivedData `/tmp/orbit-add004-dd`, инструменты `/tmp/orbit-add004-tools`.

## Git

- Код: `8e55862efb64e7beed7807e0fac0a9e8e15b6e0d` (единственный кодовый commit от базы `5dbb4a0d3c10ecb791160da2c305fd3e1135592b`).
- Отчёт: финальный commit ветки (SHA в чате).
