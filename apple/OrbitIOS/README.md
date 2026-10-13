# Orbit — iOS Inbox (NATIVE-002)

Один экран «Входящие» для iPhone (Todoist-настроение: крупный системный заголовок,
компактные строки с круглым контролем завершения слева, спокойный системный фон,
один сдержанный coral/red accent у главного действия). Локальное SwiftData
хранилище в собственной песочнице приложения через закоммиченный пакет
`apple/Orbit` (product `OrbitCore`). Без сервера, аккаунтов, синхронизации,
CloudKit (`cloudKitDatabase: .none` уже в core), без новых зависимостей.

## Структура

- `OrbitIOS.xcodeproj` — минимальный handwritten-проект (objectVersion 70,
  `PBXFileSystemSynchronizedRootGroup` для папки `OrbitIOS`, локальная package
  reference `../Orbit`, shared scheme `OrbitIOS`). Без project generators.
- `OrbitIOS/OrbitIOSApp.swift` — app entry: открытие store при старте,
  явное состояние ошибки хранилища (без удаления файла и без in-memory fallback).
- `OrbitIOS/IOSStore.swift` — единственный URL хранилища внутри sandbox:
  `Application Support/Orbit/store.sqlite` (каталог создаётся перед открытием).
  macOS CLI resolver (`OrbitStoreLocation.resolveStoreURL`) на iOS не вызывается,
  launch-override не принимается.
- `OrbitIOS/IOSInboxModel.swift` — `@MainActor @Observable` состояние экрана:
  операции через OrbitCore (валидация/список/complete/reopen), успех только после
  явного `save()`, при ошибке draft сохраняется.
- `OrbitIOS/InboxScreen.swift` — экран: NavigationStack large title «Входящие»,
  секции «Открытые»/«Завершённые», круглый completion-контроль ≥44pt с a11y
  label «действие: задача», перенос длинных названий, композер в нижнем safe
  area (клавиатура его поднимает), inline-ошибка, честный empty state.

## Требования

- Xcode 27.0 через `DEVELOPER_DIR` (системный `xcode-select` не меняется),
  iOS 17+ baseline, Simulator build с `CODE_SIGNING_ALLOWED=NO`,
  bundle id `local.orbit.ios`. Подпись/teams/Apple ID не настраиваются.

## Сборка и запуск

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd apple/OrbitIOS

xcodebuild -project OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath <own tmp> \
  CODE_SIGNING_ALLOWED=NO build
```

Core-тесты (независимо): `DEVELOPER_DIR=... swift test` в `apple/Orbit`.

## Хранилище

Только внутри собственной песочницы приложения
(`<app container>/Library/Application Support/Orbit/store.sqlite`). Stores Mac и
iPhone независимы; синхронизации нет и не обещается.

## Статус NATIVE-002 (проверено 2026-10-13)

Собрано и проверено на Simulator (Xcode 27.0, iOS 27.0 runtime, iPhone 17,
`CODE_SIGNING_ALLOWED=NO`): add по кнопке «+» и клавиатурному «Готово»,
complete/reopen круглым контролом, terminate→relaunch без reinstall — задачи и
состояния восстанавливаются с диска; blank rejection с видимой ошибкой; длинный
название переносится на несколько строк; Dynamic Type на accessibility-large;
композер не перекрывается клавиатурой. Скриншоты — вне product tree
(пути в `reports/NATIVE-002-executor.md`). Реальный iPhone НЕ ПРОВЕРЕН.

Совместимость OrbitCore с iOS обеспечена разрешённой однострочной заменой
fallback в `apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift`
(`NSHomeDirectory()` вместо `homeDirectoryForCurrentUser`); поведение macOS
не изменено (20/20 core tests).
