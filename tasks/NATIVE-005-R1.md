# NATIVE-005-R1 — название задачи в редакторе интервала

DONE, 2026-10-13. Product961cc2d, повторное review PASS. Один небольшой результат: редактор явно показывает, какую задачу редактируем. Review: reports/NATIVE-005.md, R1 [P2].

Работать в `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-005`, ветка `task/NATIVE-005`. Product review SHA `aa22fdce6cd662df5143555a2e0a72a3ef956636`; старт коррекции — coordinator HEAD из handoff. До правок проверить Git root/branch/HEAD/status, прочитать AGENTS и эти два документа.

Scope: только `apple/OrbitIOS/OrbitIOS/TaskIntervalSheet.swift` и секция R1 в `reports/NATIVE-005-executor.md`. Внутри sheet видимо отобразить текущий task.title, отдельно от generic «Время задачи» и подписи даты. Native стиль, перенос длинного названия, Dynamic Type; без жёсткой высоты или однострочного обрезания. При открытии другой задачи название актуальное. Не менять сохранение/draft/валидацию/поля/controls, core, Inbox/model/date editor, Xcode project, root docs или другие задачи.

Один iOS Simulator build с DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer, CODE_SIGNING_ALLOWED=NO и own DerivedData. GUI на own temporary Simulator: редакторы двух synthetic задач показывают свои названия, длинное название читается, поля и Save доступны прокруткой/с клавиатурой. Открытие и Cancel не пишут. Сохранить один screenshot editor вне product tree. Если tooling не позволяет действие — честно указать, не тратить часы на обходы. Core50 уже проверены и не меняются: не повторять core/web/legacy/full gates и не добавлять тестовый framework.

Обычный новый scoped commit, git diff --check/clean tree. Подробный отчёт В ФАЙЛ reports/NATIVE-005-executor.md; чат только 4–5 коротких строк: статус/full SHA/итог/checks/report. Остановиться до Codex review. Без merge/push/amend/rebase/reset/stash/deploy, main/чужие worktrees/CRM/3000/hooks не трогать, NATIVE-006 не начинать.
