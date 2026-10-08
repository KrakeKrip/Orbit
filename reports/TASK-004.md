# TASK-004 — независимое review Codex

2026-10-08. **NEEDS_FIXES**. Git-фиксация больше не блокирует передачу на review; продуктовая приёмка не выполнена. Merge/push/deploy не выполнялись, TASK-005 не выдан.

## История / решение по блокировке
База review `fbebaef9a1300bd0212dac48ae7f78c700aa9fc1`, assignment/start `5178578b567b24b0a81487871d904f1a496025fa`. Executor не смог создать commits из-за Mimosa PreToolUse среды GLM; изменения сохранились в task worktree.
Codex зафиксировал реализацию + существующий executor report обычным commit **`4ed184b937847e2d5e44acfa104d599056599626`**, без --no-verify, смены hooksPath или изменения Mimosa. Активных Git-hooks в .git/hooks не было, только .sample; пользователь описал именно PreToolUse, поэтому Git --no-verify не устранил бы такой hook. Настройки/ledger/allowlist Mimosa не изменялись; нет утверждения, что блокировка исправлена в среде GLM глобально.
Фактический implementation diff: **40 файлов**, 2204 insertions/45 deletions (не 32 из сообщения). Все текущие изменения входят в scope TASK-004. Проверка по конкретным configured local DB/auth secret значениям не обнаружила совпадений в этих файлах; это ограниченный pattern check, не полноценный security audit. Branch `task/TASK-004`, worktree `/Users/atlhnv/Codex/orbit-worktrees/TASK-004`; дерево после commit чистое. Main осталась на assignment 5178578; существующие .env/сервисы не изменялись.

## Обязательные исправления GLM

### R1 [P1] Bootstrap оставляет orphan user при отказе credential INSERT
`src/server/auth/bootstrap-core.ts:69–100`: signUpEmail выполняется вне компенсирующего catch/атомарной транзакции. Проверка/удаление orphan запускается лишь если API успешно вернул result.user, но ошибка linkAccount не возвращает этот result. Drizzle adapter config не включает transaction (в установленном adapter default false); Better Auth сначала создаёт user, затем credential account. Сбой второго INSERT оставляет user без password account.
Независимое воспроизведение на новой собственной DB: применены штатные миграции, создан BEFORE INSERT trigger на account с намеренной ошибкой, provisionLocalUser вызван для synthetic email. Результат: provisionRejected=true, remainingUsers=1, remainingAccounts=0. DB потом удалена только её владельцем-reviewer. Повторный bootstrap того же email откажет, так что заявленный rollback не работает; сообщение CLI «Nothing else was changed» неверно.
Нужно обеспечить атомарный supported Better Auth/Drizzle provisioning flow либо строго scoped компенсацию собственных созданных rows при всех ошибках. Не удалять pre-existing users по одному email и не изменять существующий password/account при duplicate/race. При неожиданном создании session не оставлять активную session после отказа. Не включать публичный signup.
Acceptance: fault injection между user/account, ошибки после account creation и duplicate email не меняют pre-existing rows и не оставляют partial user/account/session. Успешный bootstrap продолжает давать compatible sign-in. Регрессионный тест на реальной PostgreSQL, собственная unique DB; не trigger/drop пользовательской DB.

### R2 [P1] Операторский CLI не принимает пароль
`scripts/bootstrap-user.ts:111–118,85`: readline interface закрывается через rl.close(), который pause-ит stdin. askHidden добавляет data listener/setRawMode, но не возобновляет stdin. На Node 24.21.0 CLI после yes и email выдаёт «Password (hidden, min 8 chars)», затем **exit 13 / Detected unsettled top-level await**; пароль ввести невозможно.
Проверено на реальном PTY, с намеренно несуществующей local DB и синтетическими credentials: никаких DB операций/создания user не произошло. Дополнительно воспроизведён paused stream через PassThrough + readline.close; readableFlowing=false.
Исправить lifecycle приватного terminal input: возобновлять чтение, восстанавливать raw mode/listeners при Enter/Ctrl+C/error, не оставлять event handles после конца CLI. Пароль не должен echo-иться или попадать в argv/logs. Проверить именно CLI в PTY, не только provisioning core; use synthetic fixture DB, положительный запуск, duplicate refusal, cancel. Не использовать реальный личный аккаунт/пароль пользователя.

### R3 [P2] Teardown удаляет DB до закрытия app pg pool
`tests/auth/global-setup.ts:152–154`, `scripts/e2e-server.ts:56–67`: остановка HTTP server не закрывает app DB pool. Следующий prepared.teardown делает DROP WITH FORCE, вызывая pg idle client errors. В независимом test:auth после 19 PASS появляется `error: terminating connection due to administrator command`, SQLSTATE `57P01`, затем `uncaughtException`; в E2E аналогичные ошибки `[WebServer]` несмотря на 56 PASS. Из-за process-level обработчиков exit code остаётся 0, поэтому отчёт считает это чистым gate.
Исправить явный lifecycle app connections в test runtime либо останавливать изолированный owned server process и дожидаться завершения его соединений ДО DROP. Init error paths также должны закрывать свои server/pool/DB. Не глушить uncaughtException/idle errors и не скрывать ошибку кодом 0, не добавлять публичный endpoint для test teardown, не останавливать localhost:3000/чужие процессы. DROP только собственной DB остаётся обязательным.
Acceptance: два последовательных test:auth и E2E завершаются без 57P01/uncaughtException/hanging handles; после stop приложения нет его соединений к собственной DB, потом fixture DB удаляется. Сбой setup не оставляет свои server/DB, pre-existing resources не затрагиваются.

## Независимые проверки текущего commit
Node 24.21.0/npm 11.19.0; Docker PostgreSQL Orbit loopback 55432.
- Первый npm ci --offline: ENOTCACHED server-only. После registry доступа npm ci PASS; lockfile неизменный.
- lint exit 0 с четырьмя unused-import warnings; typecheck exit 0; npm test 4 PASS.
- npm run test:db 47 PASS.
- npm run test:auth: production build PASS, 19 assertions PASS, **teardown runtime errors R3**; не считать чистым acceptance.
- CI=1 E2E_PORT=3201 npm run test:e2e: 56 assertions PASS (47 старых + auth additions), **teardown runtime errors R3**. Собственный server/DB, main:3000 не затрагивался.
- Build без env подтверждён на git archive snapshot этого commit в scratch папке с собственным npm ci и удалёнными auth/DB env из process: PASS, workspace/login/API Dynamic. Первая scratch попытка с symlink node_modules была отвергнута Turbopack filesystem root; повтор с собственной установкой прошёл, это tooling ограничение review, не app defect.
- R1 fault injection: реальная isolated DB, 1 orphan user/0 accounts при отказе API. R2 CLI PTY: exit 13 после email, password prompt нерабочий.
- После обычных suites и fault test pg_database не обнаружил оставшихся orbit_test_* DB. Отсутствие leftovers не доказывает чистое закрытие pool (R3).
- git diff --check чист, scope/история сохранены. Credentials/storageState/generated evidence не коммитились.

## Неблокирующие замечания
- Удалить четыре unused imports в Playwright config/global teardown при соответствующих правках R3.
- auth env validator проверяет присутствие DATABASE_URL, но не parse/protocol; bootstrap local guard не проверяет явный dev namespace/protocol/username и не нормализует IPv6/userinfo полностью. Укрепить без расширения целей: fail-closed до DDL, sanitized error без raw URL и случайного подключения к неизвестной локальной DB. Не объявлять любую loopback DB dev базой.
- In-memory rate limiter и trusted proxy/IP policy — local single-process foundation, до deployment отдельно проверить durable/distributed protection. Не обещать production hardening по synthetic HTTP tests.
- Full npm audit при install: прежние 21 package findings (8 moderate/12 high/1 critical), преимущественно tooling/deprecated generator и вложенные версии; generator не public runtime. Force fix не выполнялся. Текущий review не повторял отдельный omit-dev audit; последний результат TASK-003 — 4 moderate в tooling цепочке. До deployment обновить оценку.
- Экраны не реализуют task CRUD/settings persistence/PWA/native; реальные iPhone/macOS устройства и production не проверены.

## Передача GLM
Та же ветка/worktree. Прочитать этот review, исправить R1/R2/R3 и связанные regression tests, актуализировать README/executor report. Обычные новые commits без amend/rebase/reset/merge/push; не менять main/старые TASK/coord docs. После исправления обязательные gates TASK-004, полный latest SHA и READY_FOR_REVIEW либо BLOCKED. Если PreToolUse Mimosa снова блокирует обычный commit — не отключать hook и не использовать --no-verify: сохранить рабочее дерево и вернуть точную диагностику; coordinator может обычным commit зафиксировать scoped исправления. TASK-005 не начинать.


## Повторное независимое review исправлений — 2026-10-08

**NEEDS_FIXES**. Проверен `5f8648e9d5ca4d6b9773edb68307e4c306b5b822`, коррекция относительно `cb13f757f7e94f4a67a0c5de4e4e2a64b260767c`: 14 файлов, 711 insertions/256 deletions. R2 закрыт; R1 и R3 закрыты частично. История сохранена, main не изменена, merge/push/deploy/TASK-005 не выполнялись. Ниже актуальный вердикт; первоначальные результаты выше остаются историческими.

### R1b [P1] Ошибка после создания account оставляет пользователя и активную session

`src/server/auth/bootstrap-core.ts:122–153`: компенсация удаляет кандидата только при отсутствии credential account. Поэтому явный отказ строки 114–118 из-за неожиданной session НЕ откатывает только что успешно созданный user/account/session: account уже существует, ветка удаления пропускается.

Независимое воспроизведение на собственной уникальной БД со штатными миграциями: AFTER INSERT trigger на account добавляет synthetic session этому NEW.user_id. Вызов provisionLocalUser отвергается, но итог **1 user / 1 account / 1 session**. Это имитирует аномалию после создания credential и доказывает невыполнение прежнего acceptance про отсутствие активной сессии после отказа. Все synthetic ресурсы удалены teardown собственной БД.

Отказ BEFORE INSERT account теперь действительно атомарен: независимая исходная fault injection даёт **0 user / 0 account**. `transaction: true` исправил этот сценарий; расширять транзакционный API самодельным hashing не нужно.

Исправить rollback ошибок после успешного signup: при подтверждённом создании именно этим вызовом удалять его rows с каскадом, включая уже созданный account/session. Не подменять доказательство ownership pre-check email + createdAt: между pre-check и catch другой actor может создать строки, и поиск кандидатов по email/времени не доказывает принадлежность вызову. При отсутствии подтверждённого собственного id не удалять произвольные строки; для ошибок внутри signup опираться на поддерживаемую атомарность. Учитывать synthetic duplicate response Better Auth при autoSignIn=false, нормализацию email и реальный формат APIError (у APIError числовой statusCode, а status — строковый статус): проверка `status !== 422` сейчас не гарантирует обещанное исключение duplicate failures.

Acceptance: регрессия unexpected session/ошибка после account creation даёт отказ и 0 собственных user/account/session; account INSERT failure продолжает давать 0 rows. Duplicate/case-normalized duplicate/race сохраняют чужие rows и password; successful provisioning совместим с sign-in. Проверки только на собственных unique БД. Не считать synthetic duplicate id доказательством созданного пользователя.

### R3b [P2] Закрывается другой pool; принудительная termination всё ещё вызывает runtime errors

`tests/auth/global-setup.ts:217–228` и `scripts/e2e-server.ts:67–73`: импорт closeDbPool из исходного core не закрывает экземпляр пула собранного Next bundle. Auth teardown сам признаёт это и вызывает pg_terminate_backend. E2E делает DROP WITH FORCE, пока pool compiled bundle ещё открыт.

Независимые **два последовательных test:auth**: 23 assertions PASS, exit 0, но после каждого `[db] idle client error: terminating connection due to administrator command`. **Два последовательных E2E** (CI=1, порты 3203 и 3204): 56 assertions PASS, exit 0, но 4 и 6 аналогичных `[WebServer] [db] idle client error` соответственно. Обработчик pool error корректен как обычная runtime мера, но перенос ошибки из uncaughtException в console.error не означает чистое закрытие. Поиск только буквального `57P01` пропускает тот же PostgreSQL error без напечатанного SQLSTATE. Утверждение executor report о чистом lifecycle не подтверждено.

Нужно закрыть фактический pool compiled приложения либо запускать приложение в собственном дочернем процессе, остановить его и дождаться выхода/нулевых соединений ПЕРЕД DROP из владельца fixture. Forced termination может быть emergency cleanup собственной БД, но не успешным нормальным teardown. Init failure paths должны соблюдать тот же порядок. Не добавлять публичную teardown API, не скрывать error logs и не останавливать чужие процессы/3000. E2E teardown должен проверять результат ожидания выхода, а не игнорировать false timeout и считать успехом.

Acceptance: два последовательных auth и E2E прогона без idle client error / terminating connection / 57P01 / uncaughtException / hanging handles; фактическое закрытие приложения и его соединений до DROP; нет leftover своих test DB. Обновить отчёт точными фактическими logs, не только числом assertions и exit code.

### R2 — CLOSED

Независимый PTY-прогон настоящего `scripts/bootstrap-user.ts` (Node 24.21.0) на собственной unique БД: создание exit 0, duplicate EMAIL_EXISTS exit 2, подтверждение no exit 0, Ctrl+C при вводе пароля exit 130. Пароль отсутствует в output всех четырёх случаев; termios до/после совпадает. В БД после positive+duplicate — ровно 1 user/1 account. Прежний exit 13 устранён. Paused-stream regression из suite также PASS. Не требуется повторно переделывать ввод без новых оснований.

### Фактические независимые gates

- npm ci --offline с локальным cache PASS; lint без warnings, strict typecheck PASS, UI unit 4 PASS.
- test:db 47 PASS. Первый sandbox запуск получил EPERM loopback connection; повтор с необходимым доступом PASS — это ограничение среды, не app failure.
- test:auth дважды: 23 PASS / exit 0, но lifecycle errors R3b в обоих logs.
- CI=1 E2E_PORT=3203/3204 test:e2e дважды: 56 PASS / exit 0, но lifecycle errors R3b.
- Build БЕЗ .env/DATABASE_URL/BETTER_AUTH_SECRET/BETTER_AUTH_URL на свежем git archive snapshot `5f8648e` с собственной npm ci PASS: workspace/login/API Dynamic. Первые scratch attempts попали в sandbox IPC EPERM Turbopack и cached failure; свежая копия с необходимым IPC доступом прошла.
- Fault injection: account failure 0 user/0 account; unexpected session refusal 1 user/1 account/1 session → R1b.
- CLI PTY четыре сценария PASS, синтетические inputs, без echo/секретов в отчёте.
- После всех suites/helper runs: leftover orbit_test_* DB **0**, git diff --check чист. Исходники продукта координатором не изменялись.
- Реальные iOS/macOS устройства, production/deployment и новый dependency audit не проверялись этим повторным review. Прежние tooling ограничения сохраняются.

### Следующая передача GLM

Та же ветка/worktree; исправить только R1b/R3b и связанные regression tests/test lifecycle, обновить executor report. R2 закрыт. Обычные новые commits, без amend/rebase/reset/merge/push, main/3000/CRM не трогать. TASK-005 не начинать. После повторных gates вернуть latest SHA и READY_FOR_REVIEW либо точную BLOCKED диагностику.
