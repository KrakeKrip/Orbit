# Orbit

Персональный менеджер задач (в разработке). Сейчас в репозитории находится только
технический фундамент: приложение Next.js запускается и показывает нейтральную
стартовую страницу. Продуктовая функциональность будет добавляться следующими
задачами (см. `TASKS.md` в корне репозитория).

## Требования

- **Node.js 24 LTS** (целевая версия, фиксируется `.nvmrc`; проверено на v24.21.0).
  Удобно использовать [nvm](https://github.com/nvm-sh/nvm): `nvm install` / `nvm use`
  в корне проекта подберёт версию из `.nvmrc`.
- **npm 11** (входит в комплект Node 24; проверено на npm 11.19.0).
- Другие системные зависимости (PostgreSQL, Docker и т. п.) для текущего
  фундамента **не нужны**; сборка и запуск не требуют доступа в сеть.

## Быстрый старт

```sh
npm ci        # воспроизводимая установка зависимостей по package-lock.json
npm run dev   # режим разработки на http://localhost:3000
```

Стартовая страница: <http://localhost:3000>.

## Production-сборка и запуск

```sh
npm run build # production-сборка Next.js
npm start     # запуск собранного приложения на http://localhost:3000
```

`npm start` обслуживает результат `npm run build`; порт по умолчанию — 3000,
можно переопределить: `npm start -- --hostname 127.0.0.1 --port 3101`.

## Скрипты

| Команда             | Назначение                                            |
| ------------------- | ----------------------------------------------------- |
| `npm run dev`       | сервер разработки Next.js (localhost:3000)            |
| `npm run build`     | production-сборка                                     |
| `npm start`         | запуск production-сборки (localhost:3000)             |
| `npm run lint`      | ESLint (flat config, `eslint.config.mjs`)             |
| `npm run typecheck` | TypeScript, `tsc --noEmit` (strict включён)           |
| `npm test`          | Vitest (smoke-тест стартовой страницы в `tests/`)     |

## Стек

- [Next.js 16](https://nextjs.org/docs/app) (App Router, `src/`, Turbopack) + React 19
- TypeScript (strict, alias `@/*` → `src/*`)
- Tailwind CSS 4
- ESLint 9 (flat config) + `eslint-config-next`
- Vitest 5

## Что ещё НЕ реализовано

Это только foundation (TASK-001). Пока отсутствуют и не притворяются работающими:

- авторизация и аккаунты (Better Auth, bootstrap первого пользователя);
- база данных (PostgreSQL + Drizzle, миграции), хранение задач;
- интерфейс менеджера задач: Inbox/Today/Upcoming, проекты, задачи, повторения;
- дизайн-система shadcn/ui, тёмная/светлая тема как настройка, app shell и навигация;
- поиск, PWA-манифест и установка на домашний экран;
- деплой, CI/CD, резервное копирование.

Ссылки на планирование: `PRODUCT.md`, `ARCHITECTURE.md`, `DESIGN.md`, `TASKS.md`.
