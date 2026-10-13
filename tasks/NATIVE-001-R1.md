# NATIVE-001-R1 — fail-closed explicit store path

Статус: TODO. Worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-001; ветка task/NATIVE-001. Начать от coordinator review HEAD, записать полный SHA до правок. Прочитать AGENTS.md, tasks/NATIVE-001.md и reports/NATIVE-001.md.

Одна цель: ошибочная команда с явным --store-path не открывает personal/default store и не создаёт неожиданную базу.

Разрешённые файлы: Sources/OrbitCore/OrbitStoreLocation.swift, Sources/OrbitMac/OrbitMacApp.swift (при необходимости InboxFormatting в InboxModel.swift только для текста launch error), Tests/OrbitCoreTests/OrbitStoreLocationTests.swift, apple/Orbit/README.md и reports/NATIVE-001-executor.md. Store/model/Inbox UX не перерабатывать.

- Default URL только если --store-path отсутствует.
- Присутствующий флаг без значения, пустое/пробельное значение обеих форм, следующий option token вместо path → явная ошибка. Обрабатывать до createDirectory/ModelContainer. Не заменять на default и не подставлять другой путь.
- Валидные формы --store-path <path>, --store-path=<path>, ~ сохранить. Не вводить большой CLI parser/зависимости.
- Startup показывает понятное состояние ошибки; данные/файлы не удаляются. Не писать «данные не изменены» как гарантию произвольного framework failure; для argument validation гарантируется отсутствие открытия store.
- Unit: absent flag default; обе valid формы; missing/empty/whitespace/next-option ошибки. README должен совпадать с поведением.
- Уточнить executor report: existing validation/open tests не покрывают реальный context.save failure/rollback branch. Не добавлять SQLite fault triggers в продукт и не обходить framework assertion.

Checks: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build и swift test; targeted launch с invalid override на собственном wrapper/временном окружении если GUI доступен — error state, без default store. Default personal store не открывать. Web/full iOS suites не запускать. xcode-select не менять.

Обычный scoped commit, git diff --check. Полный отчёт только в reports/NATIVE-001-executor.md; чат 4–5 строк (READY_FOR_REVIEW/BLOCKED,full SHA,итог,checks,путь). Остановиться до review. Без merge/push/amend/rebase/reset/stash/deploy; NATIVE-002 не начинать.
