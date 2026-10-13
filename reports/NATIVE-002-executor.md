# NATIVE-002 — отчёт исполнителя (GLM)

## Статус

**BLOCKED** — требуется одно конкретное решение по product core (см. «Блокер»).
По tasks/NATIVE-002.md core-фикс не выполняется молча; всё остальное из TASK,
что не зависит от фикса, подготовлено и проверено.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-002`; ветка `task/NATIVE-002`; **starting SHA `3f5feecf1f3ed40ef6404fd9cb9f16fba811f82a`**; review/source base `bd22a87ddf35defcdcf4b31cfa970bf4fdcb05cd` (предок HEAD, проверен merge-base).
- Дерево чистое; чужих изменений нет. Core из `c3172a8` (проверен Codex в bd22a87), WIP-копий из соседних worktrees нет.
- Прочитаны AGENTS (актуальный приоритет 2026-10-13), PRODUCT, ARCHITECTURE (iOS до R1 разрешён, CLI parser в iOS не вызывается), DESIGN, tasks/NATIVE-002.md, reports/NATIVE-001.md (R1 открыт, не трогается).
- Tooling: Xcode 27.0 (27A266a) через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, iPhoneSimulator27.0.sdk, runtime iOS 27.0; `xcode-select` не менялся, signing teams/Apple ID не трогались.

## Что сделано (все файлы созданы, ничего из запрещённого scope не изменено)

Только `apple/OrbitIOS/`:

| Файл | Содержание |
| --- | --- |
| `OrbitIOS.xcodeproj/project.pbxproj` | минимальный handwritten-проект objectVersion 70: `PBXFileSystemSynchronizedRootGroup` на папку `OrbitIOS`, app target `OrbitIOS` (bundle id `local.orbit.ios`, iOS 17+, iPhone only, `GENERATE_INFOPLIST_FILE` с INFOPLIST_KEY_*), локальная package reference `../Orbit` + product dependency `OrbitCore`. Без generators/новых зависимостей |
| `OrbitIOS.xcodeproj/xcshareddata/xcschemes/OrbitIOS.xcscheme` | shared scheme `OrbitIOS` (Build/Launch/Profile/Archive) |
| `OrbitIOS/OrbitIOSApp.swift` | app entry: открытие store при старте; failure → явный экран ошибки хранилища (без удаления файла и без in-memory fallback) |
| `OrbitIOS/IOSStore.swift` | единственный явный URL `Application Support/Orbit/store.sqlite` внутри собственной песочницы; каталог создаётся перед открытием; **macOS `resolveStoreURL` не вызывается, `--store-path` не принимается** (по TASK/ARCHITECTURE) |
| `OrbitIOS/IOSInboxModel.swift` | `@MainActor @Observable`: reuse OrbitCore add/complete/reopen/tasks; успех только после явного `save()`, отказ сохраняет draft; русские тексты ошибок; read/write ошибки раздельно |
| `OrbitIOS/InboxScreen.swift` | один экран: NavigationStack large title «Входящие», секции «Открытые»/«Завершённые», круглый completion-контроль слева (контент 26pt, hit area ≥44pt, a11y label «Отметить выполненной: <задача>»/«Снова открыть: <задача>»), перенос длинных названий (`fixedSize`), компактный композер в нижнем safe area (`safeAreaInset(.bottom)` — клавиатура не перекрывает список), поле+кнопка «+», клавиатурный submit (`onSubmit`, `submitLabel(.done)`), inline write-error, list-error с «Повторить», честный empty state; один сдержанный coral/red accent (главное действие + завершённый круг), системная типографика/Dynamic Type, light/dark системные |
| `README.md` | сборка/запуск/границы + явное предупреждение о BLOCKED |
| `.gitignore` | только iOS артефакты: `xcuserdata/`, `DerivedData/`, `*.ipa`, `*.dSYM*`, `.DS_Store` |

## Проверки (TASK list) — фактическое состояние

| Проверка | Результат |
| --- | --- |
| 2. `swift test` в `apple/Orbit` (DEVELOPER_DIR) | **exit 0 — 20/20 в 4 suites** (core не менялся) |
| 1. `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-ios-build-dd CODE_SIGNING_ALLOWED=NO build` | **exit 65 — падает в OrbitCore при сборке под iOS** (см. Блокер). Схема/проект/package при этом резолвятся: `xcodebuild -list` exit 0 (target OrbitIOS, scheme OrbitIOS, package Orbit @ ../Orbit resolved), `-showdestinations` exit 0 (5 iPhone Simulator destinations iOS 27.0). Собственно приложение iOS-целью **не собрано** |
| 3. Simulator GUI сценарий | **не выполнялся** — зависит от п.1 |
| 4. GUI screenshots | **не выполнялись** — зависят от п.1 |
| 5. `git diff --check` | чисто; в коммит входят только `apple/OrbitIOS/**` и отчёт (build artifacts — в /tmp и ignored) |

## Блокер (конкретный, для решения координатора)

Сборка OrbitCore под iOS падает:

```
apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift:9:28: error: 'homeDirectoryForCurrentUser' is unavailable in iOS
```

`FileManager.homeDirectoryForCurrentUser` (macOS 10.15+) используется в
`defaultStoreURL(fileManager:)` как **fallback** после
`urls(for: .applicationSupportDirectory, ...)` — ветка практически недостижимая,
но компилируется на всех платформах и на iOS запрещена. Это делает product
`OrbitCore` несовместимым с iOS-целью, вопреки ARCHITECTURE («core пригоден для
будущего iOS17+ target»). iOS-код пакета больше нигде не ломается: файлы
`OrbitTask/OrbitTaskStore/TaskTitle` собираются под iOS успешно (ошибка только в
`OrbitStoreLocation`).

Предлагаемая минимальная правка (на выбор координатора/Codex, мной НЕ выполнялась):

1. Кросс-платформенный fallback (поведение macOS не меняет, ветка та же недостижимая):
   `?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Library/Application Support", isDirectory: true)`
   (`NSHomeDirectory()` доступен на iOS и macOS; в iOS-песочнице это контейнер приложения).
2. Либо обернуть текущий fallback в `#if os(macOS) ... #endif` без замены.
3. Либо убрать fallback вовсе (практически `urls(for:)` не возвращает пустой массив на обеих платформах) — самое маленькое изменение, но меняет контракт на бумаге.

После решения: обновить `apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift` (+ тест при необходимости), затем p.1 build → Simulator GUI/screenshots (p.3–4) → отчёт и отдельный фикс-коммит по обычному процессу.

## Побочные находки (для review, устранены в моём scope)

Handwritten-схема потребовала двух точных соответствий формату Xcode 27, иначе xcodebuild падал/отказывался:

1. `TestAction` с `shouldAutocreateTestPlan = "YES"` и без Testables **ронял `xcodebuild -list`** (exit 133, EXC_BREAKPOINT в `IDETestPlan/IDEBuildableReference.init`, crash reports `xcodebuild-2026-10-13-1152*.ips`). Убран autocreate; пустой `<Testables/>`.
2. Без `BuildableIdentifier = "primary"` в `BuildableReference` BuildAction считался пустым: `error: Scheme OrbitIOS is not currently configured for the build action` (сравнено с эталонной схемой из шаблонов Xcode). Добавлен во все BuildableReference.

Итоговая схема прошла `-list` и `-showdestinations` (exit 0). Вторая схема «OrbitIOS» в `-list` — автосгенерированная Xcode (для target); при конфликте имён xcodebuild использует shared-схему проекта (проверено уникальным временным именем, файл удалён).

## Не проверено / ограничения

- **GUI не проверялся вовсе**: Simulator install/launch/ввод/screenshots — после снятия блокера; build ≠ GUI PASS. Реальный iPhone НЕ ПРОВЕРЕН (вне TASK).
- Pixel-вид, Dynamic Type на увеличенных размерах, keyboard/safe areas — не проверены (зависят от GUI-этапа).
- Дефолтный личный store Mac и чужие simulator devices не трогались; собственный временный simulator/derivedData будут созданы и удалены на GUI-этапе.
-Screens/evidence будут сохранены вне product commit с абсолютными путями (каталог будет указан в финальной версии отчёта).

## Git

- Ветка `task/NATIVE-002`, worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-002`.
- Starting SHA `3f5feecf1f3ed40ef6404fd9cb9f16fba811f82a`; один scoped commit (apple/OrbitIOS + этот отчёт, статус BLOCKED); полный latest SHA в чате.
- Core/macOS/coordination docs/web не менялись; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/другие worktrees/CRM/localhost:3000/hooks/Xcode settings/xcode-select не тронуты.

---

# Коррекция NATIVE-002 после решения по BLOCKED — READY_FOR_REVIEW

## Статус

**READY_FOR_REVIEW** (весь TASK; iOS build + GUI/persistence/screenshots выполнены).
Starting correction SHA `e2ba1f46f6b94947d6c195402333cf469abbf895` (coordinator
authorization `reports/NATIVE-002-blocker.md`, разрешён вариант №1).

## Применённая правка core (в точности разрешённый scope)

`apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift` — только fallback:
`fileManager.homeDirectoryForCurrentUser` →
`URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)`;
первичный Application Support lookup и `appendingPathComponent` сохранены.
CLI parser/macOS R1, модель, store, схема, пакетная архитектура — не тронуты.
Попутная минимальная правка моего iOS-файла (в scope TASK, не core):
`IOSStore.open()` помечен `@MainActor` — `OrbitTaskStore` в core MainActor-isolated,
без этого iOS-target не компилировал приложение (actor isolation error).

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift test` (apple/Orbit, DEVELOPER_DIR) после правки core | exit 0 — **20/20 в 4 suites** (поведение macOS не изменилось) |
| `xcodebuild -project OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-ios-build-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — **BUILD SUCCEEDED**; Xcode 27.0 (27A266a), SDK iPhoneSimulator27.0; 0 code warnings |
| Свой временный Simulator | `simctl create "Orbit-NATIVE-002-iPhone" iPhone-17 iOS-27-0` (UDID F30659D1-E995-44C4-87EA-7B97A7EE2501), boot, `simctl install` + `launch` (окно Device Hub); после evidence: terminate, shutdown, `simctl delete` (удалён ТОЛЬКО мой device), derivedData удалён |
| GUI сценарий (реальный ввод в окне Simulator через ZCode Computer Use: клики/тапы по клавиатуре устройства; observing через accessibility) | см. ниже |

## GUI/persistence evidence (фактические действия)

1. Первый launch: честный empty state, «+» disabled на пустом поле; ввод «Купить хлеб» тапами по экранной клавиатуре (layout переключён на русскую средствами самого устройства), поле = «Купить хлеб».
2. Add по **кнопке «+»** → секция «Открытые», строка с a11y label «Отметить выполненной: Купить хлеб», поле очищено.
3. **Blank rejection**: «Готово» (keyboard submit) на пустом поле → видимая ошибка «Не удалось добавить задачу. Введите название задачи.», список не изменён.
4. Вторая задача «Позвонить маме» набрана по клавишам и отправлена **клавиатурным «Готово»** (submitLabel .done → onSubmit) → добавлена, ошибка от предыдущего отказа очищена.
5. **Complete**: тап круглого контрола «Купить хлеб» → секция «Завершённые», label сменился на «Снова открыть: Купить хлеб», title приглушён.
6. **Terminate→relaunch без reinstall** (`simctl terminate` + `launch`; в launchctl 0 процессов между) → обе задачи и состояния восстановлены с диска.
7. **Reopen**: тап «Снова открыть» → «Купить хлеб» вернулся в «Открытые» → снова terminate→relaunch → reopen сохранён (обе задачи открыты).
8. **Длинное название** «Сходить в магазин за продуктами и не забыть кофе» (48 символов, набрано по клавишам) → добавлено, **переносится на 2 строки** (не обрезается).
9. **Dynamic Type**: `simctl ui content_size accessibility-large` — весь экран масштабируется (заголовок/секции/строки/композер), композер остаётся над клавиатурой; после скриншота возвращён `large`.
10. **Safe area/keyboard**: во всех состояниях композер поднимается над клавиатурой, строки не перекрываются.

## Скриншоты (вне product commit; абсолютные пути)

Каталог `/Users/atlhnv/Codex/orbit-outputs/NATIVE-002/`:

1. `01-empty.png` — пустое состояние (заголовок «Входящие», честный empty state, «+» disabled)
2. `02-keyboard-visible.png` — поле в фокусе, экранная клавиатура
3. `03-draft-typed.png` — draft «Купить хлеб» в поле, кнопка активна
4. `04-added-via-button.png` — задача добавлена кнопкой
5. `05-blank-rejection.png` — отказ пустой отправки с видимой ошибкой
6. `06-two-open-tasks-keyboard.png` — две открытые задачи + клавиатура
7. `07-completed-section.png` — «Завершённые»: coral круг с белой галочкой, приглушённый title
8. `08-after-terminate-relaunch.png` — состояние после terminate→relaunch
9. `09-long-title.png` — длинное название переносится на 2 строки
10. `10-dynamic-type-accessibility-large.png` — увеличенный текст (Dynamic Type)

## Подтверждение на диске (вне GUI)

`simctl get_app_container <UDID> local.orbit.ios data` →
`Library/Application Support/Orbit/store.sqlite` (+ -wal/-shm) существует;
`sqlite3 -readonly`: таблица `ZORBITTASK` содержит ровно 3 строки, созданные через GUI,
с точными titles («Купить хлеб», «Позвонить маме», «Сходить в магазин за продуктами и не
забыть кофе»), `ZCOMPLETEDAT IS NULL` для всех трёх (финальное состояние после reopen).

## Ограничения / не проверено

- **Реальный iPhone НЕ ПРОВЕРЕН** (Simulator-only, по TASK); device signing/TestFlight вне scope.
- Rejection >500 скаляров в GUI не прогонялся (ввод 501 символа тапами/вставкой недоступен: `simctl pbcopy/pbpaste` в этой сессии возвращал пустоту; hardware-клавиатура не пробрасывает текст в поле) — граница 500 покрыта core unit-тестами; в GUI проверен длинный валидный title (перенос) и blank rejection.
- Write-failure ветка (save error) в GUI не воспроизводилась (без fault injection по TASK); логика rollback/draft покрыта review core и кодом модели.
- Тёмная тема/RTL/другие локали не проверялись (системная light тема в evidence; код использует системные семантические цвета).
- Тесты XCUITest не создавались (TASK не требует; один штатный прогон достаточен).
- Символ «С» в первой букве — автозаглавная iOS; протокол действий сохранён в логе сессии.

## Git

- Ветка `task/NATIVE-002`; starting correction SHA `e2ba1f46f6b94947d6c195402333cf469abbf895`; новый обычный scoped commit (core-правка по разрешению + MainActor-фикс IOSStore + README + этот отчёт), полный latest SHA в чате; предыдущие коммиты не amend'ились.
- Скриншоты/derivedData/устройство в product commit не входят (outputs каталог вне worktree; .gitignore покрывает iOS артефакты). Свой Simulator device удалён; чужие simulators/данные/настройки не тронуты; xcode-select/signing teams/Apple ID не менялись.
- Merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/другие worktrees/CRM/localhost:3000/hooks не менялись. NATIVE-003/macOS-R1 не начинались.
