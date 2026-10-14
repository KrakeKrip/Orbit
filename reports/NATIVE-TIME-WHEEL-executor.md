# NATIVE-TIME-WHEEL — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW (независимый Codex review — следующая стадия).

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-TIME-WHEEL`; ветка `task/NATIVE-TIME-WHEEL`; **starting SHA `1d2fd642df3c150e6dd38fdab03b665dbcaa78b5`** (assignment HEAD, дерево чистое). База реализации `8e2abbd74c8bdbb6de66e9f2064b4a96feda2320` — принят MIN5, `git merge-base --is-ancestor` подтверждён.
- Прочитаны AGENTS.md, DESIGN.md (разделы «Нативные wheel controls времени, 2026-10-14» и «Шаг duration wheel — прямое уточнение 2026-10-14»), tasks/NATIVE-TIME-WHEEL.md. Старые assignments не выполнялись.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/TaskIntervalSheet.swift` | переписан UI редактора (файл из scope): TextFields/клавиатура удалены. Компактные tappable summary rows «Начало»/«Длительность» (44pt hit, chevron); тап раскрывает СВОЮ wheel-группу, максимум одна раскрыта (`ExpandedGroup?`). «Начало»: часы 0…23 + минуты 00…59 стандартными `.pickerStyle(.wheel)` — civil wall-clock компоненты, БЕЗ date→instant/DST пути; минуты старта НЕ ограничены шагом 5. «Длительность»: часы 0…24 + минутное колесо ТОЛЬКО 0/5/10/…/55 (`stride(from: 0, through: 55, by: 5)`); 00 ч 00 и 24 ч 05+ → «Сохранить» disabled + короткий красный hint из core-констант (core — финальная валидация, no clamp writes; `isWritableDuration` core НЕ менялся). Legacy вне сетки (1…4/6/7/61…): точная readable подпись «N мин — сохранено» + явный переход «выберите новую длительность, кратную 5 минутам»; колёса на нейтральных defaults 0 ч/30 мин и вступают в силу только после явного движения (`durationWheelActive`); до этого эффективный draft = сохранённое значение. Readonly preview «Закончится в ЧЧ:ММ»/«… (+1 день)» из принятого `TaskTimeInterval.end` (не сохраняется; работает и для legacy 1…4 — read compat). Дата — по-русски через existing `RussianDateCaption`. Текстовая инструкция ЧЧ:ММ/целое число минут удалена. Save/Отмена/Убрать время: прежние пути (`model.setPlannedInterval` whole pair / nil-nil), прежние accessibility identifiers, `.presentationDetents([.large])`. |
| `apple/OrbitIOS/README.md` | раздел TaskIntervalSheet под TIME-WHEEL. |
| `reports/NATIVE-TIME-WHEEL-executor.md` | этот отчёт. |

Не менялись: core (TaskTimeInterval/OrbitTaskStore/OrbitTask/schema), IOSInboxModel/errors, CompactCalendarTaskRow/CalendarDayScreen/DayTimeline/Workspace/mode controls/nav/list rows/menu, tests, Projects/macOS/web/targets/root docs.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild … -derivedDataPath /tmp/orbit-tw-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | прогон 1: 3 compile error (незадекларированные члены) → исправлены; прогон 2: **exit 0, BUILD SUCCEEDED** |
| Core 70 tests / web / full / legacy | НЕ повторялись (core не менялся — по TASK) |
| Fixture | временный генератор (вне дерева, удалён): «Обычная 09:00 30» (09:00/30, store API), «Ночная 23:30 90» (23:30/90, store API), «Легаси 1 минута» (10:00/1) и «Легаси 6 минут» (11:00/6) — через SwiftData model в изолированном context (write API корректно отвергает 1/6) |
| Simulator | свой `orbit-tw-gui` iPhone 17 Pro / iOS 27.0 UDID 3353D6C2-…-B5FEE, создан/удалён мной |

## Инструментальная заметка

CUA-контроллер по-прежнему недоступен в этой сессии (остановлен в старом TASK); GUI выполнен одноразовыми CGEvent-инструментами (клик/драг/скан-границы, swiftc, все удалены) с фикс-маппингом зеркала Device Hub (686.5/213.5, 0.7388/0.742 — подтверждён successful-кликами этой сессии: таб, строки, меню, поля, колёса, кнопки). Проверки — нативные `simctl io screenshot`.

## GUI evidence (`/Users/atlhnv/Codex/orbit-outputs/NATIVE-TIME-WHEEL/`)

1. `tw-01-editor-collapsed.png` — editor «Обычная 09:00 30»: свёрнутые summary rows «Начало 09:00 ⌄» / «Длительность 30 мин ⌄», Дата «14 окт. 2026 г.» (ru), preview «Закончится в 09:30», Save/Отмена/Убрать время видимы, клавиатуры нет.
2. `tw-02-start-wheels.png` — «Начало» раскрыто: колёсика Часы (9) / Минуты (08); минуты старта выбраны НЕ кратным 5 (08) — демонстрация «старт не ограничен шагом 5»; preview живой («09:38»).
3. `tw-03-duration-wheel-step5.png` — «Длительность» раскрыта: минутное колесо показывает ТОЛЬКО 10/15/20/25/30/35/40/45 мин (шаг 5 ✓), часы 0…24; «Начало» схлопнут (максимум одна группа).
4. `tw-04-duration-1h10.png` — явный выбор колёсами: 1 ч + 40 мин, preview «Закончится в 10:48» (09:08+1:40).
5. `tw-05-saved-row.png` + store — Сохранить: whole pair 09:08/100 записан под ТЕМ ЖЕ UUID 83c9232f-… (ZPLANNEDTIME 09:00→09:08, ZDURATIONMINUTES 30→100, Z_OPT 3→4 — единственный диф), строка «09:08–10:48».
6. `tw-09-relaunch-persisted.png` — после terminate+relaunch строка «09:08–10:48» восстановлена с диска.
7. `tw-06-legacy6-editor.png` — «Легаси 6 минут»: summary «6 мин — сохранено» (точное значение читаемо, НЕ округлено), явный переход «выберите новую длительность, кратную 5 минутам», колёса на нейтральных 0 ч/30 мин; Начало 11:00 exact.
8. Legacy Cancel: swipe/кнопка закрыли editor БЕЗ записи — store: «Легаси 6 минут» 11:00/6 и «Легаси 1 минута» 10:00/1 байт-в-байт прежние; 6 не попала в опции колеса.
9. `tw-07-axl.png` + `tw-08-axl-list.png` — accessibility-extra-large: editor «Легаси 6 минут» (Начало колёса с exact 11/00, summary rows переносятся) и список — всё читаемо/масштабируемо; content size возвращён на `large`.

## Readonly store

`.dump` до GUI и финальный: РОВНО одна изменённая строка — «Обычная 09:00 30» (UUID 83c9232f-…): 09:00/30 → 09:08/100 (целевая wheel-выборка + Save), Z_OPT 3→4. Legacy 1/6, «Ночная 23:30 90» — без изменений. Открытия editor, раскрытия колёс, Cancel — не писали.

## UNVERIFIED (честно)

- GUI-сценарии «00 ч 00 → Save disabled + hint» и «24 ч 05 → disabled» не показаны: 0 ч и 24 ч находятся на границах 25-строчного часового колеса (многострочный скролл синтетическим драгом не доведён до границ). Source-level: `saveEnabled`/`durationWheelValid` отключают кнопку для total вне 5…1440; core-правило дважды покрыто MIN5-тестами (70/70).
- Выбор 24 ч 00 в GUI (representable) — не показан по той же причине; опция «24 ч» присутствует в часах (0…24) по коду.
- Overnight editor preview («Ночная» 23:30/90 → «Закончится в 01:00 (+1 день)») в GUI не открыт; та же accepted helper показана в строке списка «23:30–01:00 (+1 день)» и в preview обычной задачи.
- «Сценарий 4 → reject» из MIN5 остаётся UNVERIFIED-GUI (наследие MIN5, пользователь перенаправил на крутилку).
- VoiceOver-сессия, реальный iPhone, тёмная тема, RTL — не проверялись. Pan-жесты вне колёс не имитировались.

## Ограничения / гигиена

- Обычный scoped commit; `git diff --check` чисто; дерево чистое; без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktrees/хранилища/hooks/xcode-select/signing/настройки не трогались; content size `large`; свой simulator/temp/tools удалены.
- Stop: независимый Codex review; Projects/commonheader/drag/resize/3дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-TIME-WHEEL`; start `1d2fd642df3c150e6dd38fdab03b665dbcaa78b5`; полный SHA итогового коммита — в чате.
