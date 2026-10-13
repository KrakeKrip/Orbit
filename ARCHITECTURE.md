Актуально2026-10-13: NATIVE-002 интегрирован как локальная iOS база (apple/OrbitIOS + OrbitCore), main build/core20 PASS. NATIVE-001-R1 остаётся открытым для macOS CLI, iOS его resolver не вызывает. NATIVE-003 принят: nullable plannedDate civil Gregorian string, explicit save и проверенная миграция прежнего store; UI adapters фиксируют Gregorian calendar, сохраняя локальную timezone. GUI смены даты и реальный iPhone остаются непроверенными. Sync/server/полный календарь не входит. Историческое условие «NATIVE-002 после приёмки NATIVE-001» ниже заменено прямым разрешением пользователя iOS первым.

# Orbit — активная native архитектура

2026-10-12: пользователь выбрал native/local-first. Прежняя web архитектура сохранена в docs/web-baseline-2026-10-12/ARCHITECTURE.md; Next.js/PostgreSQL/Better Auth код не удалён и не переписывается. Он не нужен для запуска native прототипа.

## Стек и границы

Swift + SwiftUI, локальное SwiftData хранилище. Начальная техническая база macOS14+/iOS17+, окончательный минимум пересмотреть при подготовке iOS target по устройствам пользователя. SwiftData ModelContainer с явным cloudKitDatabase:.none: без CloudKit/сервера/аккаунта. Sync позже отдельное архитектурное решение; не обещать, что текущая схема автоматически решит конфликты/миграцию в облако.

Native код в apple/Orbit/, отдельный Swift package: OrbitCore (минимальная модель и disk store), OrbitMac (SwiftUI app entry и Inbox), OrbitCoreTests. Core не зависит от AppKit/HTTP/веб-кода и пригоден для будущего iOS target. Не создавать repository/protocol/service слои без конкретной необходимости. Не добавлять все будущие сущности заранее.

NATIVE-001 — один вертикальный срез create/complete/reopen+disk persistence в macOS Inbox, без проектов/scheduling/rename/delete. Для SwiftPM executable допускается документированный launch через swift run OrbitMac; Xcode project/iOS app target — отдельный NATIVE-002 после приёмки NATIVE-001; Xcode уже установлен. Нельзя заявлять, что shared source означает проверенную iOS сборку.

Local store path централизован; для tests/GUI review явно отдельный temp path. App startup не удаляет/пересоздаёт повреждённый store. Mutation success только после явного save; failure не теряет draft и не считается записанным. Stable UUID для объектов, версия schema меняется осознанно, пользовательские stores не используются в tests. SwiftUI/SwiftData main actor boundaries простые и явные, без sync engine/HTTP/dependency frameworks.

## Tooling и проверка

Окружение подтверждено2026-10-13: /Applications/Xcode.app (Xcode27.0), macOS/iOS SDK, iOS27.0 runtime и список Simulator devices доступны. System xcode-select остаётся CLT; для команд использовать DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer, без глобального переключения. Native iOS Inbox проверен build/Simulator в NATIVE-002, реальный iPhone пока не проверен; baseline iOS17 runtime не проверен.

swift build / swift test на macOS, disk reopen regression; реальный GUI create/complete/reopen/relaunch на собственном synthetic store. Compile/unit/UI/device evidence разделять. Web full gates на каждом native задании не запускать, пока web код не меняется.

## Официальные источники

- SwiftData ModelContainer: https://developer.apple.com/documentation/swiftdata/modelcontainer
- Явный disk URL/configuration: https://developer.apple.com/documentation/swiftdata/modelconfiguration
- Отключение sync: https://developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/none
- Simulator требует Xcode: https://help.apple.com/xcode/mac/current/en.lproj/devfd9e28378.html

## Временной интервал, assignment NATIVE-004

Два nullable поля plannedTime HH:mm и durationMinutes1..1440 требуют plannedDate, pair всегда оба nil либо оба установлены. Это wall-clock/civil interval, без UTC instants/timezone offsets. Pure helper derive end; crossing midnight допускается, end не хранится и должен помещаться в1900–2199. Прежний clearDate очищает pair одним save, date move сохраняет валидную pair. Shared core+tests сейчас, iOS editor отдельным NATIVE-005, calendar rendering позже. Любая additive schema проверяется по own fixture реальной предыдущей версии, без reset stores.
