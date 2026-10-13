# NATIVE-004 — независимый review Codex

2026-10-13. Вердикт PASS в scope shared core временного интервала. Проверенный product SHA `40f1b20f32076d62469cc0cb76f4a4d7d35859f0`; assignment `0bd679a2230c240dce04a32643e41b8afb16de75`; source base `61568f2328066104e6515b604904b383af96ea46`. Root/branch/HEAD совпадают; рабочее дерево и diff --check чистые. Семь файлов: ровно три product core файла, два тестовых, package README и executor report. UI/web/координационные документы исполнитель не менял.

## Проверка кода

Прочитаны все изменения и отчёт. ASCII HH:mm, complete pair и duration 1...1440 проверяются до арифметики и мутации. Ненулевой interval требует даты; bounds проверены до сложения, включая Int.max. Derived end использует целочисленную Gregorian civil арифметику без Calendar/TimeZone/DST и не хранится. Midnight даёт следующую дату; выход конца за 2199 отвергается. Store пишет только после проверки кандидата, одним explicit save с rollback при throw. Clear date удаляет pair в том же save, date move сохраняет валидную pair. Completion/title/UUID/order не меняются. Nullable поля сохраняют совместимость старой entity.

Блокирующих замечаний не найдено. Модель остаётся минимальной; новые UI/календарные функции не добавлялись.

## Независимые проверки

Все команды выполнялись в task worktree с `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, Xcode 27.0; xcode-select не менялся.

- `swift test` в apple/Orbit: exit 0, 50/50. Компилирует также macOS executable. CoreData diagnostics в логе принадлежат существующему отрицательному тесту открытия недоступного пути, который ожидает отказ; итог suite успешен.
- `xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath <own tmp>/DerivedData CODE_SIGNING_ALLOWED=NO build`: exit 0, BUILD SUCCEEDED. Единственный warning — skipped AppIntents metadata extraction без зависимости AppIntents.
- Отдельная executable probe собрана из неизменённых OrbitCore sources. Открыта собственная копия synthetic legacy fixture исполнителя. Перед открытием SQLite schema содержала plannedDate, но не plannedTime/durationMinutes. Исходный SHA256 SQLite `717fe822aad29f458e8017004dcfa08a82d11d05b894288c2bd7d6eaac6e19c1` совпал с отчётом. После миграции сохранены оба UUID/title/createdAt/completedAt/date, новые поля nil. Назначение 22:30/120 пережило открытие новым container; затем clear date и повторное открытие подтвердили очистку всей тройки. MIGRATION PASS. Исходный fixture и личные stores на запись не открывались. Генерация fixture принятым старым кодом — evidence исполнителя; Codex независимо проверяет физическую старую schema и upgrade её копии.
- Независимый арифметический oracle: последние дни каждого месяца 1900...2199, start 23:30, durations 90 и 1440. Сравнение helper с Foundation Gregorian calendar в фиксированной UTC зоне: 7200/7200 PASS, включая високосные годы, смену месяца/года и end-range rejection. UTC здесь только oracle civil арифметики, пользовательские значения не конвертируются.
- `git diff --check 0bd679a..HEAD`: exit 0; дерево до review чистое.

Полные логи и временные probe sources сохранены вне product tree: `/Users/atlhnv/Codex/orbit-outputs/NATIVE-004-review-evidence/`. Это review-инструменты, не новые продуктовые функции или постоянный framework.

## Практические границы

UI времени/длительности ещё отсутствует: NATIVE-005 отдельный небольшой TASK. GUI/реальный iPhone здесь не проверялись и не заявляются PASS. Runtime save-failure/rollback не воспроизводился; source содержит явный rollback, invalid-before-save тесты не доказывают эту runtime ветку. Новые fixtures/calendar checks не требуют web/server gates; web, CRM, Colima, localhost:3000 и защитные hooks не менялись. Push/deploy не выполнялись.

## Локальная интеграция

Main merge `bd4984eba8a9e23b748bf017499e7bd3b1f41952` — обычный no-ff, без конфликтов. `git diff --exit-code task/NATIVE-004 -- apple/Orbit apple/OrbitIOS`: exit 0, native sources идентичны независимо проверенной ветке. Тесты/build выполнены в task worktree до merge; одинаковые исходники повторно без причины не прогонялись. NATIVE-004 DONE. NATIVE-005 — следующий плановый editor, пока не назначен. Push/deploy не выполнялись.
