# NATIVE-002 — независимый review Codex

Дата2026-10-13. Product HEAD 0a351a23d13a9479cbe248214faed5e283787f25; assignment 3f5feecf1f3ed40ef6404fd9cb9f16fba811f82a; source/review base bd22a87ddf35defcdcf4b31cfa970bf4fdcb05cd.

Вердикт: TECHNICAL_REVIEW_PASS / WAITING_FOR_VISUAL_APPROVAL. Блокирующих дефектов в штатном срезе Inbox не обнаружено. Это не пользовательское одобрение дизайна и не готовность релиза/реального iPhone. Merge/push не выполнялись; следующий TASK не назначен до оценки экрана.

## Проверено независимо

- Git root/branch/HEAD, clean tree; cumulative diff --check PASS. Прочитаны iOS Sources, project/scheme, README, разрешённая core API-замена, executor report и scope. Core изменён ровно на NSHomeDirectory fallback, macOS parser R1 не переделан.
- iOS MainActor store/state, собственный app sandbox URL, explicit save через core, no CloudKit/HTTP/login; read/write outcomes раздельны, title validation из core, draft очищается после save, failure не выдаётся за success. Отдельные completion hit areas и а11y labels с title, длинный title переносится, safeAreaInset composer.
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination generic/platform=iOS Simulator -derivedDataPath <свой tmp>/DerivedData CODE_SIGNING_ALLOWED=NO build: exit0, BUILD SUCCEEDED. Один штатный warning metadata extraction skipped (AppIntents не используется), не compile warning. Собственный чистый DerivedData.
- DEVELOPER_DIR=... swift test в apple/Orbit: exit0, 20/20. Исторические web gates не запускались.
- Создан свой iPhone17 Simulator A5D0C7F9-06CE-4F04-BB1A-57270998EF28, runtime iOS27.0 24A434; на старте booted устройств нет. Install собственного build, launch: реальное empty окно. Независимый GUI ввод через CUA/Device Hub: синтетический draft J, add кнопкой → Открытые; круг completion → Завершённые/Снова открыть; simctl terminate→launch БЕЗ reinstall → то же completion подтверждено AX. Read-only SQLite своего app sandbox подтверждает J, completedAt не NULL, UUID 9C71D1892B224129B7C611FD8306A01F.
- GUI tool нестабилен: hardware typeText отказал frontmostApplicationChanged, AX keyboard click давал invalid ID; coord tap после актуального screenshot позволил штатный add/complete. После relaunch попытки reopen получили noWindowsAvailable при доступном screenshot/AX. Независимое iOS reopen поэтому НЕ заявлено; оно заявлено GLM, согласуется с core20 и читаемым кодом. Не менялись accessibility permissions/пользовательские настройки для обхода.

## Визуальные материалы

Просмотрены executor screenshots 01-empty,08-after-terminate-relaunch,10-dynamic-type-accessibility-large. Штатный интерфейс соответствует одному простому Inbox: крупный системный title, разделители, round controls/coral accent, composer. При accessibility-large text увеличен, composer остаётся доступен над клавиатурой; часть длинной строки ниже viewport требует scroll — screenshot сам по себе не доказывает весь scroll flow. Фактическое пользовательское одобрение внешнего вида ещё отсутствует. Pixel snapshot executor сохранён вне product tree:
/Users/atlhnv/Codex/orbit-outputs/NATIVE-002/

GLM отдельно сообщает сценарии кнопка/keyboard submit, blank refusal, complete/reopen + два relaunch, длинныйtitle, Dynamic Type и3точныхSQLite titles. Не приписывать весь executor протокол независимому Codex.

## Ограничения

Реальный iPhone, подпись/TestFlight/AppStore, baseline iOS17 runtime, dark/RTL/locales, настоящий save-failure runtime не проверены. Граница500 в core unit, не в независимом GUI. Product качество/визуальное направление требует оценки пользователем одного экрана.

NATIVE-001-R1 остаётся открытым/приостановленным и не объявляется DONE; iOS не вызывает его CLI parser. Native implementation всё ещё в task branches, main содержит координационные документы. Не расширять следующими функциями до визуальной оценки.

После review собственный Simulator остановлен/удалён, свой DerivedData удалён; build/test logs сохранены в outputs/NATIVE-002-review-evidence. Чужие Simulator/devices/stores/CRM/Xcode settings не изменены.

## Приёмка и локальная интеграция2026-10-13

Пользователь одобрил визуальное направление отдельного интерактивного концепта и попросил переходить к разработке. NATIVE-002 принимается как технический Inbox foundation в своём scope; одобрение концепта не выдаётся за реализацию Today/Calendar. Main merge14a977810bba9dc4c2bfe15bfdc4adcf177f2c4c, только два coordination conflicts: актуальная очередь main сохранена, полное assignment/review из task ветки сохранено. Apple sources побайтово идентичны task/NATIVE-002. На main независимо swift test20/20 и clean-DerivedData iOS Simulator build exit0/BUILD SUCCEEDED (один штатный AppIntents metadata warning). Повтор GUI не требовался: product sources не изменились. Реальный iPhone и прочие ограничения выше сохраняются. macOS-R1 не закрыт. Push/deploy не выполнялись.
