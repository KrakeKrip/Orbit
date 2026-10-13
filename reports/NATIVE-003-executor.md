# NATIVE-003 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-003`; ветка `task/NATIVE-003`; **starting/review SHA `fb338c440128d71779b84ffb425911e150d2d42d`**; дерево чистое, чужих изменений нет.
- База — принятая iOS основа NATIVE-002 (product `0a351a2`, main merge `14a9778`); macOS-R1/web/sync PAUSED, не трогались.
- Tooling: Xcode 27.0 (27A266a) через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, SDK iPhoneSimulator27.0, runtime iOS 27.0; `xcode-select`/signing teams/Apple ID не менялись.

## Изменённые файлы (ровно 6 product Swift файлов + тесты + README + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/OrbitTask.swift` | одно nullable поле `plannedDate: String?` (default nil, entity/UUID/title/createdAt/completedAt не менялись) + метод `setPlannedDate(_:)` на модели (setter `private(set)` по принятому паттерну complete/reopen) |
| `apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift` | одна операция `setPlannedDate(_:for:)` по UUID: невалидное значение отвергается **до** fetch/мутации, unknown id → `taskNotFound`, явный `save()` с `rollback()` при ошибке |
| `apple/Orbit/Sources/OrbitCore/TaskPlannedDate.swift` (**новый**) | pure контракт: строгий `YYYY-MM-DD`, Gregorian 1900–2199, длины месяцев/високосность (1900/2100 не високосные, 2000 високосный), только ASCII-цифры; UI adapter `civilDateString(from:calendar:)` / `date(fromCivilDateString:calendar:)` без UTC-instant конверсий (полдень внутри civil дня); `TaskPlannedDateError.invalid` — собственный тип ошибки (по аналогии с `TaskTitleError`), чтобы не расширять `OrbitStoreError` (его exhaustive switch в macOS `InboxModel` вне scope) |
| `apple/Orbit/Tests/OrbitCoreTests/TaskPlannedDateTests.swift` (**новый**) | valid/invalid format, невозможные день/месяц, високосные 1900/2000/2100, границы 1899/2200, roundtrip adapter не сдвигает civil день (Moscow vs New York на фиксированной полночи UTC) |
| `apple/Orbit/Tests/OrbitCoreTests/OrbitTaskStoreTests.swift` | +5 тестов: create default nil; assign/change/clear с явным save; повтор того же значения безопасен (без дубля); invalid отклоняется и сохраняет прежнее значение; unknown UUID → taskNotFound; disk reopen сохраняет plannedDate рядом со старыми полями; назначение даты не меняет порядок и не скрывает задачу |
| `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift` | `setPlannedDate(_:for:) -> String?` (nil при успехе, сообщение при отказе — редактор остаётся открытым), русские тексты ошибок |
| `apple/OrbitIOS/OrbitIOS/InboxScreen.swift` | calendar-действие в строке (≥44pt, a11y «Дата задачи: <title>»), краткая подпись даты (`DateFormatter .medium`) под title, презентация sheet через `.sheet(item:)` |
| `apple/OrbitIOS/OrbitIOS/TaskDateSheet.swift` (**новый**) | маленький редактор: native wheel `DatePicker` (draft по умолчанию — сегодняшний local civil день; при наличии — сохранённая дата), явные «Сохранить»/«Отмена» в контенте sheet, «Убрать дату» только для назначенной; открытие/отмена не пишут; отказ показывает ошибку и оставляет draft |
| `apple/OrbitIOS/README.md` | структура/контракт даты/upgrade-примечание |

Не менялись: `IOSStore.swift`, `OrbitIOSApp.swift`, project/scheme, `OrbitStoreLocation`/CLI parser (macOS R1), `TaskTitle`, macOS UI, coordination docs, web.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift build` (apple/Orbit, macOS) | exit 0 (после model change; macOS-файлы не менялись — отдельный тип ошибки избавил от правки exhaustive switch вне scope) |
| `swift test` (apple/Orbit) | exit 0 — **30 тестов / 5 suites** (существующие 20 зелёные + 10 новых) |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n3-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — **BUILD SUCCEEDED** |
| Собственный временный Simulator | `simctl create Orbit-NATIVE-003-iPhone` (iPhone 17, iOS 27.0, UDID F5EE8296-…), boot/install/launch; после evidence — shutdown, `simctl delete` (удалён только мой device), derivedData/tmp удалены |

## Upgrade старого store (обязательное evidence) — ПОДТВЕРЖДЁН

1. **До изменений** (baseline-код из accepted main): временный тест создал fixture `/tmp/orbit-native-003-legacy/store.sqlite` через текущий `OrbitCore` — 2 задачи: `08A82C93-EB7B-4B49-90FA-3B573AFEE00B` «Купить хлеб» (open), `277E23CF-D918-400C-9FEA-391584556FCC` «Позвонить маме» (completed). Это «точный legacy disk fixture из исходного baseline code» — same entity/schema по построению (копия fixture сохранена вне репо в outputs).
2. Новый build приложения установлен на чистый свой Simulator; fixture (+wal/shm) подложен в песочницу `Library/Application Support/Orbit/` до первого launch (без erase/uninstall данных).
3. Launch нового приложения по legacy-файлу: открытие успешно (лёгкая миграция optional-поля). **SQLite (readonly)**: колонка `ZPLANNEDDATE VARCHAR` добавлена; ровно 2 старые строки; `hex(ZID)` побайтово равен baseline UUID'ам; titles/completion на месте; `ZPLANNEDDATE` NULL у обеих. GUI: обе задачи в правильных секциях (open/Завершённые), без дат, **не скрыты**. Скриншот `01-upgraded-legacy-store.png`.
4. Никакого VersionedSchema/migration framework не добавлялось; fault triggers не создавались.

## GUI evidence (реальные действия в окне Device Hub, AX-наблюдения + pixel-скриншоты)

Пиксельные скриншоты — `simctl io screenshot` (device display), полный протокол действий ниже:

1. **Открыть/Отмена без записи**: calendar-действие → sheet (wheel DatePicker, draft=сегодняшний день) → «Отмена» → sqlite: обе строки `ZPLANNEDDATE IS NULL` (ничего не записано). Скриншоты `02-date-sheet-open.png` (графический вариант picker) — финальная версия sheet с wheel на `03/04`.
2. **Assign**: sheet «Купить хлеб» → «Сохранить» (draft=сегодня) → строка показывает подпись «13 Oct 2026», задача **осталась в «Открытых»** (не скрыта, порядок прежний); sqlite `ZPLANNEDDATE=2026-10-13`. `03-assigned-date-today.png`.
3. **Assign второй**: «Позвонить маме» (completed) → подпись даты видна и в «Завершённых».
4. **Отказ-ветка UI**: «Убрать дату» появляется только у назначенной (у не-назначенной отсутствует — проверено в дереве обоих состояний). `04-date-sheet-with-clear.png`.
5. **Clear**: «Убрать дату» на «Позвонить маме» → подпись исчезла; sqlite NULL.
6. **Relaunch persistence (assign)**: terminate→launch (без reinstall) → «Купить хлеб 13 Oct 2026» на месте; sqlite значение сохранено. `05-after-relaunch-date-persisted.png`.
7. **Relaunch persistence (clear)**: «Убрать дату» на «Купить хлеб» → terminate→launch → обе строки NULL в sqlite, GUI без подписей.
8. **Прежние функции**: повторный assign на «Позвонить маме» (после upgrade-циклов) —成功; complete «Купить хлеб» → «Завершённые», reopen → «Открытые»; новая задача «Молоко» добавлена с экранной клавиатуры («Готово») со своей calendar-кнопкой. Финальный sqlite: 3 строки — `Купить хлеб|nil`, `Позвонить маме|2026-10-13`, `Молоко|nil`. `06-final-three-tasks.png`.

## Ограничения / не проверено

- **Изменение даты на другую (change) в GUI не прогонялось**: содержимое UIDatePicker (graphical и wheel) не экспонируется через accessibility-зеркало Device Hub (дни/компоненты колеса — opaque group без actions), pixel-координаты недоступны (окно симулятора «capture_surfaces_changed», synthetic scroll не реализован в CUA-бэкенде). Промежуточно пробовалась graphical-версия sheet — заменена на wheel с кнопками в контенте именно для AX-достижимости «Сохранить/Отмена/Убрать дату». **Change покрыт store-тестами** (assign→change→clear, `plannedDateDiskReopen`) и disk-evidence; UI-ветка change идентична assign (тот же sheet/save path), отличается только значение wheel, которое человек меняет жестом.
- Реальный iPhone НЕ ПРОВЕРЕН (Simulator-only). Тёмная тема/RTL не проверялись (системные семантические цвета).
- Write-failure ветка (save throw) в GUI не воспроизводилась (без fault injection — по TASK); rollback-логика покрыта кодом-паттерном store и unit-уровнем.
- Записи даты при «Отмена»/повторном открытии нет (проверено sqlite); seeding GUI не использовался — легитимный fixture-путь TASK.
- Own Simulator device удалён; derivedData/tmp удалены; fixture-бэкап и скриншоты сохранены вне product tree: `/Users/atlhnv/Codex/orbit-outputs/NATIVE-003/`.

## Git

- Ветка `task/NATIVE-003`; starting SHA `fb338c440128d71779b84ffb425911e150d2d42d`; обычные scoped коммиты (core+tests; iOS UI+README; отчёт), полный latest SHA в чате.
- Merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/другие worktrees/CRM/localhost:3000/hooks/xcode-select/Xcode settings не тронуты; SQLite stores/user data не коммитились; NATIVE-004/календарь/macOS-R1 не начинались.
