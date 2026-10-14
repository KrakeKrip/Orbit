# NATIVE-ADD-003 — отчёт исполнителя (GLM)

## Статус

**READY_FOR_REVIEW** (остановка до Codex review). Core prerequisite для create sheet с date/start/duration: `addTask` создаёт задачу с опциональными датой И интервалом одним save, вся валидация до insert.

## Назначение и база

- TASK: `tasks/NATIVE-ADD-003.md`; worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-ADD-003`; ветка `task/NATIVE-ADD-003`.
- Starting SHA `62f87577bf2b5cd7f9539ac4c55a78b35abd431b` — root/branch/HEAD совпали, дерево чистое до изменений.
- База `84672116c6cb05c89f793e7113d81cc444ee64fb` (EDIT-001 принят) — в истории ветки.
- Прочитаны AGENTS.md, ARCHITECTURE.md, tasks/NATIVE-ADD-003.md.

## Изменённые файлы (ровно по scope TASK)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift` | Только расширение `addTask`: два новых необязательных параметра ПОСЛЕДНИМИ — `plannedTime: String? = nil`, `durationMinutes: Int? = nil`. Все существующие вызовы (title/now, title/now/date) работают без правок; undated и dated-untimed разрешены; nil/nil → без интервала. Вся валидация кандидата ДО `OrbitTask.init`/insert/save: `TaskTitle.validated` → `TaskPlannedDate.isValid` → `TaskTimeInterval.isCompletePair` (частичная пара не игнорируется — `incompletePair`) → `isValidTime` → `isValidDuration` + `isWritableDuration` (write-минимум 5…1440, НЕ шаг 5: 6/7 валидны) → для timed-кандидата присутствие явной даты (`missingDate`, никакого silent «today») и derived end через `TaskTimeInterval.end` (`endOutOfRange`). Только существующие error cases; без новых validators/Calendar/UTC/DST/rounding. Далее один `OrbitTask(title:createdAt:plannedDate:plannedTime:durationMinutes:)` (один UUID, createdAt от caller, completion nil), ровно один explicit `context.save` с существующим rollback/rethrow; derived end не хранится. Doc-комментарий обновлён (ADD-001/ADD-003). `renameTask`/`deleteTask`/`setPlannedDate`/`setPlannedInterval` не рефакторились. |
| `apple/Orbit/Tests/OrbitCoreTests/OrbitTaskStoreTests.swift` | 8 новых тестов в секции `NATIVE-ADD-003` (см. ниже). Существующие тесты не менялись (совместимость сигнатуры). TestSupport/TempDir прежние; только синтетические уникальные temp store. |

Не менялись: OrbitTask (model/schema), UI (iOS/macOS), pure helpers (`TaskTimeInterval`/`TaskPlannedDate`/`TaskTitle`), root docs, web.

## Новые тесты (соответствие п.4 TASK)

1. `addTimedTask` — same-day timed create (14.10.2026, 09:00, 30): все поля + UUID/createdAt, completion nil; derived end «09:30» только вычисляется, не хранится; ровно одна строка.
2. `addTimedOvernightAndNonStepDurations` — overnight 23:30/90 (derived end 15.10 01:00, в строке остаётся 14.10); start 09:08 с duration 5/6/7 — валидны (минимум ≠ шаг); счётчик строк корректен.
3. `addTimedRequiresDate` — time без даты → `missingDate`; НЕТ новой строки (в т.ч. undated), fixture нетрогнута; валидный retry с датой работает.
4. `addPartialPairRejected` — (nil, 30) и ("09:00", nil) → `incompletePair`; ноль строк; retry полной пары работает.
5. `addTimedInvalidDateOrTime` — `2026-13-40` → `TaskPlannedDateError.invalid`; `24:00`, `9:00` → `invalidTime`; fixture (датированная completed-подобная timed задача) сохраняет ВСЕ поля; retry валиден.
6. `addTimedDurationGate` — 0, 1…4, 1441, Int.max → `invalidDuration`; ноль строк; retry с 30 работает.
7. `addTimedEndOutOfRange` — 2199-12-31 23:30 + 60 → `endOutOfRange`; ноль строк; 22:00+60 в границах принимается.
8. `addDefaultsAndDiskReopen` — совместимость (plain / dated-untimed без интервала); disk reopen: timed строка сохраняет UUID/title/createdAt/completion nil/date/time/duration; все три строки на месте.

Отказы в матрице происходят ДО insert (валидация до мутаций) — «no-new-row» отражает именно это; runtime save failure не симулировался и не выдаётся за rollback proof (по TASK).

## Проверки (фактические)

| Проверка | Результат |
| --- | --- |
| `swift test --scratch-path /tmp/orbit-add003-scratch --filter OrbitTaskStore` (DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer) | **44/44 passed** (Suite "OrbitTaskStore": 36 прежних + 8 новых) |
| `xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-add003-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | **BUILD SUCCEEDED** (exit 0) |
| `git diff --check` | чисто; дерево после коммитов чистое |

Без full core suite/web/db/auth/GUI/device/legacy migration — по TASK (schema/UI не менялись). PASS не повторялся.

## UNVERIFIED / ограничения

- Runtime disk failure при save (rollback-ветка) не симулировался — без fault injection framework; код-путь унаследован от принятого addTask.
- GUI-использование нового API (create form с date/start/duration) — следующий TASK ADD-004, здесь сознательно отсутствует; UI не менялся, реальное поведение формы не проверялось.
- Реальное устройство/тёмная тема — вне TASK.
- Тесты используют только синтетические temp store; реальные/пользовательские store не открывались.

## Гигиена

- Один обычный scoped commit (код) + commit отчёта; без merge/push/amend/rebase/reset/stash/clean/deploy; main и чужие worktrees не трогались; xcode-select/signing/hooks/systemsettings не менялись.
- Cleanup только собственных ресурсов: `/tmp/orbit-add003-scratch`, `/tmp/orbit-add003-dd` удалены.
- ADD-004/UI create form/EDIT-002/дедлайны/напоминания/notifications/Projects/drag/resize/3days/Month/AI не начинались.

## Git

- Код: `f64cabc0b388f8d20f1f373bb0e44e913ec3e9d2` (единственный кодовый commit от базы `62f87577bf2b5cd7f9539ac4c55a78b35abd431b`).
- Отчёт: финальный commit ветки (SHA в чате).
