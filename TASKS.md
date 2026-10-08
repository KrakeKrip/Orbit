# Orbit — очередь MVP

Этап FOUNDATIONS, 2026-10-08. TASK-001–004 приняты и локально интегрированы после независимого review. Реализованы foundation, UI shell/themes, PostgreSQL/Drizzle schema/migrations и Better Auth login/logout/bootstrap/session boundary. CRUD, account preferences и реальные задачи в интерфейсе ещё отсутствуют. TASK-004 DONE, review — reports/TASK-004.md. TASK-005 подготовлен для GLM: tasks/TASK-005.md, отдельная ветка/worktree, TODO до исполнения.
Статусы: TODO → IN_PROGRESS → REVIEW → DONE; NEEDS_FIXES / BLOCKED при необходимости.
Каждый следующий TASK зависит от успешной интеграции предыдущего. Строка очереди не разрешает начать реализацию.

| TASK | Статус | Результат и граница приёмки |
| --- | --- | --- |
| TASK-001 | DONE | Next.js/TS/Tailwind foundation, npm scripts, Vitest smoke, локальный README; без app shell, auth и DB |
| TASK-002 | DONE | shadcn/ui, дизайн-токены, local light/dark/system, desktop sidebar и mobile bottom navigation с пустыми экранами; 360/390/768/1280 px и keyboard smoke |
| TASK-003 | DONE | Локальный PostgreSQL Compose, Drizzle, schema/migrations с owner/FK/check constraints и completion revision; apply на пустую dev DB, без auth flows |
| TASK-004 | DONE | Better Auth login/logout sessions, server signup OFF, локальный bootstrap пользователя, protected server boundary; тесты анонимного доступа и запрета signup |
| TASK-005 | TODO (выдан) | Настройки timezone/theme, проверка сохранения и существующего sign-out, сохранение после refresh; IANA validation и owner isolation |
| TASK-006 | TODO | Projects create/rename/archive/unarchive, server ownership, исключение архивных данных; tests с двумя пользователями |
| TASK-007 | TODO | Task CRUD, quick-add/Inbox, one-off complete/reopen/soft delete, стабильный порядок; refresh persistence и IDOR tests |
| TASK-008 | TODO | Today/Upcoming, user-local даты, независимые deadline warnings без дублей; timezone boundary tests |
| TASK-009 | TODO | Project tasks, parent/subtask один уровень, atomic move/delete, priority/notes, полноценный task details sheet |
| TASK-010 | TODO | Owner-scoped search по title/notes, loading/error/empty states, shortcuts Q / Esc, rollback ошибок сохранения |
| TASK-011 | TODO | DAILY/WEEKDAYS/WEEKLY и completion history, transaction/revision/idempotency, конкуренция, overdue/Friday/timezone tests |
| TASK-012 | TODO | PWA manifest/icons, онлайн-режим, проверка реальной установки где доступно; без push/offline edits |
| TASK-013 | TODO | Итоговая интеграция и E2E: login → task → schedule → complete → refresh; два пользователя, mobile/desktop, сценарий второго устройства |

MVP считается принятым только после проверки критериев PRODUCT.md. Отдельный этап после MVP и разрешения пользователя: VPS audit, TLS/deployment, backup/restore и 14 дней личного использования. MCP, public signup, calendar sync и collaboration — отдельные будущие предложения.

## Исходный план (сохранённые вехи)
Milestone 0 Foundations: TASK-001–005. Milestone 1 Everyday core: TASK-006–010. Milestone 2 Recurrences and polish: TASK-011–013. Milestone 3 Safe personal deployment и Milestone 4 MCP/расширения пока не выданы.
Исходная редакция очереди сохранена в docs/source/TASKS.initial.md; README и доступные команды добавляет GLM в TASK-001.

## Путь до использования на iPhone
После TASK-004 остаётся 9 задач TASK-005–013 до web/PWA MVP. Первый полезный CRUD сценарий — после TASK-007 (ещё 3 задачи), Today/Upcoming — после TASK-008 (4 задачи), полноценная PWA и итоговая проверка — TASK-012/013. Это браузер/PWA, не native iOS app. Доступ с iPhone вне local Mac требует отдельного этапа TLS/deployment/backup и реальной проверки устройства; он пока не назначен. Нативное iOS/macOS приложение отдельная будущая очередь, её размер/технология ещё не утверждены. Число задач не является оценкой сроков и может измениться по результатам review.
