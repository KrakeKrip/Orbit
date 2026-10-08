# TASK-005 — независимое review Codex

2026-10-08. **NEEDS_FIXES**. Проверена реализация `458d8100987fcf58aa07f26d1b2e1f6bb21d3bc3`, старт assignment `d5c949249a359616f5d4fd78fea8b852f2e13b4f`, audit base `738dbec9a333147484284d63e3e51a4c5cde0312`. Branch task/TASK-005, worktree /Users/atlhnv/Codex/orbit-worktrees/TASK-005. Implementation diff от assignment: 22 файла, 1825 insertions/56 deletions. Перед review дерево чистое, git diff --check чист. Merge/push/deploy не выполнены, TASK-006 не выдан.

## Обязательные исправления

### R1 [P2] Запоздавший отказ PATCH прежнего аккаунта меняет тему нового

`src/components/orbit/account-theme-select.tsx:61–74`: callback после await вызывает глобальный next-themes setTheme(confirmed) при отказе/exception. Нет отмены запроса/проверки mounted и принадлежности текущему actor. При unmount React игнорирует собственные setState, но setTheme обновляет сохраняющийся root provider и localStorage — поэтому callback старого экрана всё ещё действует.

Независимое воспроизведение настоящим Chromium на собственном production E2E server, unique DB, порт 3230, synthetic users A/B:
1. A имеет подтверждённую light, выбирает dark. Ответ PATCH удержан route intercept.
2. Пока сохранение pending, A выходит через настоящий logout и B входит через настоящий login, в том же browser context/storage.
3. У B DB theme=system, prefers-color-scheme=dark, html корректно dark.
4. Старый PATCH A получает контролируемый 500. html B становится **light**, orbit-theme=**light**, хотя DB settings B остаются system.

Это нарушение явного TASK требования «поздние ответы A не меняют UI B». Серверная owner isolation в данном сценарии не нарушена; дефект в presentation/cache и lifecycle callback.

Исправить lifecycle settings save: ответы после unmount/смены actor должны игнорироваться, включая rollback setTheme и ошибки/catch/finally. Отмена через AbortController полезна, но сама по себе недостаточна, если её exception также откатывает theme. Применение server preferences/контролы должны быть scoped по actor; не добавлять client owner_id как источник серверной identity. Не откатывать законно завершённые DB записи A после клиентской отмены — требуется защитить текущий UI, а не менять transaction protocol.

Acceptance: browser regression с удержанным PATCH A, logout → login B и последующим 500/network rejection старого запроса: B сохраняет свою server theme в html и orbit-theme, не получает ложный статус старого save. Проверить также уход со Settings при pending и обычный error rollback без смены аккаунта. Обычные theme save/refresh/new context/system assertions сохранить.

### R2 [P2] Ответ timezone save стирает новый draft, введённый во время запроса

`src/components/orbit/timezone-field.tsx:49–57` и editable Input: save отправляет значение на момент старта, но Input остаётся доступным; по ответу безусловно setDraft(savedTimezone) и status=saved.

Независимый Chromium probe (контролируемый delayed 200): отправлено Asia/Tokyo → во время pending введено Europe/Moscow → пришёл ответ `{settings:{timezone:"Asia/Tokyo",theme:"system"}}` → поле стало **Asia/Tokyo**, новый draft Europe/Moscow потерян, отображается «Часовой пояс сохранён».

Исправить согласованность draft/request: либо запретить редактирование поля на время save, либо отслеживать версию отправленного draft и не перезаписывать более новый текст/не считать его сохранённым. Input/submit/pending feedback должны явно отражать выбранное поведение; ошибка по-прежнему оставляет доступный retry draft, Enter и keyboard доступность сохраняются.

Acceptance: deterministic browser regression с delayed response, попыткой изменить timezone во время pending и проверкой отсутствия потери ввода/ложного saved state. Если input disabled — это явно asserted; если редактирование разрешено — более новый draft остаётся и требует отдельного сохранения.

## Подтверждённая часть реализации

Pure enum/timezone canonicalization, defaults UTC/system, offset rejection, строгий PATCH subset; GET missing row без INSERT; PostgreSQL field-specific atomic upsert сохраняет unrelated fields, created_at и owner boundary. Session-derived actor, cookie mutation Origin policy, no-store success/errors и body streaming limit; server errors не печатают SQL/секреты. Server theme bridge не инициирует PATCH при mount. Test fixtures изолированы, production limiter не ослаблен. signInLocalUser — CLI/test provisioning module, не HTTP route; использует поддерживаемый Better Auth API/временный test secret. Schema/миграции/dependencies не менялись.

Фактические независимые gates Node 24.21.0:
- npm ci --offline PASS, lint/typecheck PASS без warnings, npm test **15 PASS**.
- test:db **47 PASS**.
- test:auth **51 PASS**, exit 0, без lifecycle errors.
- CI=1 E2E_PORT=3229 test:e2e **62 PASS**, exit 0, без lifecycle errors. Assertions существующей регрессии сохранены; PASS не покрывает выявленные delayed response сценарии.
- Build без .env/DATABASE_URL/BETTER_AUTH_SECRET/BETTER_AUTH_URL/TEST_DATABASE_URL на git archive snapshot с собственной npm ci PASS; workspace/settings API Dynamic.
- Дополнительные browser probes выше подтверждают R1/R2; app source координатором не менялся. Test server закрыт с clean completion; leftover orbit_test_* DB **0** после suites/probes.
- Executor заявляет два auth/E2E прогона; Codex в этом review выполнил по одному, поскольку два конкретных browser defects уже требуют коррекции. После исправлений повторить обязательные gates TASK и regressions.

## Ограничения

Реальные устройства/production/reverse proxy не проверены. Timezone лишь preference, расписание ещё отсутствует. Прежние memory limiter/pool registry/dependency audit ограничения сохраняются; новых dependencies нет. Основные контракты service/API менять не требуется для исправления UI lifecycle. Контроль same-field strict completion order не является новым blocker.

## Передача GLM

Та же ветка/worktree. Исправить только R1/R2 и связанные regressions, обновить reports/TASK-005-executor.md. Обычные новые commits без amend/rebase/reset/merge/push/deploy; main/3000/CRM/coord docs/защитные настройки не менять. Вернуть full latest SHA и READY_FOR_REVIEW либо точную BLOCKED диагностику. TASK-006 не начинать.
