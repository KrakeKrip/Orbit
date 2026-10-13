# NATIVE-002 — первый iOS Inbox

ASSIGNED, 2026-10-13. Прямое решение пользователя: iOS прежде macOS-дизайна. NATIVE-001-R1 приостановлен; NATIVE-001 не объявлен DONE и не влит. Предыдущее WAITING_FOR_NATIVE_001 отменено этим решением.

## База и одна цель

Ветка task/NATIVE-002, worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-002. Source/review base bd22a87ddf35defcdcf4b31cfa970bf4fdcb05cd; assignment HEAD записать до работы. Используется закоммиченный native core из c3172a8, который Codex проверил: build/test20 и обычный GUI persistence PASS, но macOS argument parser R1 открыт. Не считать эту базу принятой полностью.

Один результат: красивый и удобный iPhone Inbox с add/complete/reopen и локальным сохранением, запущенный в Simulator. Никаких новых функций. После этого пользователь оценивает один экран до развития других экранов.

## Scope

Только apple/OrbitIOS/: минимальный OrbitIOS.xcodeproj, shared scheme OrbitIOS, app entry, один iOS Inbox, README; reports/NATIVE-002-executor.md. .gitignore только собственные iOS build/generated артефакты. Local Swift package dependency на apple/Orbit product OrbitCore. Не переносить/переписывать macOS UI и не выделять shared UI framework; отдельный небольшой iOS View/state допустим. Core/store/model/macOS и корневые coordination docs не менять. Если нужен product core fix — сообщить конкретный BLOCKED, не делать его молча.

Bundle id local.orbit.ios, baseline iOS17+, SwiftUI, SwiftData. Без новых dependencies/project generators, signing team, Apple ID/entitlements. Build для Simulator CODE_SIGNING_ALLOWED=NO. Xcode через DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer; system xcode-select не менять.

## Один экран и визуальное направление

Русский интерфейс. В духе Todoist, адаптированный к iOS: крупный аккуратный «Входящие», спокойный системный фон, простые разделители строк, круглый control завершения слева, читаемый title справа. Один сдержанный coral/red accent для главного действия. Системная типографика и Dynamic Type; без тяжёлых карточек, градиентов, боковой панели, технических labels и пустых будущих tabs.

Компактный composer снизу в safe area: поле и очевидное действие добавления, keyboard submit. Не перекрывать последнюю строку/клавиатуру. Тексты ошибок рядом с действием, draft сохраняется. Открытые и завершённые отдельными компактными секциями, завершённые с менее ярким title и возможностью reopen. Empty state короткий, без декоративных иллюстраций. Control не менее44pt, а11y label содержит действие и title задачи; текст не обрезать молча, перенос длинных названий.

Сохранить screenshots empty/populated/completed + keyboard для визуального review. Только этот экран; дизайн macOS не переделывать. Не заявлять пользовательское одобрение дизайна заранее.

## Локальное поведение

Reuse существующий OrbitCore для validation/model/add/complete/reopen: trim1..500Unicode scalars, UUID/title/createdAt/completedAt, save/rollback. Store только внутри собственного iOS app sandbox/Application Support. Создать directory, передать явный URL OrbitTaskStore; НЕ вызывать macOS CLI resolveStoreURL, не принимать --store-path и не исправлять R1 здесь. Ошибка открытия → понятное состояние ошибки, без стирания/пустого memory fallback. CloudKit .none уже в core, никакого HTTP/login/sync.

Draft очищается только после успешной записи; отказ сохраняет ввод и показывает error. Read failure не превращает подтверждённую write в неуспех. Синхронные MainActor operations достаточно; без лишних async controllers/repositories. Mac/iPhone stores независимы — не обещать синхронизацию.

Вне scope: rename/delete/projects/dates/Today/Upcoming/notifications/search/settings/sync/macOS-дизайн/TestFlight/AppStore/device signing.

## Соразмерные checks

1. xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath <own tmp> CODE_SIGNING_ALLOWED=NO build. Записать фактические Xcode/SDK.
2. swift test в apple/Orbit с DEVELOPER_DIR (20 существующих core tests). Web/npm/DB/auth/E2E gates не запускать. Store не изменяется — не строить большой новый fault suite.
3. Собственный временный iPhone Simulator текущего runtime: install/launch, add по кнопке и keyboard, complete/reopen, terminate→launch БЕЗ reinstall между шагами; подтвердить прежние title/состояния на диске. Проверить blank rejection, длинный title, keyboard/safe areas и увеличенный text размер на своём Simulator.
4. Реальный GUI/screenshots обязательны для утверждения GUI PASS. Сохранить evidence в отдельном outputs каталоге, указать абсолютные пути в отчёте. Если доступен только build — честно PARTIALLY_VERIFIED/ограничение, не придуманный GUI PASS. Не включать png/build/stores в product commit.
5. git diff --check, scope/clean tree. Одного штатного прогона достаточно, повторять только при изменении/падении.

Не erase чужие simulators/данные, не менять личные device/settings. После evidence остановить только свой Simulator, можно удалить только свой временный device/derivedData, screenshots сохранить. Реальный iPhone отдельно НЕ ПРОВЕРЕН.

## Передача

Обычный scoped commit. Подробный reports/NATIVE-002-executor.md: start/latest SHA, files, команды/exits, реальные GUI/persistence evidence, screenshots, ограничения. В чат4–5 коротких строк: статус, полный SHA, итог/checks, путь отчёта. Остановиться до Codex review и оценки пользователем экрана. NATIVE-003/macOS-R1 не выполнять. Без merge/push/amend/rebase/reset/stash/deploy, main/другие worktrees/CRM/3000/hooks не трогать.

## Разрешённая минимальная коррекция совместимости, 2026-10-13

После BLOCKED executor bc275999edd09663f2fe7ea3681d95396d206868 Codex независимо подтвердил iOS compile error в OrbitStoreLocation.swift:9. Разрешён дополнительный product файл apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift: заменить только fallback fileManager.homeDirectoryForCurrentUser на URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true), сохранив appendingPathComponent и первичный Application Support lookup. Это вариант №1 executor report; API доступен iOS/macOS, временная неизменяющая repo typecheck-проба под arm64 iOS17 Simulator exit0.

Не менять CLI parsing/default policy/macOS R1, модели/store/schema, архитектуру пакета и поведение iOS store. Не добавлять force unwrap, новые зависимости/targets или большой refactor. Существующих20 macOS unit + реальная iOS build достаточно для этой API-замены. Затем закончить уже назначенные Simulator GUI/screenshots/persistence checks и обновить executor report/README (статус BLOCKED снять только по фактическим результатам). Сохранить историю обычным новым scoped commit, без amend/rebase. Starting correction SHA — текущий coordinator assignment HEAD, записать перед правками. Остальные границы TASK действуют.

## Review2026-10-13

Product0a351a2: TECHNICAL_REVIEW_PASS / WAITING_FOR_VISUAL_APPROVAL. reports/NATIVE-002.md содержит независимые checks и ограничения. Следующий TASK/merge не выполнялись; пользователь оценивает один iOS экран. NATIVE-001-R1 остаётся приостановленным.

Итог2026-10-13: DONE в Inbox scope, main merge14a9778 и интеграционные core20/iOS build PASS. Концепт дальнейшего интерфейса одобрен пользователем, календарные функции будущие. Реальный iPhone не проверен; macOS-R1 отдельно PAUSED.
