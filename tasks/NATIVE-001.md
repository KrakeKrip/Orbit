# NATIVE-001 — первый локальный Inbox на macOS

Обновлено2026-10-13: Xcode установлен, TASK ещё не отправлялся GLM. Scope остаётся macOS Inbox; iOS target — отдельный NATIVE-002 после приёмки.

## Одна цель / старт

Показать полезный SwiftUI Inbox без сервера: add, complete/reopen и сохранение после перезапуска. Ветка task/NATIVE-001, worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-001. База review da5328f9ef80e9bb9b4b3c0e1d5feed243dd7453 (до priority docs). Старт — новый coordinator assignment HEAD, полный SHA записать до работы; проверить root/branch/status. Прочитать новые PRODUCT/ARCHITECTURE/DESIGN/AGENTS, старые web assignments не выполнять.

## Имеющиеся стартовые материалы

В worktree уже есть untracked apple/Orbit Swift files (Package/core/macOS stub/tests). По уточнению пользователя это НЕ результат отправленного GLM TASK; источник не атрибутировать исполнителю. Они разрешены как исходные материалы в scope NATIVE-001: изучить и доработать, не удалять/reset/clean. Координатор сохранил исходный snapshot+SHA256 manifest: /Users/atlhnv/Codex/2026-10-08/orbit-orbit-todoist-next-js-typescript/work/native001-starter-2026-10-13-_3cu15oh. До изменений сравнить наличие/хэши, в отчёте отделить исходные файлы от своих правок. Если с момента snapshot появились другие изменения — остановить затронутую работу и сообщить. Не переносить backup/store/logs в tracked tree; сам starting SHA пока не содержит этот untracked starter.

## Небольшой scope

Только apple/Orbit/: Package.swift, Sources/OrbitCore (минимальная SwiftData model+store), Sources/OrbitMac (app entry+один Inbox view), Tests/OrbitCoreTests, README. Один маленький launcher/script допустим только если нужен реальный запуск window; без генератора большого Xcode project. reports/NATIVE-001-executor.md; .gitignore только .build/локальные stores/generated artifacts внутри native directory. Web src/npm/Drizzle/auth/coordination docs не менять.

SwiftData stable UUID/title/createdAt/completedAt, без всей будущей схемы projects/planning/recurrence. Локальный ModelContainer, cloudKitDatabase:.none, явный disk URL; core без AppKit/HTTP. SwiftPM executable OrbitMac на macOS14+; core пригоден для будущего iOS17+ target. Использовать установленный Xcode через DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer для swift build/test/run, проверить фактический Swift/SDK. System xcode-select не переключать. Если framework/GUI недоступен — точный BLOCKED/частично проверено, не заменять SwiftData самодельной БД и не устанавливать tooling автоматически.

## UX / сохранение

Входящие: field+Добавить, Enter add; title trim1..500 Unicode scalars, empty invalid и draft сохранён. Список open/completed, завершить/открыть снова отдельным native control. Stable order createdAt/id, без лишних tabs/sidebar/заглушек будущих screens. Save явно; input очищается только после успеха. При error не показывать сохранение успешным; сохранить draft, rollback незаписанное состояние. Store open failure — понятное состояние ошибки, без удаления БД/перехода на пустую memory БД.

Default store отдельный App Support OrbitNative, path централизован и документирован. Для review/test нужен explicit override store URL/path (например --store-path) с собственным temp store. Не читать/удалять существующие пользовательские stores, не импортировать web data и не запускать SQL/server. Shared core минимальный, без generic repositories/protocol hierarchy/sync engine. Rename/delete/projects/scheduling/notes/priority/export/iOS app target — следующие TASK, не реализовывать сейчас.

## Целевые доказательства

swift build и swift test (с фактическим runtime/SDK). Unit: trim/empty/limit, create id, complete/reopen; disk regression создать/save/закрыть первый container, открыть новый по тому же temp URL, UUID/title/completion сохранились. Не только in-memory test. Негативная ошибка opening/save не очищает существующие данные/не считается success; простой детерминированный случай, без большого fault framework.

GUI: запустить реальное macOS окно на own synthetic temp store, создать→complete→reopen→закрыть/повторно открыть и убедиться, что строка сохранена. Keyboard Enter, native system appearance и понятные labels. Скриншот/точные действия в отчёте если инструмент доступен; без GUI доступа не заявлять GUI PASS. UI нельзя считать проверенным по сборке. Xcode27.0 и iOS27.0 Simulator теперь доступны и проверены координатором. В NATIVE-001 iOS target всё равно не добавлять: native iOS build/GUI/device остаются НЕ ПРОВЕРЕНЫ до отдельного NATIVE-002. Shared Swift code не равен iOS готовности.

Не запускать web full gates. Не делать ad hoc data seeding в default personal store. Чистить только собственные tmp data; .build/logs/stores не коммитить. macOS app packaging/signing/notarization/App Store вне scope, launch инструкция должна быть конкретной и повторяемой.

## Передача

Один обычный scoped implementation commit и отчёт reports/NATIVE-001-executor.md (start/latest SHA,files,commands/exits,actual GUI/disk evidence,not verified/limitations). В чат только4–5коротких строк: READY_FOR_REVIEW/BLOCKED,full SHA,итог,checks,путь файла. Остановиться до Codex review; NATIVE-002/web TASK-009A не начинать. Без merge/push/amend/rebase/reset/stash/deploy; main/старые worktrees/CRM/localhost3000/Xcode settings/hooks не трогать; без secrets/реальных пользовательских данных.

Источники API: https://developer.apple.com/documentation/swiftdata/modelcontainer ; https://developer.apple.com/documentation/swiftdata/modelconfiguration .
