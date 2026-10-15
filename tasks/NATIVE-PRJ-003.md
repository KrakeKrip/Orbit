# NATIVE-PRJ-003 — принадлежность задачи проекту (core)

IMPLEMENTED / SELF-CHECK. Core101/101 + previous-source oracle + UI GUI PASS; ограничения в отчёте. База 47ab797, ветка task/NATIVE-PRJ-003. Пользователь прямо расширил scope: проекты как папки со списком/календарём и единые настройки. Core+UI выполняются последовательно в одной ветке; UI описан в NATIVE-PRJ-004.md. Один результат: store назначает/меняет/снимает проект задачи, новая задача может сразу получить проект.

- Optional projectID: UUID? у OrbitTask, default nil для старых rows/init; без cascade relationships.
- setProject(_:for:) проверяет наличие task и указанного project до мутаций; nil снимает принадлежность, одинаковое значение no-op. Прежние UUID/остальные поля, один save/rollback; existing task error UI switches не ломать.
- addTask optional trailing projectID default nil; валидация всего кандидата до insert, один save. Не add-then-assign. Identity по UUID, duplicate names допустимы.
- Task ordering/Today/Upcoming membership/расписание/completion/legacy durations не менять. Удаление проекта/orphan semantics отдельно.
- Без delete/archive/sync/personal store. UI назначения и проектный список — PRJ004, разрешены уточнением пользователя и реализованы поверх core в этой же ветке.

Проверки: targeted valid/missing/nil/no-op/retry/disk reopen, сохранность остальных полей и соседних задач, atomic create invalid project без лишней строки, old init compatibility, genuine previous-source disk upgrade схемы PRJ001 с project+tasks (projectID nil, всё сохранено), full core и iOS build. Не устанавливать schema-change на личный телефон для тестов, no reset/downgrade.
