# NATIVE-003-R1 — Gregorian storage adapter

Одна коррекция review. Worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-003, branch task/NATIVE-003. Начать от coordinator review HEAD (full SHA в handoff), проверить root/branch/status. Прочитать AGENTS.md, tasks/NATIVE-003.md, reports/NATIVE-003.md.

Scope только apple/Orbit/Sources/OrbitCore/TaskPlannedDate.swift, Tests/OrbitCoreTests/TaskPlannedDateTests.swift и reports/NATIVE-003-executor.md. Model/store/schema/iOS sheet/layout/пакет/macOS/coordination docs не менять.

Причина: оба UI adapters используют supplied Calendar целиком, который может быть non-Gregorian. Исправить year/month/day интерпретацию на Gregorian в ОБОИХ направлениях, сохранив timezone supplied calendar/local default. Сигнатуры/строгая1900–2199 ASCII YYYY-MM-DD validation и nil semantics не меняются. Не нормализовать invalid date, не конвертировать local day в UTC day, не менять persisted strings.

Минимальная реализация: внутренний Gregorian calendar с timezone входного calendar, использовать его для extraction/construction. Комментарии привести к фактическому noon adapter. Не добавлять dependencies/new files/fault frameworks.

Регрессии: Buddhist timezoneUTC + knownGregorian2026-10-13 -> canonical2026-10-13 (не2569), обратное чтение canonical2026-10-13 -> тот же Gregorian date (не1483). Ещё один non-Gregorian календарь, например Islamic civil. Прежние Moscow/NewYork local day/roundtrip и invalid-value checks сохраняются. Проверять реальный Gregorian result, не только симметричный roundtrip двух неверных helpers. System calendar settings не менять.

Checks: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test, swift build; один iOS Simulator build CODE_SIGNING_ALLOWED=NO. Новый GUI/full legacy прогон не нужен для этого pure fix; GUI change остаётся честно непроверенным. Web/npm/DB/auth/E2E не запускать. В executor report явно отличить invalid-before-save tests от непроверенной runtime save failure/rollback ветки.

Обычный новый scoped commit, git diff --check, clean tree. Полный report только reports/NATIVE-003-executor.md; чат4–5коротких строк статус/fullSHA/итог/checks/report. Остановиться до review; NATIVE-004/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy, main/чужие worktrees/CRM/3000/hooks/xcode-select/signing не менять.
