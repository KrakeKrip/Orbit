# NATIVE-002 — локальный Inbox на iPhone

**PREPARED / WAITING_FOR_NATIVE_001**, 2026-10-13. Это подготовленное задание, не разрешение параллельно переписывать незавершённый NATIVE-001.

## Одна цель / обязательная база

Запустить тот же принятый локальный Inbox как настоящее iOS-приложение: add/complete/reopen, данные сохраняются после завершения процесса. Без новых функций, сервера и синхронизации.

Зависимость: NATIVE-001 должен пройти независимый review и локальную интеграцию в main. Сейчас NATIVE-001 имеет незакоммиченную apple/ работу, поэтому точный starting/review SHA и отдельный worktree NATIVE-002 координатор фиксирует ПОСЛЕ его приёмки. Не копировать WIP из чужого worktree и не начинать от c2b1fb9, где shared core ещё не принят. При передаче без утверждённой базы вернуть WAITING_FOR_NATIVE_001, не реализовывать соседний TASK.

Будущая ветка task/NATIVE-002, worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-002; создавать/назначать их будет Codex после приёмки зависимости. Before edits проверить root/branch/clean tree и записать полный starting SHA.

## Малый scope

Минимальный iOS app target в apple/OrbitIOS/ (OrbitIOS.xcodeproj, shared scheme, app entry, Inbox UI/конфигурация локального store, короткий README), local package dependency на существующий apple/Orbit OrbitCore. Если Inbox SwiftUI view из NATIVE-001 переносим — минимально вынести только этот view в shared UI target apple/Orbit, чтобы обе платформы использовали его; не переписывать store/model и не вводить новый architecture framework. Допустимы только необходимые Package.swift/macOS app entry wiring изменения для общего view. Если выделение UI оказывается большой переработкой, сообщить evidence координатору до расширения scope.

Не генерировать сразу большой multiplatform shell/screens/settings/sync engine. Не устанавливать project generators/новые dependencies, не менять system xcode-select, Apple ID, signing teams/entitlements. Для Simulator достаточен локальный build без device signing. Bundle id для прототипа local.orbit.ios, схема OrbitIOS; iOS17+ baseline, сборка текущим SDK не доказывает запуск на всех старых версиях.

## Поведение

Reuse OrbitCore validation/model/store из принятого NATIVE-001: stable UUID, title, completion/reopen, explicit save/rollback. Только локальная SwiftData, cloudKitDatabase:.none. Нет account/login/HTTP; данные iPhone и Mac независимы, обмен ими НЕ обещать.

На iPhone: Входящие, native field+Добавить, keyboard submit, open/completed задачи и отдельный control completion. Safe areas/soft keyboard/Dynamic Type/accessibility labels; не фиксировать desktop ширину. Empty/error состояния реальные. Draft очищается только после успешного save, error не теряет ввод; startup не стирает store и не подменяет его пустым memory store. Без rename/delete/projects/scheduling/notifications/search.

Store в собственном app sandbox/Application Support, не web DB и не macOS personal store. Для review synthetic данные только в специально созданном Simulator/app sandbox; не сбрасывать чужие устройства или личные данные. После kill/relaunch тот же установленный app читает те же id/title/completion. Не переустанавливать/удалять app между persistence проверками.

## Окружение подтверждено координатором 2026-10-13

/Applications/Xcode.app, Xcode27.0, iOS27.0 SDK и Simulator runtime доступны; simctl list runtimes/devices вне песочницы exit0. System xcode-select остаётся CommandLineTools — перед командами использовать DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer. Ошибка CoreSimulatorService внутри песочницы не означает отсутствие компонента; использовать штатный permission flow, не чинить систему/хуки обходом.

## Целевые проверки

1. xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath <own tmp dir> CODE_SIGNING_ALLOWED=NO build (путь/schema уточнить только под реальное созданное дерево).
2. swift test для существующего apple/Orbit core с Xcode DEVELOPER_DIR; swift build macOS product после shared UI wiring. Не повторять web/DB/auth/E2E suites.
3. Собственный временный iPhone Simulator текущего runtime (не erase существующего). Build→install→launch. Реально выполнить add через кнопку и keyboard, complete/reopen, terminate→launch; данные/id/состояние сохранились. Пустой ввод отвергается, ошибка не утверждает success. Проверить доступный screen/keyboard layout и одну увеличенную system text настройку на своём simulator, без переписывания пользовательских настроек.
4. Зафиксировать GUI evidence: screenshots до/после relaunch и точные действия/выводы в отчёте. Build не равен GUI PASS. Если UI tools недоступны — честное PARTIALLY_VERIFIED с конкретным ограничением, не придуманный PASS. Persistence Swift unit из NATIVE-001 не заменяет проверку app sandbox на iOS.

Реальный iPhone не обязательный gate этого TASK и НЕ ПРОВЕРЕН до отдельной проверки; signing/App Store/TestFlight/deploy не выполнять. Очистить свои derivedData/screenshots вне tracked files/собственный temporary simulator после evidence; не удалять stores пользователя и не выключать чужие booted simulators.

## Завершение

Обычный scoped commit, git diff --check и clean tree. Подробный reports/NATIVE-002-executor.md: starting/latest SHA, files, exact commands/exits, Xcode/runtime/destination, actual GUI/disk evidence, непроверенное/limitations. В чат только4–5коротких строк: READY_FOR_REVIEW/BLOCKED/честный статус, полныйSHA, итог, checks, путь отчёта. Остановиться до review Codex; NATIVE-003/web TASK-009A не начинать.

Без merge/push/amend/rebase/reset/stash/deploy, main/другие worktrees/CRM/localhost3000/hooks changes. No secrets/signing profiles/real personal data. Код платформы не даёт готовой синхронизации.
