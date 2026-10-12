# Orbit — правила координации

Этап: EVERYDAY CORE. TASK-001–007 приняты и локально интегрированы. Работают auth, account settings, Projects и реальные one-off задачи в Inbox: create/rename/complete/reopen/soft delete. TASK-007 DONE после R1/R2/R3/R3b и main integration gates. TASK-008 реализован GLM, но review SHA 6388a08 дал NEEDS_FIXES: reports/TASK-008.md. R1 принят на 3b3688a (reports/TASK-008-R1.md). R2a принят на 437e5a2 (reports/TASK-008-R2a-fix.md). R2b1 принят на c68d3a8 (reports/TASK-008-R2b1.md). R2b2 принят на 9d9566e (reports/TASK-008-R2b2-fix.md). R2b3 принят на 0274215 (reports/TASK-008-R2b3.md). R2b4 принят на 15c5487 (reports/TASK-008-R2b4.md), R2 закрыт целиком. R3a product fix принят на 18f13ba (reports/TASK-008-R3a.md). R3b принят на 54780f1 (reports/TASK-008-R3b.md), R3 закрыт целиком. R4 принят на 6937135 (reports/TASK-008-R4.md). R5 принят на a4e8a84 (reports/TASK-008-R5.md). R6 принят на ed07ce2 (reports/TASK-008-R6.md). R7 принят на 3b1bd40 (reports/TASK-008-R7.md). R8 product fix принят на 01ac0ce (reports/TASK-008-R8.md), test finally cleanup закрыт на 34998ae; остаётся auth expiry fixture (reports/TASK-008-FINAL.md). Сейчас назначена только tasks/TASK-008-FINAL-EXPIRY.md: test-only auth expiry fixture; остальные замечания выдаются отдельно. Codex работает в /Users/atlhnv/Orbit, ветка main.
GLM работает только в назначенном отдельном worktree и выполняет один TASK.

## Роли и источники требований
- Пользователь утверждает продуктовые решения и передаёт задания между агентами.
- Codex: архитектура, документация, TASK, независимый review и локальная интеграция.
- GLM: реализация только назначенного TASK, самопроверка, обычные коммиты и отчёт.
- Прямые актуальные инструкции пользователя имеют приоритет. Далее AGENTS.md определяет процесс; PRODUCT.md — поведение, ARCHITECTURE.md — технические контракты, DESIGN.md — интерфейс. TASK ограничивает объём; при конфликте исполнитель возвращает BLOCKED, а не расширяет задачу.
- CODEX_PROMPT.md сохранён как исторический документ; его поручение реализовать Milestone 0 целиком больше не действует.
- План архитектуры не является подтверждением реализации. Изменения архитектуры согласуются с Codex и фиксируются в DECISIONS.md.

## Один TASK — одна ветка — один worktree
Размер новых заданий: один конкретный проверяемый результат, небольшой scope. По уточнению процесса после жалобы пользователя на медленный темп (2026-10-09), один и тот же дефект в 2–3 файлах можно закрывать одним небольшим TASK. Не объединять новые API/UI/бизнес-правила или большую переработку контроллеров. После коррекции — релевантные targeted checks; full gates — перед итоговой приёмкой, без повторов без новой причины. Блокирующие ошибки исправлять сразу, мелкую уборку собрать в финальный проход. Для TASK-008 Продуктовые R1–R8 закрыты; назначен только tasks/TASK-008-FINAL-EXPIRY.md (один auth test + full auth gate). Остальные findings выдаются отдельно. Огромные задания для GLM Flash по-прежнему запрещены.

1. Codex фиксирует координационные документы и базу сравнения, создаёт task/TASK-NNN и отдельный worktree вне исходников.
2. Пользователь передаёт GLM путь и TASK. Локальный worktree доступен лишь исполнителю на том же компьютере; облачная доступность не подразумевается.
3. GLM проверяет корень Git, ветку и status перед изменениями. При чужих изменениях останавливает затронутую работу.
4. GLM делает обычные новые коммиты и возвращает READY_FOR_REVIEW либо BLOCKED, ветку, полный SHA, изменения, фактические проверки и ограничения.
5. Codex проверяет все коммиты от указанной базы, scope, ownership, ошибки и критерии; самостоятельно запускает релевантные проверки.
6. Замечания: NEEDS_FIXES, reports/TASK-NNN.md, исправления в той же ветке новыми коммитами.
7. После успешного review: локальный merge --no-ff в чистую main, интеграционные проверки, статус DONE и отчёт. Следующий TASK только после приёмки или явного приостановления.

Статусы: TODO, IN_PROGRESS, REVIEW, NEEDS_FIXES, BLOCKED, DONE.
TODO означает в том числе подготовленную, но ещё не запущенную задачу.

## Формат отчёта исполнителя
Подробный отчёт GLM сохраняет в reports/TASK-NNN-executor.md. В чат только 4–5 коротких строк: статус, full SHA, итог, целевые checks и путь к отчёту. Не выводить подробный отчёт в чат. Прямое указание пользователя от 2026-10-09.

## Ограничения
- Codex не реализует продуктовые задачи за GLM без прямого указания пользователя.
- GLM не меняет корневые координационные документы без явного scope; отчёт исполнителя — reports/TASK-NNN-executor.md, отчёт review — reports/TASK-NNN.md.
- GLM не делает merge, rebase, amend, reset, force push и не меняет другие ветки.
- Push, deployment и изменение действующих серверов требуют отдельного разрешения. Не изменять VPN и сторонние проекты.
- Не удалять пользовательские файлы, не перезаписывать чужую работу, не делать автоматический stash, не переписывать историю.
- Не коммитить секреты, .env, реальные персональные данные и дампы. Не запускать миграции против неизвестной или production БД.
- Не считать сборку доказательством GUI, авторизации или работы на реальном устройстве. Явно отделять проверенное от непроверенного.

## Проверки
TASK-001 добавил package.json, npm scripts dev/start/lint/typecheck/test/build и README. Целевой runtime Node 24 LTS. Review — reports/TASK-001.md; тесты foundation не подтверждают будущие DB/auth/task flows.
Дальнейшие проверки соразмерны изменениям: правила дат — unit, безопасность — integration с двумя пользователями, интерфейс — browser/E2E и мобильные размеры.

TASK-002 добавил test:e2e (production build + Chromium). Для независимого запуска: CI=1 E2E_PORT=<свободный loopback port> npm run test:e2e; CI=1 исключает reuse стороннего сервера. После TASK-002 текущая регрессия: 4 Vitest и 47 browser tests. Проверки интерфейса не подтверждают auth/DB.

TASK-003 добавил PostgreSQL/Drizzle schema и миграции; npm run test:db — отдельная local PostgreSQL suite: 47 tests (28 schema,15 guard,4 runner), TEST_DATABASE_URL явный, namespace orbit_test, per-run unique DB/fixture без удаления существующих БД. Production build/UI tests по-прежнему не требуют env/БД. Auth flows/CRUD ещё отсутствуют. Audit/tooling ограничения и review — reports/TASK-003.md.

TASK-004 принят после R1/R1b/R2/R3/R3b/R3c: 4 UI/47 DB/31 auth/56 browser checks, настоящий CLI PTY и аварийный E2E exit-status проверены. Main build без env PASS; runtime auth требует env и bootstrap. Auth/E2E только собственные unique DB, фактический app pool закрывается до DROP; completion result связывает shutdown status с итогом runner. Review — reports/TASK-004.md. TASK-005 settings persistence принят, review — reports/TASK-005.md.

TASK-005 DONE: GET/PATCH /api/v1/settings, account defaults UTC/system, owner-scoped field-specific upsert, IANA validation, account theme bridge и Settings UI. Main 15 pure/UI/47 DB/51 auth/63 E2E и build без env PASS. Delayed response/account switch/timezone pending и реальный dev StrictMode success/error проверены. Реальные устройства/production не проверены; timezone алгоритмы расписания и CRUD — следующие TASK.

TASK-006 DONE: owner-scoped project service и GET/POST collection, GET/PATCH item, реальный /projects с active/archive, Unicode names и pending rename guard. Main 29 unit/47 DB/72 auth/71 E2E и no-env build PASS; review — reports/TASK-006.md. Archive сохраняет связанные tasks; project task list/delete/reorder/sharing вне scope. Реальные устройства/deployment не проверены.

TASK-007 DONE: tasks API/service с owner-scoped transactions, completion journal/no-op/reopen/soft delete; Inbox quick-add/rename/complete/reopen/delete confirmation. Read/network errors отделены от write outcomes; pending actions и keyboard focus/error/cancel/retry проверены. Main 44 unit/47 DB/101 auth/83 E2E и no-env build PASS. Dates/notes/priority/project assignment/subtasks/recurrence UI ещё отсутствуют; реальные устройства/deployment не проверены. Review — reports/TASK-007.md.
