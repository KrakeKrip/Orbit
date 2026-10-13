# Orbit — iOS Inbox (NATIVE-002/003/004/005)

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
  операции через OrbitCore (валидация/список/complete/reopen/plannedDate/
  setPlannedInterval), успех только после явного `save()`, при ошибке draft
  сохраняется.
- `OrbitIOS/TodayScreen.swift` — вкладка «Сегодня» (NATIVE-006): read-only
  срез задач на текущий локальный Gregorian день через `TaskDaySelection`;
  те же строки/actions/editors, что в Inbox (complete/reopen, date/interval
  editors); заголовок «Сегодня» + видимая локальная дата; честный empty
  state «На сегодня задач нет» с действием «Добавить во Входящих»
  (переключает на живую вкладку, не создаёт задачу). День пересчитывается
  на appear/active и не реже раза в минуту; без сетки/overdue/quick-add.
- `OrbitIOS/InboxScreen.swift` — экран: NavigationStack large title «Входящие»,
  секции «Открытые»/«Завершённые», круглый completion-контроль ≥44pt с a11y
  label «действие: задача», краткая подпись даты и интервала
  («09:00–09:30», «23:30–01:00 (+1 день)»), calendar/clock-действия в строке
  (clock — только у датированной задачи), перенос длинных названий, композер
  в нижнем safe area (клавиатура его поднимает), inline-ошибка, честный
  empty state; один editor за раз (presentation kind+UUID).
- `OrbitIOS/TaskDateSheet.swift` — маленький редактор даты (NATIVE-003):
  native wheel `DatePicker`, draft по умолчанию — сегодняшний local civil день,
  явные «Сохранить»/«Отмена» (открытие/отмена ничего не пишут), «Убрать дату»
  для назначенной; отказ показывает ошибку и оставляет редактор для retry.
- `OrbitIOS/TaskIntervalSheet.swift` — редактор времени/длительности
  (NATIVE-005): два подписанных текстовых поля («Начало» ЧЧ:ММ, «Длительность,
  мин»), draft из сохранённых значений при каждом открытии (defaults 09:00/30),
  видимые формат/диапазон, «Сохранить»/«Отмена»/«Убрать время» (для
  назначенного интервала); открытие/отмена/swipe не пишут; отклонённый draft
  не воскресает; невалидный ввод не превращается в nil/nil — core остаётся
  источником правил (пара передаётся целиком), отказ показывает русскую
  ошибку и сохраняет sheet для retry.

## Дата и время задачи (NATIVE-003/004/005)

`plannedDate` — nullable civil строка `YYYY-MM-DD` (Gregorian 1900–2199,
валидация `TaskPlannedDate`, store-операция `setPlannedDate` с явным save и
rollback, невалидное значение отвергается до мутации). Дата не превращается в
UTC instant и не зависит от timezone; `Date` — только UI adapter `DatePicker`.
Назначение даты не скрывает задачу и не меняет порядок списка (Today/календарь
— будущие TASK). Старые stores обновляются лёгкой миграцией optional-поля:
прежние строки, UUID и completion сохраняются, plannedDate=nil — проверено
upgrade-прогоном на store, созданном принятым кодом NATIVE-002.

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
