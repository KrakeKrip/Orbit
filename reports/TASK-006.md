# TASK-006 — независимое review Codex

2026-10-08. **NEEDS_FIXES**. Проверен executor commit `3036da329c96f428102fb8dbd1de11969f415aa4`, ветка `task/TASK-006`, worktree `/Users/atlhnv/Codex/orbit-worktrees/TASK-006`.
База review `9b2ba6465f2c5bda5aba88cf8f26cd0ffdd0cc2c`; assignment/start `bcde56f30be4dd3e09e3819151a41fcac7134651`. Реализация: 15 файлов, 2355 insertions/102 deletions; накопленный diff от review-базы: 22 файла, включая 7 assignment documents. До review дерево чистое, git diff --check PASS.

## Результат
Owner-scoped service/list/read/update, UUID/payload validation, атомарные PATCH, сохранение archivedAt при повторном archive, стабильная сортировка и неизменность связанных tasks проверены чтением кода и реальными HTTP/DB tests. Настройки используют общие transport helpers; прежние auth/settings/lifecycle regressions сохранены. Product source координатором не изменялся.
Три воспроизведённых замечания ниже блокируют приёмку. Merge/push/deploy не выполнялись, TASK-007 не назначен.

## R1 [P2] Допустимое Unicode-имя обрезается в create UI
`src/components/orbit/projects-view.tsx:295`: maxLength=200 ограничивает UTF-16 units, тогда как контракт принимает 120 Unicode code points. Имя из 120 non-BMP emoji — 240 units, поэтому обычная вставка в браузере молча отрезает последние 20 символов.
Независимый Chromium probe на собственном production server 3250/unique test DB: POST полного имени из 120 🦄 → 201; focus create input + keyboard.insertText того же имени → inputValue содержит только 100 code points/200 units. Пользователь может сохранить другое, укороченное имя, без сообщения о валидации.
Исправить UI-ограничение так, чтобы все допустимые 120 code points вводились без обрезания. Не заменить его на maxLength=120 UTF-16; pure/DB лимит не ослаблять. Добавить browser regression с реальным вводом/вставкой (не только fill, обходящим native maxlength), сохранением и reload полного 120-emoji имени. 121 code points должны отклоняться согласованно с API.

## R2 [P2] Завершение save одного проекта закрывает rename другого
`src/components/orbit/projects-view.tsx:175–190, 226–229, 462–463`: другие rename triggers доступны во время renamePending; openRename заменяет общие renameId/draft, но завершение предыдущего запроса безусловно вызывает closeRename и очищает уже новую форму.
Независимый browser repro: открыть rename P, изменить имя, отправить PATCH и удержать response; нажать доступное «Переименовать» у Q — его форма появляется; отпустить успешный response P → форма Q исчезает, фокус переносится обратно к P. Состояние нового действия изменено ответом прежнего запроса. При отказе прежнего запроса тот же общий error state может попасть в форму Q.
Простой допустимый fix — блокировать начало другого rename и проверять guard в openRename до окончания текущего save; альтернативно привязать все completion/state changes к конкретному актуальному editor/request. Сохранить cancel/focus/error retry/StrictMode/unmount поведение. Добавить детерминированный delayed PATCH browser regression с двумя проектами: новый editor либо нельзя открыть при pending, либо он не закрывается/не получает ошибку от старого request.

## R3 [P2] Content-Type проверяется префиксом вместо media type
`src/server/http.ts:88–91`: startsWith('application/json') принимает application/jsonp, application/json-invalid и прочие неподдерживаемые типы. TASK требует application/json (parameters допускаются), иначе 415 и отсутствие mutation. Это воспроизводится на новых projects endpoints, независимо от того, что прежний settings helper также использовал prefix.
Независимый authenticated HTTP request POST /api/v1/projects с правильным Origin, Content-Type: application/jsonp и JSON body → **201**, создана строка проекта; ожидается **415** без INSERT. Разбирать точный media type, допускающий параметры и регистр media-type token, не произвольный prefix. Добавить HTTP regressions для POST/PATCH: jsonp/похожий prefix →415, нет mutation; application/json; charset=utf-8 → success. Не ослаблять auth/Origin/body limit/no-store и не переделывать settings semantics вне исправления общего helper.

## Независимая верификация
Node 24.21.0. npm ci --offline с существующим cache; lint/typecheck; npm test **29/29**; test:db **47/47**; test:auth **71/71**; CI=1 E2E_PORT=3249 test:e2e **69/69** — все exit 0. По одному auth/E2E прогону Codex: заявленные executor 2× не выдаются за повтор Codex.
Отдельный git archive snapshot проверяемого commit, без .env/DATABASE_URL/BETTER_AUTH_SECRET/BETTER_AUTH_URL, npm ci + build — PASS/exit 0; workspace и API Dynamic. Auth/E2E logs без idle client error/terminating connection/57P01/uncaughtException. Дополнительный реальный production browser/API probe 3250 подтвердил R1/R2/R3 и завершился exit 0.
Сервер probe остановлен, настоящий pool закрыт, его completion проверен runner-finalization. После всех прогонов статистика PostgreSQL: orbit_test_* databases **0**, connections **0**. Пользовательские данные/dev DB не мутировались; main/localhost:3000/CRM/защитные инструменты не изменялись при проверках.
Executor dev StrictMode evidence прочитан; самостоятельный dev replay в этом раунде не выполнялся (обнаруженные issues воспроизведены в production browser). Реальные устройства, production proxy и deployment не проверены. Прежние deployment/limiter/tooling ограничения сохраняются.

## Передача GLM
Та же ветка/worktree. Исправить только R1/R2/R3 и связанные regressions, обновить reports/TASK-006-executor.md. Обычные новые commits; не менять main/старые worktree/coord docs/защитные настройки; без merge/push/amend/rebase/reset/deploy. Выполнить gates TASK-006, вернуть full latest SHA и READY_FOR_REVIEW либо точную BLOCKED диагностику. TASK-007 не начинать.
