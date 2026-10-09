# TASK-008 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние (проверено до изменений)

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/TASK-008`; ветка `task/TASK-008`; дерево чистое.
- База review `394aef441a05d95969596bf088b37fb1f087432e` (принятый TASK-007); **starting SHA: `9a81313bb498fd1e584b14a0bc2b87b506102c6b`** (assignment, единственный над базой).
- Runtime: **Node v24.21.0 / npm 11.19.0 из `/tmp/orbit-node24/node-v24.21.0-darwin-arm64/bin`** (системный Node 26 не использовался для gates). npm ci exit 0, lockfile неизменен; новых зависимостей нет (Intl + чистая арифметика).
- PostgreSQL Orbit loopback 55432; localhost:3000/CRM/main не затрагивались; `.env` untracked (значения не выводились).

## Этап A — pure calendar contracts

- `src/lib/calendar.ts` (новый): `parseCivilDate` — строгая `YYYY-MM-DD`, существующий Gregorian день, диапазон 1900-01-01..2199-12-31 (1900/2100 не leap, 2000 leap; whitespace/coercion/ISO timestamp/offset/пустая строка/не-строка → invalid); `parseCivilTime` (`HH:mm` 00:00..23:59, без seconds/offset/Z); `normalizeCivilTime` (PG `HH:mm:ss` → API `HH:mm`); `addCivilDays`/`civilDateRange` — **civil**-дни (не 86400000 к instant), RangeError за границами; `instantToLocalDate` — explicit IANA zone через Intl (gregory/latn, кэш форматтеров, fail-closed RangeError на невалидной зоне/не-цифрах), независимость от `process.env.TZ` доказана тестом; `formatCivilDateDisplay` (DD.MM.YYYY перестановкой строк — без Date, без сдвига дня).
- `src/lib/task-view.ts` (новый): `todaySectionOf`/`groupTodayTasks` — 4 взаимоисключающие секции (plan<today → plan=today → deadline<today → deadline=today), каждая task максимум одна секция; сортировки: секция1 plannedDate+time NULLS LAST, секция2 time NULLS LAST, секция3 deadlineDate, секция4 — стабильный вход; `groupUpcomingTasks` — инклюзивный [start..end], 7 групп включая пустые, time NULLS LAST внутри группы.
- `src/lib/tasks.ts` расширены: `TASKS_MAX_JSON_BODY_BYTES=4096` (task-specific константа; Settings/Projects/DELETE — прежние 2 KiB), `parseTaskCreate` ({title} + опциональные planning; time без date → field=plannedTime), `parseTaskPatch` (subset title/completed/plannedDate/plannedTime/deadlineDate; null только schedule), `parseTaskCollectionViewQuery` (view/status/start; дубликаты/чужие keys → invalid; start только upcoming; start+6 вне диапазона → invalid), `TaskDTO` расширен additive (plannedDate/plannedTime/deadlineDate), `toTaskDTO`.

Тесты: `tests/calendar-view.test.ts` (новый, 25) + расширение `tasks-validation`/`workspace-pages`. Unit suite: **63** (прежде 44; все прежние сохранены).

## Этап B — service/API/context

- `src/server/tasks/service.ts`: `listTasksView(actorId, view, status, today, startDate?)` — рабочие view-фильтры (root one-off non-deleted, project NULL/свой активный — прежний invariant), Inbox `planned_date IS NULL`, Today union `(planned<=today OR deadline<=today) AND (planned NOT NULL OR deadline NOT NULL)`, Upcoming `planned_date BETWEEN start AND start+6` + сортировка planned_date/time NULLS LAST/stable; `createTask` принимает planning; `mutateTask` — merge под task→project row locks: результирующие значения вычисляются под блокировкой, **очистка плана автоматически очищает time** (явное время при `plannedDate:null` → validation field=plannedTime; time при отсутствии даты → 400), deadline независим, **только реально изменённые поля** в UPDATE, revision+1 на effective mutation, no-op без записи (HH:mm vs HH:mm:00 нормализуется), journal/completion/soft-delete/409/404 семантика TASK-007 сохранена.
- `src/server/tasks/context.ts` (новый, server-only): `getTasksReadContext` — timezone из `getAccountSettings` (default UTC, без INSERT), **один** `SELECT current_timestamp` на read → `asOf` ISO + `today` civil date этого instant в зоне actor.
- Routes: GET коллекции — единый ответ `{tasks, context:{timezone,today,asOf,view,startDate?,endDate?}}`; POST/PUT PATCH — `readJsonBodyWithLimit(request, TASKS_MAX_JSON_BODY_BYTES)`; item PATCH маппит `validation` outcome в 400 field.

Тесты: `tests/auth/tasks-planning.auth.test.ts` (новый, 22): defaults/точность DTO+DB (PG TIME с секундами), границы дат/времени, 500-emoji+schedule в 4 KiB / >4KiB 413, неизвестные поля, context UTC без settings INSERT, timezone смена (Europe/Moscow) переписывает today без изменения сохранённых дат, query-матрица 400, full planned×deadline матрица Today (один ID, секции по контракту), Upcoming инклюзивность/диапазон, merge-кейсы (set/clear/no-op/combined/конкурентные title-vs-schedule и complete-vs-schedule — оба сохранены), невалидный merge без изменений task/journal. Прежние tasks.auth адаптированы (context в ответе, 4KiB threshold, поля DTO).

## Этап C — UI

- Общие компоненты: `task-row.tsx` (строка: title текст, бейджи plan/deadline с overdue/today, completion toggle, rename editor, schedule editor, delete confirmation; **id `task-row-<id>`** на li), `task-schedule-editor.tsx` (дата/время/дедлайн; disabled time без даты; очистка даты чистит draft time; **dirty-only Save** — no-op Save disabled; Escape/cancel; pending блокирует ввод), `task-items-list.tsx` (global busy), `use-task-writes.ts` (единый хук мутаций: in-flight guards, R1 read-handling — onConfirmed false → listError, не failed write; R2 — открытие editor/confirmation заблокировано при любом in-flight; фокус: success → `task-<kind>-trigger-<id>` если строка в DOM, иначе createFocusElementId; failure → editor input/«Отмена»/toggle; lifecycle/actor guards + программный фокус с повторами, отменяемый по nonce/unmount/смене actor).
- Экраны: Inbox (+«Планирование», «Обновить», read-error/retry); Today (`today-board.tsx` — секции из pure-хелпера, quick-add с `plannedDate=context.today`, completed-режим с нейтральными заголовками, Обновить); Upcoming (`upcoming-board.tsx` — prev/next/current с диапазоном в URL через replaceState, группы 7 дней, invalid start — явная ошибка на SSR). TasksView переработан на shared-компоненты (не дублирует 700 строк).

## Исправления по review Codex WIP `2861969`

1. **DOM id в focusAfterSuccess**: проверка `task-row-<id>` не находила элемент (li имел только `data-task-id`) → фокус всегда уходил на create-input; шаблон `${kind}-trigger-` не совпадал с реальными `task-<kind>-trigger-`. Исправлено: `id={task-row-<id>}` на li + `task-${kind}-trigger-${taskId}`.
2. **renameError boolean-проверка**: `state.renameError !== null` всегда true (boolean ≠ null) → параграф ошибки рендерился в каждой строке безусловно. Исправлено на truthiness.
3. **Проглатывание таймаута**: `.catch(() => null)` на `waitForResponse` в planning-тесте удалял диагностику «PATCH не отправлен». Убрано; падение теперь громкое.
Дополнительно: удалены все отладочные PROBE/DBG-логи; освобождение gate в «failed schedule» перенесено до ожидания ответа (тестовый дедлок снят).

## Проверки (Node v24.21.0 / npm 11.19.0 — /tmp/orbit-node24)

| Команда | Результат |
| --- | --- |
| `npm ci` | exit 0, lockfile неизменен |
| `npm run lint` / `npm run typecheck` | exit 0 / exit 0 (strict), без warnings |
| `npm test` | exit 0 — **63 passed** (44 прежних + 25 календарных − адаптации) |
| `npm run test:db` | exit 0 — **47 passed** |
| `npm run test:auth` №1 / №2 (последовательно, после всех фиксов) | exit 0 — **123/123** оба; 0 lifecycle-паттернов |
| Падающие сценарии вместе (`inbox.spec` + `planning.spec`) ×2 | exit 0 — **25/25** оба |
| `CI=1 E2E_PORT=3327` / `3328` (последовательно) | exit 0 — **94/94** оба (83 + 11 planning); 0 lifecycle-паттернов |
| `npm run build` без `.env` | exit 0; /api/v1/tasks, /today, /upcoming, /inbox ƒ Dynamic |
| Real `next dev` StrictMode probe (порт 3330, unique DB) | `DEV-SCHEDULE-SUCCESS` (PATCH ok, задача уходит из Inbox) → `DEV-SCHEDULE-FAILURE` (500, draft/error видимы) → `DEV-SCHEDULE-RETRY` (PATCH ok) → **DEV CHECK PASS**; side effects возвращены, leftover 0 |
| Leftovers после всех прогонов | orbit_test\*-баз: **0**; `git diff --check` чист |

Флейк-расследование (по требованию Codex, trace/DOM-доказательства): корневые причины — перечисленные id/boolean-дефекты; версия о «задержке React-коммита» **не подтвердилась** — после исправления id все фокус-сценарии стабильны без увеличения циклов ожидания (retry-механизм фокуса сохранён как страховка, но не является причиной зелёного).

## Известные ограничения / не проверено

- Реальные устройства/production proxy/deployment не проверялись; DST-gap время (02:30) — допустимый wall-clock label без будильников (по контракту).
- Midnight-таймер/realtime sync отсутствует: today обновляется на read/reload/«Обновить» (по контракту).
- Постоянного dev-mode suite нет; live dev процедура описана и выполнена (evidence выше).
- npm audit не пересчитывался (новых зависимостей нет); limiter single-process; прежние tooling-ограничения действуют.
- Upcoming timezone-метки: `today`-маркер группы по server context; месяц/год/DST-переходы покрыты pure-тестами addCivilDays/instantToLocalDate, browser-проверка навигации через диапазон в URL.

## Git

- Ветка `task/TASK-008`, worktree `/Users/atlhnv/Codex/orbit-worktrees/TASK-008`.
- Starting SHA `9a81313bb498fd1e584b14a0bc2b87b506102c6b`; коммиты: WIP `28619690ee11150e6321388ccd628a177d15e885` (реализация трёх фаз) + финальный фикс-коммит (три замечания Codex + README + этот отчёт); latest full SHA сообщён после commit.
- Merge/push/amend/rebase/reset/stash не выполнялись; main/старые worktree/localhost:3000/CRM/VPN/coord docs не менялись; secrets только в untracked `.env`.

## Итог

TASK-008 реализован по phases A/B/C (civil calendar, atomic planning merge + context API, shared editor/rows + Today/Upcoming). Все gates зелёные на Node 24. Остановка до независимого review Codex; TASK-009 не начинался.

---

# Коррекция TASK-008-R1 — snapshot планировочного редактора

## Статус

READY_FOR_REVIEW (только R1 [P1] из `reports/TASK-008.md`; R2–R8 не затронуты). Assignment `tasks/TASK-008-R1.md`; старт correction — coordinator review commit `f56cecc0bf42441b6b2c39c4bd0f6b91df21c36b` (HEAD проверен перед изменениями, дерево чистое).

## Дефект и исправление

`TaskScheduleEditor` сравнивал draft с «живым» prop snapshot (обновляемым refetch'ем при открытом редакторе): после чужого PATCH + «Обновить» Save отправлял `deadlineDate:null` и стирал чужую запись. Исправление (`src/components/orbit/task-schedule-editor.tsx`): snapshot фиксируется в `useState` на момент конкретного открытия (редактор монтируется только пока открыт); dirty-вычисление и PATCH-ключи считаются **только** от этого frozen snapshot. Сохранены контракты: очистка даты чистит time (draft+PATCH), no-op Save disabled, failed save сохраняет draft, Cancel/reopen берёт свежий snapshot из актуального task, публичные API не менялись. `task-row.tsx` правки не потребовал.

## Browser-регрессии (tests/e2e/planning.spec.ts, новый describe «Planning editor snapshot (R1)»)

1. **refresh+Save**: задача plan/time/deadline NULL → editor, меняется только plannedDate → второй клиент (тот же аккаунт C, независимый APIRequestContext, правильный Origin) пишет deadline=D → «Обновить» с ожиданием фактического GET; editor открыт, draft жив, поле дедлайна показывает snapshot открытия → Save: тело настоящего PATCH (200) содержит ровно `["plannedDate"]` → GET item: plannedDate=future, plannedTime=null, **deadline=D сохранён**; editor закрыт, задача ушла из Inbox.
2. **Cancel/reopen**: тот же сценарий до Save → «Отмена» → новое «Планирование»: deadline подставлен из актуального task, отменённый draft даты не воскресает, Save disabled (no-op PATCH невозможен).
3. **Симметричный time**: правка только deadline в Upcoming, второй клиент ставит plannedTime=10:00 → refresh → Save: PATCH ровно `["deadlineDate"]`, GET item: время 10:00 сохранено, дедлайн записан.

## Проверки (Node v24.21.0 — /tmp/orbit-node24)

| Команда | Результат |
| --- | --- |
| `npm run lint` | exit 0, **1 warning** — оставшийся известный `use-task-writes.ts:325` (файл вне R1 scope, не правил); warning `planning.spec.ts:169` (unused today) устранён в рамках правки этого файла |
| `npm run typecheck` | exit 0 |
| `npm test` | exit 0 — 63/63 |
| `CI=1 E2E_PORT=3421 npm run test:e2e -- tests/e2e/planning.spec.ts --project=chromium` (штатный `next build` + server) | exit 0 — **16/16** (13 прежних планировочных + 3 новых R1; auth-setup project включён) |
| Leftovers | orbit_test\*-баз: 0, соединений: 0 (read-only проверка) |
| `git diff --check` (unstaged R1-изменения) | чисто |

Процедурная находка: первый прогон R1-тестов падал на **устаревшем** production-билде (`npx playwright test` без `next build` отдал предыдущий `.next`); оба падения в точности воспроизводили старое поведение и после штатного `npm run test:e2e` (build включён) не воспроизводятся. В отчёт включено как свидетельство, что регрессия ловит дефект.

## Ограничения / не входило

- R2–R8 не исправлялись; full auth/E2E прогон не выполнялся (по заданию — перед итоговой приёмкой TASK-008). Известный R6 auth timezone failure остаётся открытым.
- Debug-остатки в тестовых файлах (inbox.spec PROBE-листенеры, «R3 DEBUG», navigation OVERFLOW) и EOF-пустые строки в task-row.tsx / tasks-planning.auth.test.ts из review — чужие для R1 файлы, не тронуты (отдельная финальная уборка).
- Trace `'on'` в playwright.config оставлен как был; main/старые worktree/localhost:3000/CRM/coord docs/protective hooks не менялись; merge/push/amend/rebase/reset/stash не выполнялись.

---

# Коррекция TASK-008-R2a — один task write в полёте

## Статус

READY_FOR_REVIEW (только R2a: общий guard create/row writes; R2b editor/mode переходы, R3–R8 не затронуты). Assignment `tasks/TASK-008-R2a.md`; R1 принят на `3b3688ad66845dc80216105bb20d85375293592e`; старт — coordinator commit `73c65492b9405707572a8ec39fb482490d37318e` (root/HEAD/status проверены, дерево чистое, чужих изменений нет).

## Дефект и исправление

Create имел собственный `createInFlight`, невидимый shared writes-hook: удержанный POST quick-add не блокировал row controls — уходил второй (PATCH) write. Исправление — общий guard, без переписывания экранов:

- `src/components/orbit/use-task-writes.ts`: `TaskWriteKind` расширен `create`; новые `beginCreate()` (синхронная проверка общего in-flight set + регистрация ДО fetch, возвращает false при любом pending write) и `endCreate()` (снятие в finally экрана; ref чистится всегда); реактивный `anyPending` (create|rename|toggle|schedule|delete) для disabled; `create.pending/begin/end` в возвращаемом объекте. Попутно точечно устранён известный lint warning: неиспользуемый `focusElement` удалён, в deps `submitDelete` возвращён реально используемый `requestFocus` (поведение фокуса не менялось).
- `src/components/orbit/task-items-list.tsx`: `globalBusy` включает `writes.create.pending` → row controls disabled во всех строках при удержанном create.
- `src/components/orbit/tasks-view.tsx` и `today-board.tsx`: `handleCreate` регистрирует create через `writes.create.begin()` синхронно до `fetch` (после parse — невалидный черновик guard не занимает), снимает в `finally` через `end()`; create input/submit `disabled={writes.anyPending}` — заблокированы и при своей, и при чужой pending записи.

Синхронные handler guards row writes уже стояли первыми строками каждого submit*/open* (`anyInFlight()`), теперь они видят create; программный обход disabled невозможен. Контракты сохранены: idle editor держит draft (чужая pending его не стирает), write-response/read-error distinction (confirmed write + failed read = read error/retry), focus policy, actor/unmount/StrictMode suppression, GET-only retry. Upcoming row writes идут через тот же shared hook/list без изменений файла (create UI там нет); status/window переключения не трогались (R2b).

## Browser-регрессии (tests/e2e/write-guard.spec.ts, новый, 3 теста, user C)

1. **Inbox, held POST**: удержанный route'ом POST quick-add → create input/submit и все row controls disabled; force-click «Завершить»/«Планирование» и программный `form.requestSubmit()` не отправляют PATCH/DELETE/второй POST (счётчики route-наблюдателей = 0; editor не открыт). Release 500 → create error виден, черновик сохранён, контролы вновь enabled → retry успешно создаёт задачу.
2. **Inbox, held schedule PATCH**: валидный create-черновик заранее → удержанный PATCH editor'а → create input/submit disabled; программный `requestSubmit()` (мимо disabled кнопки) и force-click не отправляют POST (postCount=0). Release 500 → schedule error, guard снят, create доступен → повторный «Сохранить» проходит (PATCH 200), editor закрыт, задача ушла из Inbox.
3. **Today, held POST**: короткий вариант №1 — row controls disabled, force-toggle без PATCH, отказ снимает guard, черновик сохранён, retry работает.

Минимальная адаптация существующего теста `tests/e2e/inbox.spec.ts` (R3b, последняя фаза): мгновенное чтение `document.activeElement` после `toHaveCount(0)` заменено на авто-ретраящий `await expect(page.locator("#task-title-input")).toBeFocused()` — по требованиям R2a create input законно disabled до конца write flow, поэтому фокус landится через кадр после снятия pending (тот же ассерт, та же цель, корректная синхронизация вместо гонки).

## Проверки (Node v24.21.0 — /tmp/orbit-node24; окружение: Colima OFF, 55432 недоступен)

| Команда | Результат |
| --- | --- |
| Состояние test DB | Colima not running, `nc 127.0.0.1 55432` closed; dev DB не использовалась и не менялась |
| Временный test PostgreSQL | **PostgreSQL 18.6 (Homebrew)**, отдельный кластер `/private/tmp/orbit-pg-r2a-*`, `initdb -U orbit_tmp -A scram-sha-256`, эфемерный пароль (0600-файл), listen 127.0.0.1 на свободном порту 37100; TEST_DATABASE_URL только через env (перекрывает .env), namespace `orbit_test` |
| `npm run lint` | exit 0, **0 warnings** (известный warning hook'а устранён точечно в рамках R2a) |
| `npm run typecheck` | exit 0 |
| `npm test` | exit 0 — 63/63 |
| `CI=1 E2E_PORT=3521 npm run test:e2e -- write-guard+inbox+planning --project=chromium` (штатный `next build`) | 30 passed + 1 failed: R3b inbox — гонка мгновенного чтения фокуса (см. адаптацию выше); product-дефект не подтверждён (фокус landится, кадром позже) |
| `CI=1 E2E_PORT=3522 npx playwright test` (тот же билд, после адаптации теста) | exit 0 — **31/31**: 3 auth-setup + **3 write-guard** + **12 inbox** (включая pending-complete/R3b) + **13 planning** (включая 3 R1-регрессии) |
| Leftovers после прогонов | read-only check на временном инстансе: **0** orbit_test\*-баз; `git diff --check` чист |
| Очистка окружения | `pg_ctl stop` — server stopped; кластер, парольный и env-файлы удалены; порт закрыт; сторонние сервисы не поднимались, dev DB не тронута |

## Ограничения / не входило

- R2b (единственный активный editor, mode/window переключения при pending), R3–R8 — не тронуты; full auth/E2E не гонялись (R6 открыт отдельно). Frozen snapshot R1, service/API/schema/auth/read context не менялись.
- Проверка на целевом PostgreSQL 17 (55432/Colima) в этом запуске невозможна — сервис выключен не мной; целевой E2E выполнен на временном PG 18.6 (как и независимый review R1).
- Debug-остатки в inbox.spec (PROBE-листенеры, «R3 DEBUG») и EOF-пустые строки task-row.tsx/tasks-planning.auth.test.ts — не R2a, не тронуты.
- main/другие worktree/localhost:3000/CRM/coord docs/hooks не менялись; merge/push/amend/rebase/reset/stash/деплой не выполнялись. R2/TASK-008 целиком НЕ приняты — только эта коррекция на review.

