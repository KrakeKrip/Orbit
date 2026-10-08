# Orbit — правила координации

Этап: FOUNDATIONS завершён; TASK-001–005 приняты и локально интегрированы. Auth и account timezone/theme settings проверены, task/project CRUD ещё отсутствует. TASK-006 не выдан. Codex работает в /Users/atlhnv/Orbit, ветка main.
GLM работает только в назначенном отдельном worktree и выполняет один TASK.

## Роли и источники требований
- Пользователь утверждает продуктовые решения и передаёт задания между агентами.
- Codex: архитектура, документация, TASK, независимый review и локальная интеграция.
- GLM: реализация только назначенного TASK, самопроверка, обычные коммиты и отчёт.
- Прямые актуальные инструкции пользователя имеют приоритет. Далее AGENTS.md определяет процесс; PRODUCT.md — поведение, ARCHITECTURE.md — технические контракты, DESIGN.md — интерфейс. TASK ограничивает объём; при конфликте исполнитель возвращает BLOCKED, а не расширяет задачу.
- CODEX_PROMPT.md сохранён как исторический документ; его поручение реализовать Milestone 0 целиком больше не действует.
- План архитектуры не является подтверждением реализации. Изменения архитектуры согласуются с Codex и фиксируются в DECISIONS.md.

## Один TASK — одна ветка — один worktree
1. Codex фиксирует координационные документы и базу сравнения, создаёт task/TASK-NNN и отдельный worktree вне исходников.
2. Пользователь передаёт GLM путь и TASK. Локальный worktree доступен лишь исполнителю на том же компьютере; облачная доступность не подразумевается.
3. GLM проверяет корень Git, ветку и status перед изменениями. При чужих изменениях останавливает затронутую работу.
4. GLM делает обычные новые коммиты и возвращает READY_FOR_REVIEW либо BLOCKED, ветку, полный SHA, изменения, фактические проверки и ограничения.
5. Codex проверяет все коммиты от указанной базы, scope, ownership, ошибки и критерии; самостоятельно запускает релевантные проверки.
6. Замечания: NEEDS_FIXES, reports/TASK-NNN.md, исправления в той же ветке новыми коммитами.
7. После успешного review: локальный merge --no-ff в чистую main, интеграционные проверки, статус DONE и отчёт. Следующий TASK только после приёмки или явного приостановления.

Статусы: TODO, IN_PROGRESS, REVIEW, NEEDS_FIXES, BLOCKED, DONE.
TODO означает в том числе подготовленную, но ещё не запущенную задачу.

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
