# Orbit — смена приоритета, 2026-10-12

По прямому решению пользователя: native iOS/macOS и локальные данные раньше sync/web. Продуктовая реализация не менялась: Swift кода ещё нет, web TASK-001–008 сохраняются принятыми. TASK-009A приостановлен; root specs заменены актуальными native/local-first, прежние exact snapshots сохранены в docs/web-baseline-2026-10-12. История/пользовательские файлы/данные/процессы не удалялись, push/deploy не выполнялись.

Назначен только tasks/NATIVE-001.md: маленький реальный macOS Inbox add/complete/reopen+SwiftData disk persistence, shared Swift core, без сервера. Swift6.4/CommandLineTools/macOS SDK подтверждены read-only; full Xcode в /Applications не найден, xcodegen не найден. Системный developer directory не менялся. macOS build/GUI и iOS build/device пока не проверены; task исполнителю предстоит выполнить. iOS target — следующий отдельный шаг после наличия Xcode, без отказа от платформы.

SwiftData ModelConfiguration cloudKitDatabase.none выбран для явного отключения managed sync; официальные ссылки в ARCHITECTURE.md. Будущая sync стратегия и перенос web данных не решены. Ранее обсуждённые60–65% web MVP не являются оценкой native готовности.
