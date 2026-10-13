# NATIVE-001 — независимый review Codex

Дата: 2026-10-13. Вердикт: NEEDS_FIXES (одна небольшая коррекция R1).
Executor HEAD: c3172a86710a2ef9ecb0c3949b3addcf02b4d486.
Assignment: 3c492e055d77656b9caa5860e786b8301abebb7f; историческая review base da5328f9ef80e9bb9b4b3c0e1d5feed243dd7453.

## Проверено независимо

- Git root/branch/HEAD совпадают, working tree чист до review; implementation scope — 15 native файлов и отчёт, web не изменён; diff --check PASS.
- Прочитаны все Sources/Tests, manifest, README и отчёт. SwiftData локальный, cloudKitDatabase:.none; autosave отключён, save явно, catch вызывает rollback; сортировка createdAt/id; input очищается после успешного save.
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test: exit 0, 20/20. Негативный opening case логирует ожидаемую ошибку CoreData. Первый sandbox запуск не получил доступ к compiler cache; обычный повтор с разрешённым локальным доступом PASS.
- swift build: exit 0.
- Независимое настоящее macOS окно через временный wrapper того же собранного бинарника, собственный explicit temp store. AX и реальный ввод: Enter добавляет; checkbox переносит в завершённые; после Cmd+Q/relaunch завершение сохранено; reopen; русскоязычное название через paste + кнопку; после следующего перезапуска обе задачи открыты, название сохранено. Поле после успешного добавления пустое. Начальный typeText дал «Codex.» вместо запрошенной строки — ограничение ввода инструмента; paste отдельно подтвердил русскоязычную строку «Проверка Codex».
- Default personal store не открывался. Синтетические store/wrapper/probe созданы в /private/tmp/orbit-native-review-qd47rpzo; приложение закрыто, собственные артефакты удаляются после сохранения отчёта.

## R1 [P2] — ошибочный explicit override выбирает личную базу

OrbitStoreLocation.swift: resolveStoreURL возвращает defaultStoreURL при присутствующем --store-path без значения, пустом/пробельном значении. При '--store-path --other-flag' принимает флаг как имя файла. Контракт override нужен для изоляции запусков: ошибка команды не должна молча создавать/открывать personal store или неожиданное хранилище.

Детерминированный отдельный probe, собранный из неизменённого OrbitStoreLocation.swift: для [OrbitMac,--store-path], [OrbitMac,--store-path=], [OrbitMac,--store-path,пробелы] сравнение resolved == default даёт true/true/true. Probe НЕ открывает базу.

Исправить только разбор аргументов/launch error path, тесты, README и executor report: default только при отсутствии флага; явно невалидный override → понятная ошибка до создания каталога/ModelContainer. Следующий option token вместо значения также reject. Валидные формы и ~ сохранить. Scope и проверки — tasks/NATIVE-001-R1.md.

## Ограничения и уточнение evidence

- 20 unit НЕ выполняют failure ветку context.save: validation rejection происходит до save, opening failure — до mutation. Фраза executor report «unit-тесты store (rollback + данные не теряются)» преувеличивает фактическое покрытие. Уточнить отчёт, дополнительный большой fault suite не требуется для R1.
- Попытка reviewer injection: собственный SQLite BEFORE INSERT trigger с RAISE(ABORT) при открытом SwiftData store. Enter вызывает SIGTRAP в CoreData -[NSManagedObjectContext _thereIsNoSadnessLikeTheDeathOfOptimism], через context.save (OrbitTaskStore.swift:32). Два crash reports OrbitBinary 11:35:00/11:35:16; существующие две строки сохранились. CUA observation после аварии вновь открывала приложение: пустой draft был следствием process crash, не обработанного успешного save. Изменение внутренней SQLite schema — искусственный неподдерживаемый сценарий; не выдаём его за доказанный дефект штатных write ошибок. Не требуем обхода framework trap. Триггер удалён; последующее открытие подтвердило существующие строки. Обычный save failure/draft rollback остаётся непроверенным runtime.
- Pixel/appearance visual QA не выполнялся, AX не доказывает пиксельный вид. iOS/Simulator/device, packaging/signing, schema migrations вне проверки.

Merge/push не выполнены. NATIVE-002 ждёт принятия NATIVE-001. Коррекция — один небольшой результат, без web gates и повторного расширения scope.
