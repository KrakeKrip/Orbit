# Orbit — активная native архитектура

2026-10-12: пользователь выбрал native/local-first. Прежняя web архитектура сохранена в docs/web-baseline-2026-10-12/ARCHITECTURE.md; Next.js/PostgreSQL/Better Auth код не удалён и не переписывается. Он не нужен для запуска native прототипа.

## Стек и границы

Swift + SwiftUI, локальное SwiftData хранилище. Начальная техническая база macOS14+/iOS17+, окончательный минимум пересмотреть при подготовке iOS target по устройствам пользователя. SwiftData ModelContainer с явным cloudKitDatabase:.none: без CloudKit/сервера/аккаунта. Sync позже отдельное архитектурное решение; не обещать, что текущая схема автоматически решит конфликты/миграцию в облако.

Native код в apple/Orbit/, отдельный Swift package: OrbitCore (минимальная модель и disk store), OrbitMac (SwiftUI app entry и Inbox), OrbitCoreTests. Core не зависит от AppKit/HTTP/веб-кода и пригоден для будущего iOS target. Не создавать repository/protocol/service слои без конкретной необходимости. Не добавлять все будущие сущности заранее.

NATIVE-001 — один вертикальный срез create/complete/reopen+disk persistence в macOS Inbox, без проектов/scheduling/rename/delete. Для SwiftPM executable допускается документированный launch через swift run OrbitMac; Xcode project/iOS app target — следующий отдельный шаг, когда доступен полный Xcode. Нельзя заявлять, что shared source означает проверенную iOS сборку.

Local store path централизован; для tests/GUI review явно отдельный temp path. App startup не удаляет/пересоздаёт повреждённый store. Mutation success только после явного save; failure не теряет draft и не считается записанным. Stable UUID для объектов, версия schema меняется осознанно, пользовательские stores не используются в tests. SwiftUI/SwiftData main actor boundaries простые и явные, без sync engine/HTTP/dependency frameworks.

## Tooling и проверка

Текущее окружение: Swift6.4, CommandLineTools и macOS SDK доступны, /Applications/Xcode*.app не найден. Системный xcode-select не переключать, Xcode не устанавливать автоматически. iOS Simulator и device signing не подтверждены.

swift build / swift test на macOS, disk reopen regression; реальный GUI create/complete/reopen/relaunch на собственном synthetic store. Compile/unit/UI/device evidence разделять. Web full gates на каждом native задании не запускать, пока web код не меняется.

## Официальные источники

- SwiftData ModelContainer: https://developer.apple.com/documentation/swiftdata/modelcontainer
- Явный disk URL/configuration: https://developer.apple.com/documentation/swiftdata/modelconfiguration
- Отключение sync: https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/none
- Simulator требует Xcode: https://help.apple.com/xcode/mac/current/en.lproj/devfd9e28378.html
