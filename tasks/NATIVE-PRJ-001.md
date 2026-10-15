# NATIVE-PRJ-001 — локальная основа проектов

База: af4ef5001678cd9277c4c4fc96e96369022f359d. Пользователь 2026-10-16 разрешил продолжить по очереди; Codex реализует сам. Один результат: в том же локальном store можно перечислять, создавать и переименовывать проекты.

## Scope и контракт

- OrbitProject: стабильные UUID, name, createdAt; без assignment, связей с задачами, архива, удаления и сортировки drag.
- ProjectName: trim, 1…120 Unicode scalars, дубликаты разрешены; порядок createdAt/UUID (аналогично tasks).
- Store projects/addProject/renameProject: проверка до мутаций, один save с rollback; identical rename — no-op, unknown — отдельная projectNotFound. Та же ModelContainer, CloudKit none.
- OrbitTask не менять. Никаких UI/фиктивной вкладки, серверов, signing, личных stores/устройства. PRJ002 — настоящий экран, PRJ003 — assignment.
- Additive schema: проверить сохранность всех полей прежних задач и операции после upgrade на своей disk fixture из настоящего кода базы. Не сбрасывать данные и не открывать upgraded-store старым приложением.

## Приёмка

Целевые project tests (кириллица, Unicode-граница, отказы/retry, stable identity/order, неизвестный ID, сохранность задач), full core regression, previous-version disk upgrade + reopen, один iOS Simulator build. Отчёт с честными ограничениями; GUI этого core-этапа не заявлять. Локальная интеграция после проверок, без автоматического push или установки на iPhone.
