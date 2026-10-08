# Orbit

Персональный менеджер задач (в разработке). Сейчас реализованы каркас
веб-интерфейса с входом по email/password (регистрация на сервере отключена),
инфраструктура базы данных: локальный PostgreSQL 17, Drizzle схема с
ownership-связями и проверяемые миграции. Данных задач ещё нет — экраны
показывают поясняющие заглушки. Продуктовая функциональность добавляется
следующими задачами (см. `TASKS.md` в корне репозитория).

## Требования

- **Node.js 24 LTS** (целевая версия, фиксируется `.nvmrc`; проверено на v24.21.0).
  Удобно использовать [nvm](https://github.com/nvm-sh/nvm): `nvm install` / `nvm use`
  в корне проекта подберёт версию из `.nvmrc`.
- **npm 11** (входит в комплект Node 24; проверено на npm 11.19.0).
- Для unit-тестов нужен только Node; для E2E — браузер Chromium, который Playwright
  ставит локально в пользовательский кеш (см. ниже). Сборка и UI-тесты
  не требуют БД, Docker и env.
- Для входа в приложение, миграций и DB/auth-тестов: локальный PostgreSQL
  (Compose) и Docker-совместимый runtime (проверено с Colima).

## Быстрый старт

```sh
cp .env.example .env   # затем заполните пароли/секрет (см. комментарии внутри)
npm ci                 # воспроизводимая установка зависимостей по package-lock.json
docker compose up -d   # локальный PostgreSQL; дождитесь healthy
npm run db:migrate     # применить миграции к dev-базе
npm run auth:bootstrap # создать первый локальный аккаунт (интерактивно)
npm run dev            # http://localhost:3000 → редирект на /login
```

## Локальная база данных (PostgreSQL 17 + Drizzle)

1. Создайте локальный `.env` из шаблона и сгенерируйте свой пароль
   (`.env` игнорируется Git; реальные секреты в репозиторий не попадают):

   ```sh
   cp .env.example .env
   # замените change-me-local-only на свой пароль, например: openssl rand -hex 24
   ```

2. Поднимите локальный PostgreSQL (Compose, project name `orbit`; порт
   публикуется только на 127.0.0.1, по умолчанию 55432, настраивается
   `ORBIT_DB_PORT`; занятый порт освобождать за счёт чужих сервисов нельзя —
   поменяйте `ORBIT_DB_PORT` в `.env`):

   ```sh
   docker compose up -d   # запуск контейнера
   docker compose ps      # дождитесь статуса healthy
   ```

3. Примените миграции к dev-базе (`orbit_dev` из `DATABASE_URL`):

   ```sh
   npm run db:migrate     # checked-in SQL из drizzle/; повторный запуск безопасен
   ```

4. Изменение схемы: правьте `src/server/db/schema.ts` (auth-таблицы в
   `schema.auth.ts` генерируются Better Auth CLI, см. ниже) и зафиксируйте
   историю миграций:

   ```sh
   npm run db:generate    # создаст SQL-миграцию в drizzle/; schema push запрещён
   npm run db:migrate
   ```

Безопасная остановка без удаления данных:

```sh
docker compose stop     # либо docker compose down — БЕЗ флага -v (volume сохраняется)
```

`docker compose down -v` удаляет данные базы — в обычном workflow не используется.

### Схема и auth-таблицы

- `src/server/db/schema.auth.ts` — core auth-таблицы `user`, `session`,
  `account`, `verification`, сгенерированные официальным CLI закреплённой
  версии Better Auth (`@better-auth/cli` 1.4.x / `better-auth` 1.7.x,
  email/password без plugins). Файл не редактируется вручную; воспроизведение:
  `npx @better-auth/cli generate --config scripts/auth-generator.config.ts --output src/server/db/schema.auth.ts -y`
  (подключения к БД генерация не выполняет).
- `src/server/db/schema.ts` — доменные таблицы `user_settings`, `projects`,
  `tasks`, `task_completions`: UUID PK, owner/user `text` (Better Auth id),
  composite FK (id, owner_id) для task→project, task→parent и completion→task,
  SQL checks (priority 1–4, длины, planned_time⇒planned_date, recurrence⇒planned_date
  без deadline и без постоянного completed_at, parent_id ≠ id, revision ≥ 0),
  партиальные индексы по owner+датам для активных задач. Событийные timestamp —
  timestamptz; календарные planned_date/planned_time — DATE/TIME.
- `src/server/db/client.ts` — ленивый пул: на import подключений нет,
  `DATABASE_URL` нужен только при явной DB-операции.
- `updated_at` заполняется при insert (default); обновление timestamp при
  UPDATE — обязанность будущего сервисного слоя (триггеров нет).

### Тесты базы данных

`npm run test:db` — интеграционный suite на реальном PostgreSQL (28 проверок
схемы + guard- и sentinel-тесты раннера): defaults и nullable-поля, ownership
composite FK (в том числе на UPDATE), SQL checks, round trip DATE/TIME и
физических типов, дубликаты idempotency/revision — с двумя синтетическими
пользователями. Раннер требует явный `TEST_DATABASE_URL` (fallback на
`DATABASE_URL` отсутствует; query-параметры и нелокальные хосты отвергаются
до подключения), создаёт для каждого запуска **новую уникальную** базу
`orbit_test_<запуск>` (без `IF NOT EXISTS` — ничего предварительно не
удаляется) и применяет миграции перед тестами. После прогона удаляется
только база, созданная этим запуском: ранее существовавшие базы (включая
`orbit_test`) не затрагиваются. Без настроенного доступа команда падает
с ошибкой, а не пропускает тесты.

## Маршруты

| Путь          | Доступ      | Экран                      |
| ------------- | ----------- | -------------------------- |
| `/`           | —           | перенаправление на `/today` |
| `/login`      | анонимно    | Вход (email/password)      |
| `/today`      | сессия      | Сегодня                    |
| `/inbox`      | сессия      | Входящие                   |
| `/upcoming`   | сессия      | Предстоящее                |
| `/projects`   | сессия      | Проекты                    |
| `/settings`   | сессия      | Настройки (тема, выход)    |
| `/api/v1/me`  | сессия      | GET identity endpoint      |

Все workspace-маршруты защищены на сервере: анонимный браузер перенаправляется
на `/login`, API отвечает `401 {"error":{"code":"UNAUTHENTICATED"}}`.

Оболочка: sidebar (~240 px) при ширине **от 960 px**, компактный header + bottom
nav — ниже. Активный раздел помечен `aria-current="page"`; есть skip link
«К содержимому».

## Аутентификация

- [Better Auth](https://better-auth.com) 1.7.7 (email/password, Drizzle adapter)
  поверх таблиц `user/session/account/verification`. **Публичная регистрация
  отключена на сервере** (`disableSignUp=true`, без env-переключателя): прямой
  POST на sign-up отвергается и не создаёт записей.
- Сессии: HttpOnly cookie, SameSite=Lax, cookie cache отключён (отзыв/истечение
  проверяются на каждом запросе). Sign-in rate limit: 10 попыток/60s на IP
  (однопроцессное memory-хранилище; перед deployment требуется пересмотр).
- Runtime-конфигурация (только в `.env`): `DATABASE_URL`, `BETTER_AUTH_SECRET`
  (минимум 32 символа случайности: `openssl rand -hex 32`), `BETTER_AUTH_URL`.
  Без них auth-запросы fail-closed; сборка и UI-тесты работают без env.
- **Первый аккаунт** — локальная одноразовая процедура (не публичный endpoint):

  ```sh
  npm run auth:bootstrap   # интерактивно спросит email и пароль (скрытый ввод)
  ```

  Повторный запуск с тем же email отказывает, не меняя пароль. Восстановление
  пароля — отдельная будущая задача.
- Выход: кнопка «Выйти» в `/settings` (отзывает сессию на сервере).

### Тесты аутентификации

`npm run test:auth` — интеграционный suite на реальном PostgreSQL и production
Next-сервере: изолированная per-run база (тот же проверенный target, что и в
`test:db`), синтетические пользователи с одноразовыми паролями, закрытые
подключения и cleanup только своих ресурсов. Покрывает: запрет signup прямым
запросом, generic ошибки входа без user enumeration, HttpOnly/SameSite cookie,
поддельный/истёкший/отозванный session cookie, actor isolation, hostile Origin,
rate limit 429, повторный bootstrap.

## Тема оформления

В настройках доступен выбор «Системная / Светлая / Тёмная» (next-themes, class
attribute). Выбор применяется сразу и хранится **только на этом устройстве** —
в `localStorage` под ключом `orbit-theme`. Сохранение темы в аккаунте появится
позже (TASK-005).

## Production-сборка и запуск

```sh
npm run build # production-сборка Next.js
npm start     # запуск собранного приложения на http://localhost:3000
```

`npm start` обслуживает результат `npm run build`; порт по умолчанию — 3000,
можно переопределить: `npm start -- --hostname 127.0.0.1 --port 3101`.

## Скрипты

| Команда             | Назначение                                                  |
| ------------------- | ----------------------------------------------------------- |
| `npm run dev`       | сервер разработки Next.js (localhost:3000)                  |
| `npm run build`     | production-сборка                                           |
| `npm start`         | запуск production-сборки (localhost:3000)                   |
| `npm run lint`      | ESLint (flat config, `eslint.config.mjs`)                   |
| `npm run typecheck` | TypeScript, `tsc --noEmit` (strict включён)                 |
| `npm test`          | Vitest: быстрые UI smoke-тесты (`tests/*.test.tsx`), без БД  |
| `npm run test:db`   | Vitest: интеграционные тесты схемы на изолированном локальном PostgreSQL (нужен `TEST_DATABASE_URL`, см. раздел БД) |
| `npm run test:auth` | Vitest: интеграционные тесты аутентификации на реальном PostgreSQL и production-сервере (нужны `TEST_DATABASE_URL`; build входит) |
| `npm run test:e2e`  | Playwright: пересобирает production build и гоняет браузерные тесты `tests/e2e/` на свободном loopback-порту (по умолчанию 3123, переопределяется `E2E_PORT`) |
| `npm run auth:bootstrap` | интерактивное создание первого локального аккаунта (только local DB) |
| `npm run db:generate` | генерация SQL-миграции из `src/server/db/schema*.ts` в `drizzle/` |
| `npm run db:migrate`  | применение checked-in миграций к dev-базе из `DATABASE_URL` |

E2E-тесты требуют однократной установки Chromium (в пользовательский кеш,
без изменения системы):

```sh
npx playwright install chromium
```

E2E-покрытие: redirect `/`, прямой вход и навигация по всем разделам, активная
ссылка (`aria-current`), отсутствие горизонтального overflow на 360/390/768/1280 px,
выбор темы light/dark (мышью и клавиатурой) с сохранением после refresh,
реакция системной темы на `prefers-color-scheme`, skip link, touch targets ≥44 px,
отсутствие ошибок в консоли браузера.

## Стек

- [Next.js 16](https://nextjs.org/docs/app) (App Router, `src/`, Turbopack) + React 19
- TypeScript (strict, alias `@/*` → `src/*`)
- Tailwind CSS 4 + [shadcn/ui](https://ui.shadcn.com) (Radix-база: Button, Select)
- next-themes (light/dark/system, ключ `orbit-theme`)
- PostgreSQL 17 + [Drizzle ORM](https://orm.drizzle.team) 0.45 / drizzle-kit 0.31,
  драйвер pg 8.23; аутентификация — [Better Auth](https://better-auth.com) 1.7.7
  (email/password, Drizzle adapter, signup отключён на сервере)
- ESLint 9 (flat config) + `eslint-config-next`
- Vitest 5, Playwright 1.64 (Chromium)

UI-строки интерфейса централизованы в `src/lib/i18n/ru.ts`.

## Что ещё НЕ реализовано

Данных задач и серверной бизнес-логики пока нет. Пока отсутствуют и не
притворяются работающими:

- CRUD задач и проектов, сервисный слой, API besides identity endpoint;
- смена email/пароля, восстановление пароля, сессии «на других устройствах»;
- сохранение темы и timezone в аккаунте (сейчас тема только на устройстве;
  настройки аккаунта — TASK-005);
- алгоритм completion повторений (в схеме только журнал task_completions);
- межстрочные правила (глубина/циклы подзадач, перенос архивации, IANA-валидация
  timezone) — будущие service invariants, БД их не обеспечивает;
- PWA-манифест и установка на домашний экран;
- деплой, CI/CD, резервное копирование.

Ссылки на планирование: `PRODUCT.md`, `ARCHITECTURE.md`, `DESIGN.md`, `TASKS.md`.
