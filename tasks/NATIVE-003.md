# NATIVE-003 — дата задачи в iOS Inbox

DONE, 2026-10-13. Одна небольшая вертикальная функция перед календарём: назначить, поменять и убрать дату задачи с сохранением на диске. Без времени/длительности/дедлайна и без новых календарных экранов.

## Старт

Ветка task/NATIVE-003; worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-003. Review/source base — main coordinator assignment HEAD, точный полный SHA будет в handoff и должен быть записан исполнителем до правок. Проверить root/branch/HEAD/clean tree. Прочитать AGENTS/PRODUCT/ARCHITECTURE/DESIGN и этот TASK. Принятая iOS база NATIVE-002 (product0a351a2, main merge14a9778); macOS-R1 PAUSED, web PAUSED.

## Scope

Разрешены только:
- apple/Orbit/Sources/OrbitCore/OrbitTask.swift — одно nullable civil date поле plannedDate с default nil; UUID/title/createdAt/completedAt и entity identity сохранить.
- apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift — одна операция setPlannedDate по UUID через explicit save/rollback.
- один небольшой pure helper apple/Orbit/Sources/OrbitCore/TaskPlannedDate.swift и его targeted tests в Tests/OrbitCoreTests; дополнения OrbitTaskStoreTests для новой операции/persistence.
- apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift, InboxScreen.swift, один новый TaskDateSheet.swift; README iOS и reports/NATIVE-003-executor.md.
Ориентир не более6 product Swift файлов; не добавлять framework/repositories/generic scheduler. Проект с synchronized root включает новый iOS файл автоматически, генераторы/зависимости/signing/targets не нужны. Core store location/macOS/корневые coordination docs/web не менять. Если обнаружен отдельный blocker — точный отчёт, без самостоятельного расширения.

## Контракт

plannedDate — String? строго YYYY-MM-DD, Gregorian civil date1900–2199 (как продуктовый календарный контракт). Правильные месяцы/дни/високосность, nil снимает дату. Невалидное значение отвергается ДО мутации. Никаких преобразований сохранённой даты в UTC instant или смены даты из-за timezone; Date используется только как UI adapter DatePicker. Новый параметр не обязателен при create, существующие callers и stores должны работать с nil. Не добавлять time/duration/deadline/updatedAt/revision/sync поля.

Операция по своему local UUID: неизвестный id → имеющаяся taskNotFound ошибка; дата меняется через store, save явно, rollback при save throw. Completion/reopen/title/id не меняются. Повтор того же значения безопасен, не создаёт новую task. Не менять порядок списка и не скрывать задачи после назначения даты: Today экран ещё не реализован, все прежние задачи доступны в текущем Inbox.

## UI — один маленький редактор даты

В строке Inbox понятный calendar action (hit area≥44pt, а11y содержит title), дата при наличии видима краткой подписью. По действию открывается native sheet/DatePicker только даты. Для новой даты draft по умолчанию сегодняшний local civil день; открытие и «Отмена» ничего не пишут. Явное «Сохранить», «Отмена», возможность «Убрать дату» для назначенной. Успех закрывает sheet и обновляет строку; отказ показывает ошибку и оставляет draft/editor для retry. После повторного открытия берётся актуальная сохранённая дата. System theme/Dynamic Type, русские labels, без больших redesign/новых вкладок/пустых календарных заглушек. Existing add/completion/composer поведение сохранить. Удобство в направлении одобренного концепта; не копировать демонстрационные mock tasks в приложение.

## Сохранность старых stores — обязательное evidence

Добавляется nullable поле: не переименовывать @Model/entity/прежние свойства, не стирать/пересоздавать store, не делать пустой fallback. До правок подготовить baseline на собственных synthetic данных с текущим принятым приложением: создать2task, одну complete, записать их UUID/title/completion. После нового build обновить app в том же собственном Simulator БЕЗ uninstall/erase; прежние строки/UUID/completion на месте, plannedDate=nil. Потом назначить дату, terminate→relaunch и подтвердить сохранение даты, убрать→relaunch — nil сохранён.

Вместо GUI seed допустим точный legacy disk fixture из исходного baseline code в изолированном test helper, если реально доказан same entity/schema; произвольная «похожая V1-модель» не доказывает upgrade. Не коммитить SQLite stores/user data. Не создавать сложный VersionedSchema/migration framework без фактической необходимости; несовместимый upgrade → BLOCKED с evidence. Проверять только свой Simulator/tmp, не личные stores.

## Соразмерные checks

- Pure: nil/valid/invalid format, invalid day/month, leap1900/2000/2100; roundtrip picker adapter не сдвигает civil day. Несколько meaningful cases, без большого календарного suite.
- Store: assign/change/clear, invalid leaves existing value unchanged, unknown UUID, disk reopen сохраняет поле и прежние значения. Existing20tests должны остаться зелёными.
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test и swift build (macOS product compile совместимости после model change).
- Один штатный iOS Simulator build в own DerivedData CODE_SIGNING_ALLOWED=NO. Дополнительная baseline build только для необходимой upgrade regression до schema change; не повторять full gates без новой причины.
- Реальный own iPhone Simulator: upgrade старых2task, open/cancel без записи, assign/change/clear, relaunch, прежний complete/reopen/add. Скриншот editor/назначенной даты и точные evidence, без выдуманного GUI PASS. Если GUI tool ограничен, отдельно указать что доказано unit/disk и что не проверено; build не заменяет GUI. Никаких SQLite fault triggers внутри SwiftData store (известный framework trap).
- git diff --check, clean tree, scoped commit. Web/npm/DB/auth/E2E не запускать. Не менять xcode-select/Apple ID/signing teams. Очистить только own device/derivedData после сохранения evidence, screenshots сохранить вне product commit.

## Передача

Обычные новые scoped коммиты, full reports/NATIVE-003-executor.md (start/latest SHA,files,commands/exits,baseline upgrade/disk/GUI evidence,limitations). В чат только4–5коротких строк: статус,full SHA,итог/checks,путь отчёта. Остановиться до review Codex. NATIVE-004/календарь/macOS-R1 не начинать; без merge/push/amend/rebase/reset/stash/deploy, main/чужие worktrees/CRM/localhost3000/hooks не менять.

Принято после R1 на product7baab2c: независимые core31/iOS build PASS, прежний legacy upgrade подтверждён; main merge762e7ad. Ограничения GUI/device в reports/NATIVE-003.md.
