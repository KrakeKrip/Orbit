# NATIVE-006 — независимый review Codex

2026-10-13. Вердикт NEEDS_FIXES: одна маленькая R1 [P2], Today не отображает model.writeError. Product SHA `917f9608b9670b01ff10f397d8478b77979fb4c3`; assignment `5add26ef4aff9f9e8b70bd730a921af8d2641175`, source base `800b189adc9442d980cb8fb5080aa5e42efa0ff7`. Clean tree, cumulative diff --check PASS. Scope ровно три product Swift файла, один targeted test, README/report.

## Проверено независимо

- Все изменённые sources/tests и report прочитаны. Helper read-only, valid day equality, same objects/order; completed сохраняет. currentDay делегирует принятому Gregorian adapter с supplied timezone. Tests fixed UTC/Moscow/NewYork/Buddhist PASS. Scope schema/store/accepted editors не расширялся.
- App открывает ровно один model/store; две real tabs, default Today. Inbox остаётся all tasks; Today переиспользует row/editor, без новых UUID/cache. Periodic30s/appear/active пересчитывают currentDay, day-change перечитывает tasks; persisted dates не конвертируются. Реальная смена timezone/clock не выполнялась, source wiring с eventual30s refresh проверен; отсутствие отдельного notification само по себе не блокирует этот bounded-refresh slice.
- Независимый DEVELOPER_DIR Xcode27 swift test: exit0, 56/56 в7suites. Один тестовый warning: TaskDaySelectionTests.swift:70 сравнивает nonoptional String с nil, assertion всегда true. Это не доказывает no-mutation; более полезные identity/order/date/time/duration checks проходят. Неблокирующая уборка разрешена вместе с R1.
- Независимый iOS Simulator build в новых own DerivedData, CODE_SIGNING_ALLOWED=NO: exit0, BUILD SUCCEEDED. Source warnings: TodayScreen Timer.Autoconnect/Publishers без явного import Combine; плюс штатный AppIntents warning. import Combine — небольшая уборка того же файла, разрешена.
- Screenshot01-today-populated.png независимо просмотрен: три correct today tasks, completion sections/local date/two real tabs. Полные GUI flows (all6 Inbox, complete/reopen/date clear/empty action/add/relaunch/a11y) — executor evidence, новый Codex Simulator прогон не выполнялся. Это не независимый runtime fault test.
- Реальный iPhone/RTL/dark/runtime save failure не проверены; только synthetic fixture provisioning в отчёте. Нет web/legacy/DB/full повторов. Логи в `/Users/atlhnv/Codex/orbit-outputs/NATIVE-006-review-evidence/`.

## R1 [P2] — отказ записи не виден на Today

`TodayScreen.swift:20–28` читает только listError. Переиспользуемая строка вызывает IOSInboxModel.setCompleted, catch которой выставляет writeError и reload. При отказе complete/reopen read может успешно пройти, listError остаётся nil: Today снова показывает прежнее состояние без причины отказа. writeError отображается только композером Inbox, которого в Today нет. Это нарушает явный TASK-контракт «model.writeError видимы» и делает ошибку доступной лишь после переключения вкладки.

Добавить видимое читаемое model.writeError на Today, без маскировки списка/empty/read failure и без переписывания модели/complete. Не очищать shared error автоматически ради скрытия симптома; успешная существующая mutation уже очищает его в model. Исправление только TodayScreen + отчёт; две мелкие warning-cleanup правки допускаются. tasks/NATIVE-006-R1.md содержит точный scope/checks. Для error-state доказательства не нужен disk fault framework/SQLite triggers.

Неблокирующие замечания не превращать в дополнительные большие TASK: синяя системная tint у tab bar отличается от будущего coral направления; cosmetic consistency можно учесть с последующей навигацией. Date caption на полностью пустом store находится только в list, а не empty state — допустима маленькая уборка того же view, не блокирует R1 сама по себе.

NATIVE-006 не принят, merge/push/deploy отсутствуют; NATIVE-007 не назначен.
