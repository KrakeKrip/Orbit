# Orbit

Персональный менеджер задач (в разработке). Сейчас реализован каркас веб-интерфейса:
маршруты основных разделов, адаптивная навигация (desktop sidebar / mobile bottom nav)
и выбор темы. Данных задач и аккаунтов ещё нет — экраны показывают поясняющие
заглушки. Продуктовая функциональность добавляется следующими задачами
(см. `TASKS.md` в корне репозитория).

## Требования

- **Node.js 24 LTS** (целевая версия, фиксируется `.nvmrc`; проверено на v24.21.0).
  Удобно использовать [nvm](https://github.com/nvm-sh/nvm): `nvm install` / `nvm use`
  в корне проекта подберёт версию из `.nvmrc`.
- **npm 11** (входит в комплект Node 24; проверено на npm 11.19.0).
- Для unit/e2e-тестов интерфейса нужен только браузер Chromium, который Playwright
  ставит локально в пользовательский кеш (см. ниже). PostgreSQL, Docker и другие
  системные зависимости **не нужны**; сборка и запуск не требуют доступа в сеть,
  БД и auth secrets.

## Быстрый старт

```sh
npm ci        # воспроизводимая установка зависимостей по package-lock.json
npm run dev   # режим разработки на http://localhost:3000
```

Откроется <http://localhost:3000> → перенаправление на `/today`.

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
| `npm test`          | Vitest: smoke-тесты экранов (`tests/*.test.tsx`)            |
| `npm run test:e2e`  | Playwright: пересобирает production build и гоняет браузерные тесты `tests/e2e/` на свободном loopback-порту (по умолчанию 3123, переопределяется `E2E_PORT`) |

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
- ESLint 9 (flat config) + `eslint-config-next`
- Vitest 5, Playwright 1.64 (Chromium)

UI-строки интерфейса централизованы в `src/lib/i18n/ru.ts`.

## Что ещё НЕ реализовано

Данных и серверной логики пока нет. Пока отсутствуют и не притворяются работающими:

- авторизация и аккаунты (Better Auth, bootstrap первого пользователя);
- база данных (PostgreSQL + Drizzle, миграции), хранение задач и проектов;
- создание/редактирование задач, quick-add, поиск, счётчики в навигации;
- сохранение темы в аккаунте (сейчас только на устройстве);
- PWA-манифест и установка на домашний экран;
- деплой, CI/CD, резервное копирование.

Ссылки на планирование: `PRODUCT.md`, `ARCHITECTURE.md`, `DESIGN.md`, `TASKS.md`.
