# NATIVE-004 — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-004`; ветка `task/NATIVE-004`; **starting SHA `0bd679a2230c240dce04a32643e41b8afb16de75`**; review/source base `61568f2328066104e6515b604904b383af96ea46` (merge-base совпадает — принятый NATIVE-003 с R1, 31 core test); дерево чистое, чужих изменений нет.
- Прочитаны AGENTS/PRODUCT/ARCHITECTURE/tasks/NATIVE-004.md; macOS-R1/web/sync PAUSED, не трогались.
- Tooling: Xcode 27.0 (27A266a) через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, SDK iPhoneSimulator27.0; `xcode-select`/signing/system settings не менялись.

## Изменённые файлы (ровно 3 product Swift файла + тесты + README + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/Orbit/Sources/OrbitCore/TaskTimeInterval.swift` (**новый**) | pure контракт: строгий ASCII `HH:mm` 00:00–23:59 (24:00 не start, шир/сепараторы/не-ASCII/пробелы отвергнуты), `durationMinutes` 1…1440 (границы до арифметики — Int.max/Int.min безопасны), полнота пары, derived end `(date,time)` с переходом через полночь (ровно полночь → 00:00 следующей даты) и nil при выходе за Gregorian 1900–2199. End считается целочисленной proleptic-Gregorian арифметикой (Hinnant daysFromCivil/civilFromDays) — **без Calendar/TimeZone/DST/локалей**; не хранится |
| `apple/Orbit/Sources/OrbitCore/OrbitTask.swift` | nullable `plannedTime: String?` и `durationMinutes: Int?` (default nil; UUID/title/createdAt/completedAt/plannedDate/sort не тронуты; init-args опциональны — прежние callers совместимы) + метод мутации пары `setPlannedInterval(plannedTime:durationMinutes:)` (паттерн setPlannedDate/complete) |
| `apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift` | новая операция `setPlannedInterval(plannedTime:durationMinutes:for:)`: валидация ВСЕГО кандидата до изменения свойств (пара → формат времени → границы длительности) → fetch по UUID (`taskNotFound`) → интервал требует существующую валидную `plannedDate` (`missingDate`; без авто-подстановки «сегодня») → derived end в диапазоне (`endOutOfRange`) → один `save()` с rollback. `setPlannedDate` дополнен минимально: `nil` очищает интервал тем же save; перенос даты сохраняет пару, если итоговый derived end валиден, иначе `endOutOfRange` и все 3 значения неизменны. Свой `TaskTimeIntervalError` (incompletePair/invalidTime/invalidDuration/missingDate/endOutOfRange) — `OrbitStoreError` не расширялся |
| `apple/Orbit/Tests/OrbitCoreTests/TaskTimeIntervalTests.swift` (**новый**) | 9 тестов: валидные/невалидные форматы времени и длительности, полнота пары, end в тот же день, через полночь, ровно полночь, месяц/високосные границы, диапазон 2199-12-31 (последний вмещающийся и выход за 2200), нижняя граница 1900-01-01, invalid-входы, календарно-независимый civil результат |
| `apple/Orbit/Tests/OrbitCoreTests/OrbitTaskStoreTests.swift` | +10 тестов: create default nil/nil; assign/change/repeat-safe/clear на датированной задаче; incomplete pair отклоняется и сохраняет старую пару; invalid time/duration (включая Int.max) отклоняются и сохраняют пару; интервал без даты → missingDate (clear на undated — безопасный no-op); clear даты стирает пару тем же save; перенос даты сохраняет пару; перенос даты с end за диапазоном отклонён атомарно; midnight-интервал принимается store; unknown UUID; disk reopen сохраняет интервал с датой |
| `apple/Orbit/README.md` | одна краткая секция «Временной интервал задачи (NATIVE-004, core only)» |
| `reports/NATIVE-004-executor.md` | этот отчёт |

Не менялись: `TaskPlannedDate`/R1-адаптеры, `TaskTitle`, store location/CLI parser, macOS/iOS UI, project/scheme, coordination docs, web.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `swift build` (apple/Orbit, DEVELOPER_DIR) | exit 0 |
| `swift test` (финальный) | exit 0 — **50 тестов / 6 suites** (существующие 31 зелёные + 19 новых) |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n4-dd CODE_SIGNING_ALLOWED=NO build` | exit 0 — BUILD SUCCEEDED (compile regression shared model; UI untouched, DerivedData удалён) |
| Legacy fixture + upgrade probe | см. ниже (временный generator/probe удалены после прогонов, не коммитились) |

## Legacy fixture и upgrade evidence (обязательное)

1. **До schema change** временный тест (baseline-код = accepted NATIVE-003 `61568f2`) создал `/tmp/orbit-native-004-legacy/store.sqlite`:
   - `EF0840AA-8DD9-465D-A7BC-CA9C52BAF438` «Подать декларацию», plannedDate=2026-10-20, open;
   - `57590E50-BED0-4E4C-8427-AEDBC949C792` «Заказать сертификат», completed.
   - `sha256(store.sqlite)=717fe822aad29f458e8017004dcfa08a82d11d05b894288c2bd7d6eaac6e19c1`; это fixture от настоящего baseline module/entity (не «похожая V1-модель»).
2. Новый core открывает **копию** fixture: обе старые строки с точными UUID/titles, completion/`plannedDate` на месте, `plannedTime`/`durationMinutes` = nil. SQLite: колонки `ZPLANNEDTIME VARCHAR` и `ZDURATIONMINUTES INTEGER` добавлены лёгкой миграцией; никаких VersionedSchema/fault triggers.
3. На обновлённой копии выполнен `setPlannedInterval(22:30, 120)` → store закрыт → новый container по тому же URL: интервал прочитан с диска (22:30/120), дата и вторая задача не тронуты; sqlite подтверждаает значения строк.
4. Backup fixture и provenance (IDs + hash) сохранены вне product tree: `/Users/atlhnv/Codex/orbit-outputs/NATIVE-004/legacy-fixture-backup/`.

## Derived end evidence (unit)

- Тот же день: 2026-10-13 10:00+90 → 11:30; через полночь: 23:30+90 → 2026-10-14 01:00; ровно полночь: 00:00+1440 → 2026-10-14 00:00; месяц: 2026-10-31 23:00+120 → 2026-11-01 01:00; високосные: 2024-02-28+1440 → 2024-02-29, 2025-02-28+1440 → 2025-03-01.
- Границы диапазона: 2199-12-31 23:59+1 → nil (2200); 2199-12-31 23:58+1 → 2199-12-31 23:59 (последний вмещающийся); 1900-01-01 00:00+30 → 1900-01-01 00:30.
- Civil-детерминизм: расчёт не принимает Calendar/TimeZone вовсе; отдельный тест подтверждает Gregorian-валидность результата при Buddhist/ Islamic календарях с фиксированными timezone (через Gregorian-pinned `TaskPlannedDate`).

## Ограничения / не проверено

- **UI не существует и не заявляется**: редактора интервала нет (NATIVE-005 отдельно); iOS — только compile regression, GUI не запускался.
- Runtime save-failure/rollback ветка не воспроизводилась (без fault framework/triggers по TASK); rollback-паттерн идентичен принятому в store, invalid-candidates отвергаются до мутации (unit-покрыто).
- Реальный iPhone, тёмная тема — неприменимо/не проверялось (нет UI). Web/npm/DB/auth/E2E не запускались.
- Own tmp (fixture, upgrade-копия, derivedData) удалён после сохранения evidence; бэкап fixture — вне product tree. Личные stores/чужие simulators не трогались.

## Git

- Ветка `task/NATIVE-004`; starting SHA `0bd679a2230c240dce04a32643e41b8afb16de75`; обычные scoped коммиты, полный latest SHA в чате.
- `git diff --check` чисто; SQLite/WAL/SHM в коммиты не входили; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/чужие worktrees/CRM/localhost:3000/hooks/xcode-select не менялись. NATIVE-005/macOS-R1 не начинались.
