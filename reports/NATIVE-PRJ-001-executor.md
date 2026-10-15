# NATIVE-PRJ-001 — основа локальных проектов

2026-10-16. База af4ef5001678cd9277c4c4fc96e96369022f359d, ветка task/NATIVE-PRJ-001. Реализация и self-check Codex по прямому разрешению пользователя продолжить очередь; независимый review не заявляется.

## Итог

- OrbitProject: UUID/name/createdAt, setters закрыты снаружи core, internal setName вызывается validated rename. ProjectName trim/1…120 Unicode scalars, дубликаты допустимы.
- OrbitTaskStore использует тот же URL/context и ModelContainer с двумя моделями. projects сортирует createdAt/UUID; addProject/renameProject проверяют имя до мутаций и сохраняют один раз, rollback/rethrow при save failure; identical rename не вызывает save. Missing UUID — отдельный OrbitProjectStoreError, task error switches не расширялись.
- OrbitTask и его поля/операции не менялись. Нет assignment/relationship, delete/archive, UI или фиктивной вкладки. Существующие три вкладки приложения сохранены.
- Контракт зафиксирован в tasks/NATIVE-PRJ-001.md и ADR-049; следующий UI scope подготовлен отдельно.

## Проверки

1. Targeted OrbitProjectStore: 5/5 PASS. Проверены trim/кириллица/Unicode scalar boundary 120/121 и composed graphemes, duplicate names, UUID, stable order при одинаковом createdAt, unknown ID, no-op, invalid create/rename без изменений на диске и corrected retry, rename/reopen с сохранением UUID/createdAt, task-only schema upgrade и сохранность всех task fields.
2. Настоящая предыдущая версия: через git show af4ef500 извлечены исходники OrbitCore в отдельный temp Swift package. Старый OrbitTaskStore создал dated/undated/completed/overnight задачи, старый SwiftData model — legacy 1 мин; JSON oracle снимал все семь task fields после повторного открытия. Процесс завершился до upgrade.
3. Дополнительный targeted run с ORBIT_PRJ_PREVIOUS_FIXTURE: 1/1 PASS. Тест копирует old.store и sidecars в собственную temp directory, открывает новым store, создаёт/переименовывает проект, переоткрывает и сравнивает все поля четырёх задач с JSON oracle. Старый исходный fixture не мигрировался и не менялся. Новые task create/complete/rename/delete после upgrade тоже работают, исходные четыре строки сохраняются.
4. Full core: **98/98, 10 suites PASS** (93 прежних + 5 project tests). Swift build одновременно компилирует macOS executable; GUI macOS не проверялся.
5. Generic iOS Simulator build — **BUILD SUCCEEDED**, CODE_SIGNING_ALLOWED=NO, свой DerivedData. Единственный warning — стандартное skipped AppIntents metadata extraction без зависимости AppIntents.
6. git diff --check PASS. OrbitTask.swift не менялся. Первые sandbox-команды не смогли писать compiler cache; повтор с разрешённым доступом прошёл. Это tooling failure, не product test failure.

Логи: /Users/atlhnv/Codex/orbit-outputs/NATIVE-PRJ-001/{tests,previous,upgrade,full,ios}.log. Фикстуры только синтетические, в Git не добавляются. Личные базы, чужие симуляторы, телефон, signing/Apple ID и серверы не тронуты. Web suites не запускались (web не менялся).

## Ограничения

Это core-этап: пользователь пока не видит экран проектов. GUI/реальное устройство/runtime disk failure injection не проверялись; rollback присутствует в коде, но save failure не моделировался. Downgrade upgraded-store старым бинарником не поддерживается и не тестировался. Проверено additive обновление одной конкретной предыдущей production-схемы на текущей macOS/SwiftData; не заявляется проверка всех версий iOS. Автоматическая установка на iPhone и push не выполнялись.
