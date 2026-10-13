# NATIVE-007A — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007A`; ветка `task/NATIVE-007A`; **starting SHA `8b98ed88a4856c59846ad5056a7326a3d0405f3b`**; review/source base `2b14c779ad2abff50e6b30bc87457c8f9e580fb2` (merge-base совпадает — принятый NATIVE-006 + R1, core 56); дерево чистое, чужих изменений нет.
- Прочитаны AGENTS/ARCHITECTURE/tasks/NATIVE-007A.md; macOS-R1/web PAUSED, не трогались.
- Tooling: Xcode 27.0 через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `xcode-select`/signing не менялись.

## Изменённые файлы (ровно 1 product файл + тест + README + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/TaskDayProjection.swift` (**новый**, единственный product-файл) | `struct TaskDayIntervalSegment` (taskID, day, startMinute, endMinute, continuesFromPreviousDay, continuesIntoNextDay; half-open `[start, end)`, start<end); `struct TaskDayProjection` (day, untimedTaskIDs, timedSegments; Equatable, public init); `enum TaskDayProjector` с единственной pure-функцией `project(day:in:) -> TaskDayProjection` |
| `apple/Orbit/Tests/OrbitCoreTests/TaskDayProjectionTests.swift` (**новый**) | 9 тестов по списку TASK (см. ниже) |
| `apple/Orbit/README.md` | одна краткая секция «Проекция интервала на календарный день (NATIVE-007A, read-only)» |
| `reports/NATIVE-007A-executor.md` | этот отчёт |

Не менялись: model/store/TaskPlannedDate/TaskTimeInterval/TaskTitle/TaskDaySelection/store location, macOS/iOS UI/project/scheme/root docs/web. Никаких новых targets/dependencies/layers; это не store operation, entity fields/migrations нет.

## API (зафиксированная форма)

```swift
TaskDayProjector.project(day: String?, in tasks: [OrbitTask]) -> TaskDayProjection
// TaskDayProjection { day: String; untimedTaskIDs: [UUID]; timedSegments: [TaskDayIntervalSegment] }
// TaskDayIntervalSegment { taskID: UUID; day: String; startMinute: Int; endMinute: Int;
//                          continuesFromPreviousDay: Bool; continuesIntoNextDay: Bool }
```

Правила: `day` строго Gregorian `YYYY-MM-DD` 1900–2199 через `TaskPlannedDate.isValid`; invalid/nil → пустые списки (без throw). Untimed: `plannedDate == day`, оба interval-поля nil → UUID в исходном порядке; завершённые не выбрасываются. Timed: полная валидная пара + `TaskTimeInterval.end` (принятый helper;civil-день арифметика не дублируется, Date/Calendar/timezone не добавлены — только bounded minutes-арифметика строк HH:mm после валидации). Same-day → `start…end` на дне; overnight → `start…1440` + `continuesIntoNextDay` на дне старта и положительный `0…end` + `continuesFromPreviousDay` на дне `end.date == day` (сравнение ISO-строк в 1900–2199 хронологично, что избавляет от отдельной арифметики «вчера»); end ровно в полночь не даёт zero-length сегмента. Range-reject: `end == nil` → исключение без clipping. Corrupt partial-пары исключаются, не чинятся. Overlaps — отдельные сегменты, без lanes. Сортировка: startMinute ASC → endMinute ASC → taskID.uuidString ASC. Identity сегмента = существующий task UUID + selected day; повторные чтения стабильны; входные задачи не изменяются.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift test` (apple/Orbit, DEVELOPER_DIR, финальный) | exit 0 — **66 тестов / 8 suites** (существующие 56 зелёные + 10 новых TaskDayProjection) |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n7a-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — BUILD SUCCEEDED (shared-core compile regression; DerivedData удалён) |
| Промежуточные итерации | 3 compile-фикса моих же новых файлов: (1) result-struct `TaskDayProjection` отсутствовал — enum helper носил его имя; введён struct + enum переименован в `TaskDayProjector`; (2–3) тест-опечатки (makeTask без `date:`, tuple `(Int,Int)?` не Equatable — заменено сравнением массивов `[[start,end]]`) |

## Тестовое покрытие (все fixed civil strings/minutes, без system calendar/часов)

- Same-day 09:00/30 → 540…570, флаги false; untimed в отдельном списке в исходном порядке.
- Untimed-фильтр по дню: Банк(13) vs Вчера(12)/undated.
- Overnight 23:30/90: день 13 → 1410…1440 + `continuesIntoNextDay`; день 14 → 0…60 + `continuesFromPreviousDay`; 12/15 — пусто.
- Exact midnight 23:30/30: день 13 → 1410…1440 (flag), день 14 → **пусто** (никакого zero-length сегмента).
- Duration 1440: старт 00:00 → один полный 0…1440, на следующий день ничего; старт 09:00 → 540…1440 + следующий день 0…540.
- Completed не выбрасываются.
- Invalid: partial-пара (только время), время 24:00, duration 0, Int.max; invalid/nil выбранные дни (2026-13-01/not-a-date/nil) → пусто, без crash.
- Range: 2199-12-31 23:59+1 → исключено без clipping; 23:58+1 → 1439 на месте.
- Overlap 09:00/60 + 09:30/60 + 09:00/15 → три отдельных сегмента, сортировка [[540,555],[540,600],[570,630]], tie 540 по UUID-строке.
- Повторное чтение: `first == second` (Equatable), identity task.id + day; входные поля не изменены.

## Ограничения / не проверено

- GUI/Simulator device/скриншоты отсутствуют по TASK — UI сетки в NATIVE-007B; «календарная сетка реализована» НЕ заявляется.
- Часовая сетка/3 дня/Месяц, lanes/columns, overdue — не начинались.
- Реальная смена времени/зоны не выполнялась (helper не принимает Calendar/TimeZone вовсе — детерминирован по построению).
- Swift 6 concurrency-аудит для Sendable сегментов не выполнялся (struct значимого типа, без ссылочных полей).

## Git

- Ветка `task/NATIVE-007A`; starting SHA `8b98ed88a4856c59846ad5056a7326a3d0405f3b`; один scoped commit (helper + тест + README + отчёт); полный latest SHA в чате.
- `git diff --check` чисто; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/чужие worktrees/root docs/CRM/3000/hooks/xcode-select не менялись. 007B/3дня/Месяц/macOS-R1 не начинались.

---

# Коррекция NATIVE-007A-R1 — midnight flag и детерминированный sort test

## Статус

READY_FOR_REVIEW (только R1 [P2] + R2 [P2] из reports/NATIVE-007A.md; остальное не переписывалось). Starting correction SHA `de64a83364b310d82fa251e3a1ca032de8af2137`, дерево чистое до правок.

## Изменения

1. **R1** `apple/Orbit/Sources/OrbitCore/TaskDayProjection.swift` (минимально, ветка стартового дня): `continuesIntoNextDay` теперь `endMinutes(of: end.time) > 0` вместо безусловного `true`. Геометрия сегментов/next-day selection/accepted `TaskTimeInterval.end`/zero-segment exclusion не переделывались. 23:30/30 и 00:00/1440 (end ровно 00:00) → flag false; 23:30/90 и 09:00/1440 → flag true; `continuesFromPreviousDay` на следующем дне не затронут.
2. **R2** `apple/Orbit/Tests/OrbitCoreTests/TaskDayProjectionTests.swift`:
   - `exactMidnight`: assert `continuesIntoNextDay == true` заменён на **false** (старый assert был ошибочен);
   - `fullDayDuration`: добавлен assert `continuesIntoNextDay == false` для full-day 00:00/1440;
   - `overlapAndSort`: оставлена проверка end-priority ([[540,555],[540,600],[570,630]]) без ложного UUID-assertion на разных ends;
   - **новый тест** `uuidTieDeterministic`: настоящий tie — SAME start/end (10:00/30), фиксированные UUID 00000000-…BBBB и FFFFFFFF-…AAAA, входной порядок обратный ожидаемому; assert порядок [BBBB, FFFF…AAAA] и стабильность повторного чтения.

Продуктовый comparator не менялся (он корректен: start → end → UUID). Модель/store/UI/accepted helpers — не тронуты.

## Проверки

| Проверка | Результат |
| --- | --- |
| `swift test --filter TaskDayProjection` (DEVELOPER_DIR) | exit 0 — **11/11 в suite** (10 прежних с исправленными asserts + новый UUID-tie), warnings: 0 |
| Диагностические прогоны | один падающий прогон в процессе (tuple `(Int,Int)?` не Equatable + makeTask без `date:`) — ошибки компиляции тестов, исправлены до финального прогона; продуктовых диагностических прогонов не было |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-r1a-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — BUILD SUCCEEDED; DerivedData удалён |

## Доказательство из тестов

- Exact flags: `exactMidnight` — 1410…1440 + `continuesIntoNextDay == false`, день 14 пуст; `fullDayDuration` — 0…1440 + `continuesIntoNextDay == false`; `overnightBothDays` (без изменений) — 23:30/90: 1410…1440 true + день 14: 0…60 `fromPrevious=true`; 09:00/1440: 540…1440 true + день 14: 0…540.
- Deterministic equal-start/end IDs: `uuidTieDeterministic` — фиксированные FFFF…AAAA/0000…BBBB, вход [later, early], результат сегментов [idEarly(BBBB), idLate(FFFF)], повтор стабилен.

## Ограничения / не проверено

- GUI/симулятор по-прежнему отсутствует по TASK (UI сетки — NATIVE-007B); «календарная сетка реализована» не заявляется.
- Core 66/56 ранее независимо проверялись — не повторялись; web/legacy/DB не запускались; real iPhone не проверен.

## Git

Новый обычный scoped commit (TaskDayProjection.swift + TaskDayProjectionTests.swift + R1-секция отчёта); полный latest SHA в чате. Без merge/push/amend/rebase/reset/stash/deploy; 007B/3дня/Месяц/macOS-R1 не начинались; main/чужие worktrees/CRM/3000/hooks/xcode-select/signing не тронуты.
