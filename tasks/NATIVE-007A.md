# NATIVE-007A — проекция интервалов на календарный день

DONE, 2026-10-13. Review PASS reports/NATIVE-007A.md; локальный merge 9c499d4e81c251b2f8c2b93d70ff94202a374a88. Исходный scope сохранён. Один маленький результат: read-only данные для будущей суточной сетки 00:00–24:00, включая продолжение через полночь. UI сетки отдельно в NATIVE-007B; не реализовывать календарь целиком.

## Старт / scope

Review/source base `2b14c779ad2abff50e6b30bc87457c8f9e580fb2` — принятый NATIVE-006, core56/iOS build PASS. Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007A`, branch `task/NATIVE-007A`; starting SHA — assignment HEAD из handoff. Перед правками проверить root/branch/HEAD/status, прочитать AGENTS/ARCHITECTURE/tasks/NATIVE-007A.md. Исторические assignments не выполнять.

Ровно ОДИН product файл: новый `apple/Orbit/Sources/OrbitCore/TaskDayProjection.swift`. Targeted test: новый `apple/Orbit/Tests/OrbitCoreTests/TaskDayProjectionTests.swift`. Краткая секция apple/Orbit/README.md и reports/NATIVE-007A-executor.md разрешены. Существующие core helpers/model/store/tests, iOS/macOS UI, project/scheme, root docs/web не менять. Никаких новых targets/dependencies/layers. Это не store operation, миграций/новых entity fields нет.

## Read contract

Маленький pure helper получает explicit selected civil day и массив OrbitTask. Return value содержит список UUID задач без времени и timed segments. Простой public API/struct, без протоколов/repositories/SwiftUI geometry; выбранную форму зафиксировать в отчёте. Значения read-only, без изменения tasks, без новых task UUID или сохранения derived end.

- selected day строго Gregorian YYYY-MM-DD1900...2199 через принятый TaskPlannedDate. Невалидный/nil day -> пустой result, без throw/crash.
- Untimed: plannedDate==selected day и оба interval fields nil; UUID в исходном порядке. Завершённые НЕ исключать: фильтр/стиль completion будущего UI отдельно.
- Timed: валидные date/time/duration и derived end через принятый TaskTimeInterval.end. Нельзя дублировать civil календарную арифметику или добавлять Date/Calendar/timezone/DST конверсии; минуты HH:mm — простая bounded integer арифметика после валидации. Повреждённые partial/invalid inputs исключаются, не чинятся/не пишутся.
- Каждый segment содержит существующий taskID, selected day, startMinute/endMinute внутри0...1440 (half-open interval [start,end), start<end), признаки продолжения с предыдущего/на следующий день. Stable identity task UUID+selected day, не новый random UUID при каждом чтении. Один segment на task/selected day для обычного unique-task массива store.
- Same-day09:00/30 ->540...570.
- 23:30/90 на2026-10-13 -> выбранный13:1410...1440, continuation into next; выбранный14:0...60, continuation from previous. На другие даты segment отсутствует. Это отличается от принятого Today LIST, который по-прежнему выбирает только start date; его не менять.
- End ровно в midnight:23:30/30 ->13:1410...1440;14:НИ ОДНОГО segment нулевой длины. Continuation flags означают положительную часть в соседнем дне, поэтому exact-midnight НЕ имеет continuation into next. Duration1440/start00:00 -> один полный segment0...1440 на стартовом дне, на следующем ничего; start09:00/duration1440 -> стартовый540...1440 и следующий0...540.
- Range boundary1900/2199 respected: TaskTimeInterval.end nil -> исключение invalid interval из результата, без clipping неверного значения/overflow. Принятые диапазоны/validation не менять.
- Segments в chronological order startMinute ASC, endMinute ASC, taskID UUID-string ASC для стабильных ties. Untimed отдельно; без искусственной привязки к00:00.
- Пересекающиеся задачи все сохраняются отдельными segments (например09:00/60 и09:30/60). НЕ назначать lanes/columns, не объединять/скрывать overlapping tasks: это visual layout007B, не этот TASK.

Не добавлять default today, recurrence/deadline/overdue, task mutations, notifications или clock scheduler. Данные/правила одни для будущих Day/3days, но три дня/Месяц сейчас не делать.

## Соразмерные проверки

Targeted deterministic tests: same-day; untimed/other-day/nil; exact midnight без zero segment; overnight обе даты/flags; duration1440 оба случая; completed inclusion; invalid day/partial/time/duration включая Int.max; range end rejection; overlap сохранён и sort/ties stable; repeated result stable IDs и отсутствие изменения input fields. Fixed civil strings/minutes, без system calendar/реального clock. Прежние56 tests сохранить.

Один `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` в apple/Orbit, один iOS Simulator build CODE_SIGNING_ALLOWED=NO в own DerivedData (shared core compile regression). Без GUI/Simulator device/screenshots: UI в007A отсутствует. Без legacy fixture/web/DB/auth/npm/7200oracle или повторов full gates по привычке. Не менять xcode-select/Apple ID/signing/личные stores/чужие simulators/Colima/CRM/3000/hooks. Cleanup только own temp после сохранения нужных логов.

## Передача

Обычный scoped commit, git diff --check/clean tree. ПОДРОБНЫЙ отчёт В ФАЙЛ reports/NATIVE-007A-executor.md: start/latest SHA, files/API, commands/exits, фактические tests/границы/непроверенное. В чат только4–5коротких строк: статус/full SHA/итог/checks/report. Не называть календарную сетку реализованной. Остановиться до Codex review;007B/3days/Месяц/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy, main/другие worktree/root docs не менять.
