# NATIVE-ADD-004-R1 — отчёт исполнителя (GLM)

## Статус

**READY_FOR_REVIEW** (остановка до Codex review). Tiny fix: явное подтверждение показанной date-wheel даты в create sheet.

## Назначение и база

- TASK: `tasks/NATIVE-ADD-004-R1.md`; worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-ADD-004`; ветка `task/NATIVE-ADD-004`.
- Starting SHA `d62df0c665b5c29bd22e46ac7c53b4d95f1af688` — root/branch/HEAD совпали, дерево чистое до изменений.
- Executor HEAD исходного R0 `867a0a1025ddb502795230955f194c9b0b3c7a32`; review — `reports/NATIVE-ADD-004.md` [P2].

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/TaskCreatePresentation.swift` | В раскрытой группе «Дата» добавлена явная кнопка «Выбрать эту дату» (`create-confirm-date`, borderedProminent, coral): присваивает `draftDate = TaskPlannedDate.civilDateString(from: pickerDate)` — через принятый адаптер, даже если значение колеса НЕ изменилось. Доступна всегда при раскрытой группе: при `draftDate == nil` (Inbox) и после «Убрать дату» (колесо хранит последнюю позицию). Группа НЕ схлопывается при подтверждении (caption обновляется live, пользователь видит результат). Doc-комментарий TaskCreateSheet дополнен. |

Сохранено без изменений (по TASK): change-wheel путь (onChange присваивает live), «Убрать дату» → pair nil, «Убрать время» → дата остаётся, preservation drafts/created-guard/item-identity; время/валидация/model/core/другие editors/FAB/headers. Открытие/закрытие группы само ничего не назначает; auto-today не вводился; записи до общего «Добавить» нет.

## Проверки (фактические)

| Проверка | Результат |
| --- | --- |
| `xcodebuild … -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-r1-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | **BUILD SUCCEEDED** (exit 0), один прогон |
| Целевой GUI, СВОЙ simulator `orbit-r1` (iPhone 17 / iOS 27.0, создан и удалён; store — sandbox приложения) | см. ниже; evidence `/Users/atlhnv/Codex/orbit-outputs/NATIVE-ADD-004-R1/` |
| `git diff --check` | чисто; дерево после коммитов чистое |

### GUI-сценарий R1 (скриншоты — `simctl io screenshot`; store — sqlite-копии контейнера СВОЕГО приложения)

1. **Inbox undated → confirm без вращения → create/date persisted:** Inbox → «+» → sheet «Без даты» (wheel уже показывает today 15 окт по центру) → раскрыть «Дата» → `d2`: видна НОВАЯ кнопка «Выбрать эту дату», caption ещё «Без даты» (открытие группы не назначает) → тап «Выбрать эту дату» БЕЗ вращения → `r1-confirm-shown-date.png`: caption «15 окт. 2026 г.» → время включено (toggle стал доступен, 09:00/30 — `d7`) → заголовок введён → Add → store: `R1 confirm date | 2026-10-15 | NULL | NULL` (время снято случайным тапом instrumentation перед Add — date-persisted утверждение R1 это не затрагивает; включённость времени после confirm видна в `d7`). Попутно подтверждено «no stale»: пресет пересчитан под новую дату симулятора (15 окт после полуночи).
2. **Вторая форма: assign → clear → confirm той же показанной даты → Cancel:** новая форма → раскрыть «Дата» → confirm (назначил) → sheet растянут до large (грабер) → «Убрать дату» → caption «Без даты» → confirm той же показанной позиции (15 янв — колесо к тому моменту было провернуто instrumentation-скроллом, change-wheel путь) → `r1-clear-reconfirm-restored.png`: summary ВОССТАНОВЛЕН «15 янв. 2026 г.», «Время» выключено (clear→pair nil путь сохранён) → Cancel → store count = 1 (`R1 confirm date`), вставки нет.
3. **Keyboard + AXL:** `content_size accessibility-medium` → форма: заголовок получил фокус, текст введён («All kb» — autocorrect), «Добавить» активен, все поля/кнопки доступны скроллом (`r1-axl-software-keyboard.png`); размер возвращён в `large`. **Честное ограничение:** РЕНДЕР самой software keyboard на скриншоте отсутствует — симулятор в режиме hardware keyboard скрывает экранную клавиатуру (AutoFill-аксессуар появляется, ввод работает); переключение ⌨ в DeviceHub тулбаре рендер не вернул. Визуальный software-keyboard-кадр — UNVERIFIED (tooling), ввод/доступность при AXL — подтверждены.

## UNVERIFIED / ограничения

- Рендер software keyboard (см. выше) — единственный недоказанный пункт сценария R1; подтверждены ввод с клавиатуры, фокус, доступность формы скроллом при AXL.
- Runtime disk failure / реальное устройство / VoiceOver / тёмная тема — вне TASK (как ранее).
- Тесты/core не перезапускались: тела методов поведения не меняли, 36/44 targeted PASS зафиксированы на R0 независимым review; повтор не требовался по TASK.

## Гигиена

- Один обычный scoped commit (код) + commit отчёта; без merge/push/amend/rebase/reset/stash/clean/deploy; main/чужие worktrees/чужие симуляторы не трогались (чужое «orbit-add002-codex-review» устройство не существовало в системе — только одноимённое устаревшее окно DeviceHub было закрыто, данные невозможны).
- Cleanup только собственных ресурсов: simulator `orbit-r1` (shutdown+delete), `/tmp/orbit-r1-dd`, `/tmp/orbit-r1-tools`, `/tmp/orbit-r1-udid.txt`.
- EDIT-002/дедлайны/напоминания/Projects/gestures не начинались.

## Git

- Код: `de057f5f28e96a95505d1c4fe524734257751c19` (единственный кодовый commit от базы `d62df0c665b5c29bd22e46ac7c53b4d95f1af688`).
- Отчёт: финальный commit ветки (SHA в чате).
