# Orbit

Персональный менеджер задач (в разработке). Сейчас реализованы каркас
веб-интерфейса (маршруты разделов, адаптивная навигация, выбор темы) и
инфраструктура базы данных: локальный PostgreSQL 17, Drizzle схема с
ownership-связями и проверяемые миграции. Данных задач и аккаунтов ещё нет —
экраны показывают поясняющие заглушки. Продуктовая функциональность
добавляется следующими задачами (см. `TASKS.md` в корне репозитория).

## Требования

- **Node.js 24 LTS** (целевая версия, фиксируется `.nvmrc`; проверено на v24.21.0).
  Удобно использовать [nvm](https://github.com/nvm-sh/nvm): `nvm install` / `nvm use`
  в корне проекта подберёт версию из `.nvmrc`.
- **npm 11** (входит в комплект Node 24; проверено на npm 11.19.0).
- Для unit/e2e-тестов интерфейса нужен только браузер Chromium, который Playwright
  ставит локально в пользовательский кеш (см. ниже). UI-сборка, UI-тесты и E2E
  не требуют БД, Docker и env.
- Для работы с базой (миграции, DB-тесты): Docker-совместимый локальный runtime
  (проверено с Colima) — только для локального контейнера PostgreSQL.

## Быстрый старт

```sh
npm ci        # воспроизводимая установка зависимостей по package-lock.json
npm run dev   # режим разработки на http://localhost:3000
```

Откроется <http://localhost:3000> → перенаправление на `/today`.

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

`npm run test:db` — интеграционный suite на реальном PostgreSQL (28 проверок):
defaults и nullable-поля, ownership composite FK (в том числе на UPDATE),
SQL checks, round trip DATE/TIME и физических типов, дубликаты
idempotency/revision — с двумя синтетическими пользователями. Раннер требует
явный `TEST_DATABASE_URL` (fallback на `DATABASE_URL` отсутствует), отвергает
нелокальные хосты и имена без суффикса `_test`, пересоздаёт только эту
изолированную базу и применяет миграции перед тестами. Без настроенного
доступа команда падает с ошибкой, а не пропускает тесты.

## Маршруты

| Путь          | Экран                      |
| ------------- | -------------------------- |
| `/`           | перенаправление на `/today` |
| `/today`      | Сегодня                    |
| `/inbox`      | Входящие                   |
| `/upcoming`   | Предстоящее                |
| `/projects`   | Проекты                    |
| `/settings`   | Настройки (тема)           |

Оболочка: sidebar (~240 px) при ширине **от 960 px**, компактный header + bottom
nav — ниже. Активный раздел помечен `aria-current="page"`; есть skip link
«К содержимому».

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
| `npm run test:e2e`  | Playwright: пересобирает production build и гоняет браузерные тесты `tests/e2e/` на свободном loopback-порту (по умолчанию 3123, переопределяется `E2E_PORT`) |
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
  драйвер pg 8.23; core auth-схема под [Better Auth](https://better-auth.com) 1.7
  (сами auth flows — TASK-004)
- ESLint 9 (flat config) + `eslint-config-next`
- Vitest 5, Playwright 1.64 (Chromium)

UI-строки интерфейса централизованы в `src/lib/i18n/ru.ts`.

## Что ещё НЕ реализовано

Данных и серверной логики пока нет. Пока отсутствуют и не притворяются работающими:

- авторизация и аккаунты: сессии, вход/выход, bootstrap первого пользователя,
  публичная auth-интеграция (сейчас только физическая схема auth-таблиц);
- CRUD задач и проектов, сервисный слой, API: схема готова, данные никто не пишет;
- алгоритм completion повторений (в схеме только журнал task_completions);
- межстрочные правила (глубина/циклы подзадач, перенос архивации, IANA-валидация
  timezone) — будущие service invariants, БД их не обеспечивает;
- сохранение темы в аккаунте (сейчас только на устройстве);
- PWA-манифест и установка на домашний экран;
- деплой, CI/CD, резервное копирование.

Ссылки на планирование: `PRODUCT.md`, `ARCHITECTURE.md`, `DESIGN.md`, `TASKS.md`.
