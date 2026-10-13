# NATIVE-007A-R1 — midnight flag и детерминированный sort test

DONE, 2026-10-13. Source addcfd3, R1/R2 повторное review PASS. Одна небольшая коррекция helper + tests по reports/NATIVE-007A.md (R1/R2). Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007A`, branch task/NATIVE-007A. Product review SHA1e53a778fe92b91ef00b97254edaa122c691e5d5; starting correction SHA — coordinator HEAD из handoff. Проверить root/branch/HEAD/status, прочитать AGENTS/review/этот TASK.

Scope: только TaskDayProjection.swift, TaskDayProjectionTests.swift, R1-секция reports/NATIVE-007A-executor.md. Если README содержит неверное описание exact-midnight flag, разрешено только уточнить эту строку. Root docs/accepted helpers/model/store/UI не менять.

1. Exact-midnight continuesIntoNextDay=false:23:30/30 и00:00/1440 не имеют positive coverage следующего дня. Исправить минимально в ветке стартового дня, без переработки segment geometry/next-day selection. Сохранить true для23:30/90 и09:00/1440, отсутствие zero-length segment, все прочие contracts.
2. Исправить ошибочный exactMidnight assertion true→false, дополнить assert false для full-day00:00. Sort-test: разные ends555/600 проверяют end-priority, а не UUID-sort. Отдельный настоящий tie — SAME start/end, fixed UUID, input reverse UUID order, assert ожидаемые UUID. Сохранить overlap/minutes assertions; comparator продукта корректен, не менять его.

Один targeted swift test --filter TaskDayProjection с DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer. Один iOS Simulator build CODE_SIGNING_ALLOWED=NO в own DerivedData. Core66 уже независимо проверены, full suite/legacy/web/DB/GUI/7200oracle повторять не надо. Никаких devices/screenshots/frameworks; UI007B отсутствует. Доказать в отчёте exact flags и deterministic equal-start/end IDs. Если были диагностические прогоны — честно указать, не назначать повторения по привычке.

Обычный новый scoped commit, diff --check/clean tree. Подробный отчёт СОХРАНИ В ФАЙЛ reports/NATIVE-007A-executor.md, не в чат; чат4–5коротких строк: статус/full SHA/итог/checks/report. Остановиться до Codex review;007B/3дня/Месяц/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktree/CRM/3000/hooks/xcode-select/signing не трогать.
