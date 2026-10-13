# Orbit — native macOS Inbox (NATIVE-001)

Первый локальный вертикальный срез Orbit на Swift/SwiftUI: один экран «Входящие»
с добавлением, завершением/повторным открытием задач и локальным SwiftData
хранилищем на диске. Без сервера, аккаунтов, синхронизации и CloudKit
(`cloudKitDatabase: .none`). iOS target в этом TASK отсутствует; shared-код в
OrbitCore написан без AppKit/HTTP и пригоден для будущего iOS 17+ target, но
сборка/GUI на iOS НЕ ПРОВЕРЕНЫ.

## Структура

- `Sources/OrbitCore` — SwiftData-модель `OrbitTask` (стабильный UUID, title,
  createdAt, completedAt, nullable plannedDate/plannedTime/durationMinutes),
  валидация заголовка (trim, 1…500 Unicode scalars), disk store с явным
  save/rollback, централизованные пути хранения и разбор `--store-path`.
  Без AppKit/HTTP.
- `Sources/OrbitMac` — SwiftUI app entry и единственный экран Inbox
  (добавление по Enter/кнопке, секции «Открытые»/«Завершённые», native
  checkbox-контроль завершения, честные ошибки без подмены хранилища).
- `Tests/OrbitCoreTests` — Swift Testing: валидация, операции store, disk
  reopen regression, негативное открытие, разбор аргументов запуска.

## Временной интервал задачи (NATIVE-004, core only)

`plannedTime` — строгий ASCII `HH:mm` (00:00–23:59), `durationMinutes` — целое
1…1440; оба поля nullable и существуют только парой (обе nil или обе заданы)
и только у задачи с `plannedDate`. Store-операция `setPlannedInterval` валидирует
весь кандидат до мутации (пара/формат/границы/наличие даты/derived end) и
сохраняет явно с rollback; `setPlannedDate(nil)` очищает интервал тем же save,
перенос даты сохраняет валидную пару, а вариант с выходом derived end за
Gregorian 1900–2199 отвергается. Derived end (может переходить через полночь)
не хранится — считает pure-хелпер `TaskTimeInterval.end` целочисленной civil
арифметикой без Calendar/TimeZone/DST. UI-редактор — отдельный будущий TASK.

## Требования

- macOS 14+ (собрано и проверено на текущей системе с Xcode 27.0 / macOS 27.0 SDK).
- Для сборки используется установленный Xcode через `DEVELOPER_DIR`;
  системный `xcode-select` не переключается.

## Сборка, тесты, запуск

```sh
cd apple/Orbit

# сборка
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build

# тесты (Swift Testing; временные хранилища создаются в собственном temp)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test

# запуск GUI с хранилищем по умолчанию
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run OrbitMac

# запуск GUI на отдельном временном хранилище (для review/test)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run OrbitMac -- \
  --store-path /tmp/orbit-review/store.sqlite
```

## Хранилище

- Путь по умолчанию (централизован в `OrbitStoreLocation.defaultStoreURL()`):
  `~/Library/Application Support/OrbitNative/Orbit.store`.
- Переопределение на запуск: `--store-path <путь>` или `--store-path=<путь>`
  (`~` раскрывается; при отсутствии/пустом значении используется путь по
  умолчанию). App-слой создаёт родительский каталог выбранного пути; сама
  OrbitTaskStore каталоги не создаёт (ошибка открытия — явное состояние).
- Приложение не читает и не удаляет существующие пользовательские хранилища;
  для проверок используйте отдельный temp-путь. Ошибка открытия хранилища
  показывается как состояние ошибки — без удаления файла и без подмены на
  пустую in-memory базу.

## Границы (не входит в NATIVE-001)

Rename/delete, проекты, планирование (Today/Upcoming), notes/priority,
subtasks/recurrence, экспорт, упаковка/подпись macOS, iOS app target,
синхронизация и сервер — следующие TASK.
