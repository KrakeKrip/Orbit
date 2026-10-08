# TASK-002 — независимый review / Correction TASK

Дата: 2026-10-08. Результат: **NEEDS_FIXES**. Merge не выполнен, TASK-003 не начинать.

## Проверенный Git
- Worktree: /Users/atlhnv/Codex/orbit-worktrees/TASK-002; ветка task/TASK-002.
- База audit: 223e75cee2025e0644a0aee3f0de59a424d65f83.
- Старт реализации: 586dc4316970d93166a69e727f75baab81fc1380.
- Полностью проверены оба commit: 93e38ccd08fe90572601b25b9c727c8ae462fddd (реализация), b9971e677e392435a6c3301039cd14b136146a67 (отчёт).
- Diff от старта: 32 файла, от audit base: 37 (5 assignment docs). Scope соблюдён, старый smoke заменён новым осмысленным покрытием; координационные документы GLM не менял. Рабочее дерево до review чистое, base/start являются предками HEAD; git diff --check PASS.
- Main получил только координационный status REVIEW (b380f04); app source в main остаётся принятой TASK-001.

## Проверки Codex
Runtime: Node 24.21.0 / npm 11.19.0 из /tmp/orbit-node24/; системный runtime не менялся.

| Проверка | Результат |
| --- | --- |
| npm ci по lockfile | PASS, exit 0, 694 packages, нет peer conflicts |
| npm run lint | PASS, exit 0 |
| npm run typecheck | PASS, exit 0, strict |
| npm test | PASS, exit 0, 4 render smoke tests |
| E2E_PORT=3137 npm run test:e2e | PASS, exit 0: production next build + 43 Chromium tests; собственный production webServer |
| Production start для ручного review | PASS, 127.0.0.1:3138; после проверки собственный процесс остановлен |
| CUA browser Settings light/dark | PASS: visual на 360/1280, selection и root dark class |
| Breakpoint | PASS: 959 px sidebar=none/bottom=block; 960 px sidebar=flex/bottom=none |
| Touch-size вне существующего E2E покрытия | **FAIL**, реальные DOM размеры ниже |
| npm audit --omit=dev --json | PASS, exit 0, 0 vulnerabilities |
| npm audit --json | exit 1, 9 high, dev tooling chain; source ниже |

E2E покрывает redirect, five routes на 360/390/768/1280, nav transitions, active aria-current, overflow, skip link, nav touch targets, theme keyboard/persistence/system emulation и console errors. Оно не проверяет theme trigger/options и ссылку Orbit, поэтому 43 PASS не подтверждают criterion «все touch targets >=44×44».

## Acceptance criteria
1. Five routes, redirect и поясняющие экраны — PASS. Формулировки заглушек см. необязательную рекомендацию.
2. Sidebar/bottom nav и доступ Settings — PASS по функциональности; точная граница 960 проверена. Дополнительное визуальное active-state улучшение Settings см. рекомендацию.
3. Readable/overflow/layout light/dark — PASS для выполненных browser scenarios; **FAIL по minimum touch target sizes**.
4. Themes, mouse/keyboard/system/persistence/hydration — PASS в независимых E2E + ручной выбор темы.
5. Keyboard/skip link/aria-current/hidden nav — PASS в E2E и анализе.
6. shadcn/i18n/lockfile/build без DB/auth/external fonts — PASS; metadata строки в root layout исторические, не блокируют UI shell.
7. Основные команды/tests/docs/scope — PASS; browser regression нужно расширить для найденного дефекта.

## Обязательное исправление R1 [P2] — мобильные области нажатия меньше 44×44

**Места:**
- src/components/orbit/theme-select.tsx:39 — SelectTrigger имеет generated default h-8 без override.
- src/components/orbit/theme-select.tsx:44 — SelectItem использует generated compact padding без минимальной высоты.
- src/components/orbit/mobile-header.tsx:14–16 — ссылка Orbit имеет min-height, но не minimum width/touch area.

**Нарушение:** TASK-002 раздел 3 и acceptance criterion 3; DESIGN.md — touch targets >=44 px. Это заданная продуктовая граница, а не требование произвольно менять shadcn defaults.

**Воспроизведение:** production /settings, viewport 360×740, после hydration getBoundingClientRect():
- #theme-select: 224×32 px;
- после открытия каждый [role=option]: 219×28 px;
- header link Orbit: 36.5625×44 px.
Настройки/header icon link =44×44 и bottom nav соответствуют условию. Light/dark не исправляют геометрию. Слишком компактные элементы увеличивают вероятность промаха при выборе темы с телефона.

**Ожидается:** actual clickable rectangles указанных элементов >=44×44 на мобильной ширине. Подправить consumers/layout classes в рамках темы/мобильного header; не переделывать библиотеку и не добавлять новый UI. Если специфичные data-size классы shadcn имеют более высокий приоритет, проверить фактическую CSS геометрию, а не наличие min-h класса в source.

**Проверка исправления:** расширить существующие Playwright tests: /settings на 360 и 390, trigger bounds, все открытые options bounds и Orbit link bounds; проверить выбор темы/Enter/Esc после изменения размеров, отсутствие overflow и clip popup. Повторить lint/typecheck/unit/build/e2e. Поправить report: исходные 43 tests не покрывали все controls; вернуть фактические результаты расширенного покрытия.

## Correction scope и Git
Исправлять только R1 и его regression coverage в текущем worktree/branch. Допустимы src/components/orbit/theme-select.tsx, src/components/orbit/mobile-header.tsx, tests/e2e/navigation.spec.ts, tests/e2e/theme.spec.ts, reports/TASK-002-executor.md; локальный helper при непосредственной необходимости. Не изменять docs/архитектуру, зависимости и другие TASK. Необязательные рекомендации не расширяют обязательный scope.
Этот reports/TASK-002.md добавлен Codex отдельным coordination commit в task branch. Новый HEAD отличается от проверенного b9971e6 только review report. GLM делает новые обычные fix/report commits; никакого amend/rebase/merge/push/reset, история сохраняется.
После исправления вернуть READY_FOR_REVIEW либо BLOCKED, полный latest SHA, diff, фактические проверки и ограничения. Не считать DONE до повторного review и integration Codex.

## Необязательные рекомендации
- Settings active state: mobile header icon визуально одинаков на /settings и остальных routes; desktop выделяет Settings только цветами без отдельного marker. При последующей UI-полировке унифицировать видимый non-color indicator с остальными nav links; aria-current уже есть. В этой correction не требуется.
- Заголовки «Задач/Проектов пока нет» можно заменить на «Раздел готовится» до подключения DB, чтобы первая строка не напоминала реальный empty response. Под ними уже есть честное пояснение о будущем подключении, поэтому не блокирует приёмку.
- Playwright reuseExistingServer=!CI способен локально использовать сторонний сервер на занятом порту. Для независимого review был свободный отдельный E2E_PORT и freshly started webServer. В будущем smoke gate можно использовать CI=1 или явно запретить reuse; сейчас не обязательное исправление.

## Ограничения audit
Production audit =0 по текущему npm snapshot. Full audit =9 high: известная braces chain через eslint-config-next плюс новая dev chain shadcn → @shadcn/registry/ts-morph/@ts-morph/common → fast-glob/micromatch/braces. Не девять независимых runtime уязвимостей. Существующее no-audit-cleanup ограничение TASK соблюдено, auto-fix не применялся. Неподдерживаемый ESLint 9 и allowScripts warnings остаются неблокирующими tooling рисками, ранее зафиксированными TASK-001.
Реальное iPhone/OS theme change не проверялись; system scheme проверено Playwright emulation. Auth/DB/PWA не реализованы и не проверялись. Публичный security audit проекта не заявляется.

## Итог
NEEDS_FIXES: один обязательный пункт R1 с тремя малыми mobile targets и расширением регрессионного покрытия. Code merge/push/deploy не выполнены. Ветка и worktree сохранены для исправлений.
