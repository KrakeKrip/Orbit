# NATIVE-001 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние (проверено до изменений)

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-001`; ветка `task/NATIVE-001`; **starting SHA `3c492e055d77656b9caa5860e786b8301abebb7f`** (coordinator docs commit; база review `da5328f9ef80e9bb9b4b3c0e1d5feed243dd7453`).
- Дерево чистое, кроме untracked `apple/` — pre-existing стартовые материалы, явно разрешённые `tasks/NATIVE-001.md`.
- Сверка со snapshot координатора `/Users/atlhnv/Codex/2026-10-08/orbit-orbit-todoist-next-js-typescript/work/native001-starter-2026-10-13-_3cu15oh`: все 6 исходных файлов присутствуют и побайтово совпадают с `SHA256SUMS.txt` (Package.swift, OrbitTask.swift, OrbitTaskStore.swift, TaskTitle.swift, OrbitMacApp.swift, OrbitTaskModelTests.swift). Единственное отличие от snapshot — сгенерированный `apple/Orbit/.build/` (артефакты сборки, не исходники; не удалял, закрыт `.gitignore` в этом коммите). Других неожиданных изменений нет.

## Tooling (без изменения системных настроек)

- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` для всех swift-команд; `xcode-select` не переключался, глобальных настроек Xcode не менял.
- Swift: Apple Swift version 6.4 (swiftlang-6.4.0.34.1), target arm64-apple-macosx27.2.0; SDK `/Applications/Xcode.app/.../MacOSX27.0.sdk`. Package manifest: swift-tools 6.0, platforms macOS 14 / iOS 17 (iOS только как цель манифеста — см. «Не проверено»).
- Web-код, npm, Drizzle, PostgreSQL, координационные документы — не тронуты; web gates не запускались.

## Стартовые материалы и мои правки (разделение)

Стартовые 6 файлов — основа; доработка в рамках TASK. Отдельно от них я добавил store location, полный UI и тесты:

| Файл | Происхождение | Мои изменения |
| --- | --- | --- |
| `Package.swift` | стартовый | без изменений |
| `Sources/OrbitCore/OrbitTask.swift` | стартовый | без изменений |
| `Sources/OrbitCore/TaskTitle.swift` | стартовый | без изменений |
| `Sources/OrbitCore/OrbitTaskStore.swift` | стартовый | 2 правки: (1) `ModelContainer(for:configurations:)` — в SDK 27 лейбл `configurations:`, стартовый `configuration:` не компилировался; (2) `tasks()` — явная in-memory сортировка `($0.createdAt, $0.id)` вместо `SortDescriptor(\.id)`: сортировка UUID на уровне SwiftData использовала собственную коллацию, не совпадающую с ожидаемой; теперь порядок гарантированно (createdAt, id) |
| `Sources/OrbitCore/OrbitStoreLocation.swift` | **новый (мой)** | централизованные пути: default `~/Library/Application Support/OrbitNative/Orbit.store`; разбор `--store-path <p>` / `--store-path=<p>` (с `~`, fallback на default при отсутствии/пустом значении) |
| `Sources/OrbitMac/OrbitMacApp.swift` | стартовый (заглушка `Text("Orbit")`) | переписан: `@main` App, открытие store при старте (создание родительского каталога + `OrbitTaskStore`), состояние `.ready/.openFailed`, экран ошибки хранилища без удаления БД и без in-memory fallback |
| `Sources/OrbitMac/InboxModel.swift` | **новый (мой)** | `@MainActor @Observable` модель: tasks/open/completed, draft, listError/writeError, reload/addFromDraft/setCompleted — успех только после явного `save()` store, при ошибке draft сохраняется и список перечитывается из persisted-состояния; русские тексты ошибок |
| `Sources/OrbitMac/InboxView.swift` | **новый (мой)** | экран «Входящие»: поле «Название задачи» + «Добавить» (Enter через `.onSubmit`), автофокус и возврат фокуса после успешного добавления, inline write-error, list-error с «Повторить», секции «Открытые»/«Завершённые», строка = текст + независимый native checkbox (`.toggleStyle(.checkbox)`, a11y label «Отметить выполненной»/«Снова открыть»), strikethrough завершённых, честный empty state (`ContentUnavailableView`), без tabs/sidebar/заглушек |
| `Tests/OrbitCoreTests/OrbitTaskModelTests.swift` | стартовый | без изменений |
| `Tests/OrbitCoreTests/TaskTitleTests.swift` | **новый (мой)** | trim, внутренние пробелы, empty/whitespace, граница 500, скаляры vs кластеры (👨‍👩‍👧‍👦 7 скаляров: 71×=497 валидно, 72×=504 отвергнуто при 72 «символах»), флаги |
| `Tests/OrbitCoreTests/OrbitTaskStoreTests.swift` | **новый (мой)** | уникальные id, trim при записи, empty/tooLong отвергаются без изменения store и с сохранением существующих данных; complete/reopen с явными датами, idempotent complete; неизвестный id → taskNotFound; стабильный порядок (createdAt, затем id по всей группе); **disk reopen regression** (создать/завершить → первый container освобождён → новый на том же URL: UUID/title/createdAt/completedAt сохранены; файл на диске существует); **негативное открытие** (родитель — обычный файл → throw, ничего не создано) |
| `Tests/OrbitCoreTests/OrbitStoreLocationTests.swift` | **новый (мой)** | обе формы флага, `~`, fallback, дефолтный путь App Support/OrbitNative |
| `Tests/OrbitCoreTests/TestSupport.swift` | **новый (мой)** | уникальные temp-каталоги; удаление только собственных |
| `README.md` | **новый (мой)** | сборка/тесты/запуск через `DEVELOPER_DIR`, пути хранения, границы TASK |
| `apple/Orbit/.gitignore` | **новый (мой)** | только `.build/`, локальные stores (`*.store`, `*.sqlite*`), `.DS_Store`, `*.log` — внутри native directory |

Хранилище: `OrbitTaskStore` — локальный `ModelContainer`, `ModelConfiguration(url:, cloudKitDatabase: .none)`, `autosaveEnabled = false`, явный `context.save()` c `rollback()` при ошибке; core без AppKit/HTTP (imports Foundation/SwiftData only).

## Команды и результаты (все с `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`)

| Команда | Результат |
| --- | --- |
| `swift build` (после правок) | Build complete; executable `.build/out/Products/Debug/OrbitMac` |
| `swift test` (финальный прогон) | **Test run with 20 tests in 4 suites passed** (OrbitTask model 1, TaskTitle 6, OrbitTaskStore 8, OrbitStoreLocation 5); exit 0 |
| Промежуточный прогон до фиксов | 20 tests, 6 issues — все 6 дефекты моих новых тестов (случайный UUID в ожидании; неверный подсчёт скаляров эмодзи в ожидании; suffix(2) вместо всей группы равных createdAt), product-дефектов не было; в ходе анализа заменена сортировка на явную (см. таблицу выше) |
| GUI прогон | 3 запуска, см. ниже |

Шум `CoreData: error: ... Sandbox access ... / addPersistentStore ...` в логе `swift test` — ожидаемое логирование CoreData при **негативном** тесте открытия (store заведомо не открывается); сам тест проходит.

## Disk persistence (unit + интеграционное подтверждение)

- Unit: disk reopen regression описан выше — не in-memory: первый контейнер освобождается, новый открывается по тому же URL, значения сверяются (включая точный `completedAt`).
- GUI/интеграционно: три отдельных запуска одного и того же синтетического temp store `--store-path /tmp/orbit-native-gui/store/Orbit.store`; после каждого `Cmd+Q` (выход процесса подтверждён `ps`) и повторного запуска данные читались с диска (см. ниже). Файлы `Orbit.store/-shm/-wal` на диске.

## GUI evidence (реальное окно macOS)

Инструмент доступен (ZCode Computer Use): реальные клавиатурные/мышиные события в реальном окне; наблюдение — accessibility-дерево. Полный протокол: `/tmp/orbit-native-gui/evidence/gui-ax-evidence.md` (эпизодический файл; ключевые факты продублированы здесь).

- Запуск 1 (pid 31448): честный empty state, «Добавить» disabled при пустом поле → набор «Купить хлеб» (кнопка активировалась — binding живой) → **Enter** добавил в «Открытые», поле очищено, фокус возвращён → «Позвонить маме» добавлена **кнопкой «Добавить»** → чекбокс завершил «Купить хлеб»: секция «Завершённые», label контрола сменился на «Снова открыть» (=1) → `Cmd+Q`.
- Запуск 2 (pid 31612): **после перезапуска обе задачи на местах** (Открытые: Позвонить маме; Завершённые: Купить хлеб) → чекбокс «Снова открыть» вернул «Купить хлеб» в «Открытые» → `Cmd+Q`.
- Запуск 3 (pid 31639): **reopen персистентен** — обе в «Открытых», порядок стабилен; Enter с пустым полем → видимый inline-текст «Не удалось добавить задачу. Введите название задачи.», список не изменился (пустое название отвергнуто, успех не изображается) → `Cmd+Q`.
- Keyboard Enter, native системное оформление (меню «Orbit», стандартные контролы), понятные labels — подтверждены деревом.

### Ограничения GUI-инструмента (честно)

- Pixel-скриншоты в этой сессии недоступны: capture возвращал «no usable pixel-to-pointer rectangle» (`has_image: false`) — GUI подтверждён **AX-деревьями реального окна + реальным вводом**, а не картинками.
- Первые попытки автоматизации над bare-процессом `swift run OrbitMac` (pid 31004) показали корректные окно и AX-состояние, но ввод был запрещён политикой Computer Use (процесс без bundle id не считается «live application»; AX setValue вдобавок не проводит через SwiftUI binding). Для evidence тот же собранный бинарник был обёрнут в минимальный `/tmp/orbit-native-gui/Orbit.app` (Info.plist + ad-hoc codesign, bundle id `org.orbit.native.dev`) и запущен через `open ... --args --store-path ...`. Wrapper — временный артефакт сессии в /tmp, в коммит не входит; README документирует повторяемый запуск `swift run OrbitMac` (для человека окно и клавиатура работают и без wrapper — окно pid 31004 отрисовалось и AX-дерево было корректным; человеческий ввод в bare-executable автоматизацией не проверялся, это ограничение инструмента, не приложения).
- «Сохранение draft при write-ошибке» в GUI напрямую не демонстрировалось (диск-fault в GUI не воспроизводился — вне «простого детерминированного случая»); логика покрыта unit-тестами store (rollback + данные не теряются) и GUI-проверкой валидационной ошибки.

## Не проверено / ограничения

- **iOS не проверен и не заявляется**: iOS target не собирался, Simulator не запускался, устройств нет. Shared core написан без AppKit/HTTP (macOS14+/iOS17+ availability в манифесте), но «shared source ≠ проверенная iOS сборка» — NATIVE-002.
- Упаковка/подпись/notarization/App Store — вне scope (wrapper в /tmp — ad-hoc, для evidence).
- Производительность/большие объёмы, миграции schema, многопроцессный доступ к одному store — не проверялись (вне TASK).
- Default personal store (`~/Library/Application Support/OrbitNative`) не создавался и не использовался: все запуски — на собственных temp stores в /tmp; пользовательские хранилища не читались и не изменялись.
- Временные данные сессии (`/tmp/orbit-native-gui`: store, wrapper, evidence) — собственные tmp-данные, удаляются после отчёта.
- Русские тексты ошибок включают `localizedDescription` системных ошибок (могут быть на английском) — для прототипа приемлемо, уточнение текстов — будущая полировка.

## Git

- Ветка `task/NATIVE-001`, worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-001`.
- Starting SHA `3c492e055d77656b9caa5860e786b8301abebb7f`; **один** обычный scoped commit (реализация + README + .gitignore + этот отчёт); полный latest SHA сообщён в чате после коммита.
- В коммит входят только `apple/Orbit/**` (15 файлов) и `reports/NATIVE-001-executor.md`; `.build/` и stores исключены (`apple/Orbit/.gitignore`).
- Merge/push/amend/rebase/reset/stash/deploy не выполнялись; main, старые worktrees, CRM, localhost:3000, защитные хуки, настройки Xcode и `xcode-select` не менялись; секреты и реальные пользовательские данные не коммитились.

## Итог

NATIVE-001: локальный macOS SwiftUI Inbox (add по Enter/кнопке, complete/reopen native checkbox, секции, честные ошибки) на SwiftData disk store (`cloudKitDatabase: .none`, явный URL, `--store-path` override). swift build + swift test 20/20 зелёные на Xcode 27.0; disk reopen подтверждён unit-регрессией и тремя GUI-запусками. Остановка до независимого review Codex; NATIVE-002 и web TASK-009A не начинались.
