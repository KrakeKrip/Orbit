# NATIVE-007C — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007C`; ветка `task/NATIVE-007C`; **starting SHA `9618c7ecfa86dbf9f0f990584cfb245eb028868c`**; source base `5e5274964465142093471535d7618ddda34d07fb` (merge-base совпадает — принятый NATIVE-007B с R1b, core 50); дерево чистое.
- Прочитаны AGENTS/DESIGN/tasks/NATIVE-007C.md; core/Today/Inbox/editors/projection не трогались.
- Tooling: Xcode 27.0 через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `xcode-select`/signing/Apple ID/system settings не менялись.

## Изменённые файлы

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | collapsible untimed-область: default до 3 строк; «Ещё N» (≥44pt, a11y id `untimed-toggle`) раскрывает bounded scroll (~260pt, ~⅓ экрана) со всеми строками; «Свернуть» возвращает к 3; при 0 — компактная пустая строка; при 1–3 — без фиктивного «Ещё»; `onChange(of: selectedDay)` сбрасывает collapse; строки переиспользуют существующие InboxRowView/actions/sheets; date controls и grid остаются видимы |
| `apple/OrbitIOS/README.md` | секция collapsible untimed (NATIVE-007C) |

Не менялись: core (вся модель/store/helpers/тесты), TodayScreen/InboxScreen/TaskDateSheet/TaskIntervalSheet/DayTimelineView/OrbitIOSApp, project/scheme, root docs, web.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift test` (apple/Orbit, DEVELOPER_DIR) | exit 0 — **50/50 в 6 suites** (core не менялся в 007C) |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n7c-dd CODE_SIGNING_ALLOWED=NO build` | после фикса static placement и Color.orbitAccent — exit 0, **BUILD SUCCEEDED**; DerivedData удалён |
| Fixture (временный генератор, удалён) | 13 задач: 12 untimed + 1 timed на 2026-10-13 в own tmp store |
| Свой Simulator | iPhone 17 iOS 27.0 (UDID 0A879A39-…), install, fixture в СВОЮ пустую песочницу до launch, launch; после evidence — terminate/shutdown/`simctl delete` (удалён только мой), derivedData/tmp удалены |

## GUI evidence (pixel-скриншоты; каталог `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/`)

1. **Collapsed default (3 строки)**: Календарь показывает date controls (‹ 13 Oct 2026 › Сегодня), область «Без времени» с 3 строками, «Ещё 9» (коралловая кнопка ≥44pt с chevron.down). Скриншот `01-collapsed-3-tasks.png`.
2. **Expanded**: клик «Ещё 9» → bounded scroll region (~260pt) показывает все 12 untimed строк с внутренним скроллом; date controls и grid остаются видимы ниже. Скриншот `02-expanded-12-tasks.png`.
3. **Свернуть**: клик «Свернуть» → возврат к 3 строкам. Скриншот `03-collapsed-after.png`.
4. **Смена дня**: Next → 14 Oct → collapse сброшен до 3 строк, grid не сброшен. Скриншот `04-day-change-collapse-reset.png`.
5. **sqlite**: до/после toggle — 13 строк без изменений (collapse не пишет в БД).

## Ограничения / не проверено

- Реальный iPhone/тёмная тема/RTL не проверялись.
- Dynamic Type accessibility-large не прогонялся (системные шрифты везде).
- Вечерние часы 23:00–24:00 в сетке не скриншотились (см. NATIVE-007B ограничения по scroll); collapsible область «Без времени» проверена полностью.
- Тестовый framework не добавлялся (по TASK); UI-поведение проверено визуально на Simulator.

## Git

- Ветка `task/NATIVE-007C`; starting SHA `9618c7ecfa86dbf9f0f990584cfb245eb028868c`; обычные scoped коммиты; полный latest SHA в чате.
- `git diff --check` чисто; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/чужие worktrees/CRM/3000/hooks/xcode-select/Apple ID/signing не менялись. NATIVE-007D/drag/resize/3дня/Месяц/AI не начинались.
