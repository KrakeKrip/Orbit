# Orbit — журнал решений

2026-10-08. Этап INITIAL SETUP; все решения целевые, реализация не начата.

- ADR-001 — Репозиторий /Users/atlhnv/Orbit: здесь обнаружены исходные спецификации, этот путь указан в поручении. Папка чата используется только для временных материалов. main + task/TASK-NNN, один локальный worktree на задачу в /Users/atlhnv/Codex/orbit-worktrees/. Удалённый репозиторий не подключён.
- ADR-002 — Next.js App Router + TypeScript, Tailwind + shadcn/ui, PostgreSQL + Drizzle, Better Auth + Zod. Монолит с service layer проще личного проекта; owner filtering с первого data TASK обеспечивает будущих отдельных пользователей без shared projects.
- ADR-003 — npm, Node 24 LTS, стабильные совместимые пакеты и lockfile. Точные версии проверяет и фиксирует GLM в TASK-001 по официальным источникам; не использовать prerelease или latest без проверки совместимости.
- ADR-004 — planned_date отдельно от deadline_date; DATE/TIME для календарного плана, timestamptz для событий, IANA timezone аккаунта. Today имеет отдельные deadline warnings без переноса плана.
- ADR-005 — Completion recurrence защищается transaction + revision + idempotency key. Unique occurrence date без revision не защищает от разных ключей двойного клика; счётчик версии исключает завершение следующего повторения.
- ADR-006 — Вложенность один уровень, archive скрывает задачи из активных списков без удаления, soft delete родителя охватывает детей; перемещение родителя переносит детей в транзакции. Так не остаются несогласованные ссылки и неоднозначные действия дерева.
- ADR-007 — Public signup выключен server-side; первый аккаунт через локальную одноразовую процедуру. Обязательные ownership integration tests с двумя пользователями; MCP/OAuth, приглашения и регистрация вне MVP.
- ADR-008 — PWA online-only, без offline data cache. Проверка manifest не равна проверке установки на iPhone. Deployment и VPS/VPN работы только по отдельному поручению.
- ADR-009 — Старый CODEX_PROMPT.md сохранён, но больше не действующий TASK. Codex координирует/reviews; GLM получает только TASK-001, дальнейшие TASK ещё не выданы.

- ADR-010 — Уточнение пользователя: web first, затем iOS/macOS, возможно Telegram; офлайн позднее. Сохраняем стек и общий service layer; до CRUD уточняем versioned HTTP API для внешних клиентов, Server Actions не единственный transport. Технологии native UI/Telegram format/auth пока не утверждены.
- ADR-011 — TASK-001 независимо проверен и интегрирован локальным merge 25a0a9ca47e337a02dd4d4ffe14001f90744b8fc. Foundation tests/build/HTTP/browser проходят на Node 24.21.0. Принят неблокирующий dev-tooling риск: braces advisory без патча и unsupported ESLint 9; production audit 0, повторить проверку обновлений до deployment. Подробности — reports/TASK-001.md. Remote/push/deploy отсутствуют.
