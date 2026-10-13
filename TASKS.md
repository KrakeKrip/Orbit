# Orbit — активная очередь

2026-10-13: iOS первым, local-first. Пользователь одобрил направление концепта: удобство задач Todoist и календаря TickTick, Today Список/Расписание; Календарь День/3 дня/Месяц, без Недели. Концепт не равен реализованному календарю.

| TASK | Статус | Один результат |
| --- | --- | --- |
| NATIVE-001 | NEEDS_FIXES / PAUSED | macOS R1 explicit store path открыт; core/macOS base импортирован как зависимость NATIVE-002, задача macOS не DONE |
| NATIVE-002 | DONE (Inbox scope) | локальный iOS Inbox, build/core20, Simulator evidence; main merge14a9778, интеграционные build/core20 PASS; реальный iPhone не проверен |
| NATIVE-003 | DONE | назначить/изменить/убрать дату task в iOS Inbox, disk persistence и сохранность старых stores |
| NATIVE-004 | ASSIGNED | shared core: временной интервал task, сохранность stores, без UI |
| NATIVE-005 | TODO (план, не назначен) | небольшой iOS editor времени/длительности |
| NATIVE-006 | TODO (план, не назначен) | Сегодня: реальный список задач на дату |
| NATIVE-007 | TODO (план, не назначен) | календарный День с временной сеткой |
| NATIVE-008 | TODO (план, не назначен) | 3 дня на общей шкале времени |
| NATIVE-009 | TODO (план, не назначен) | календарный Месяц |

Сейчас выдан только tasks/NATIVE-004.md в task/NATIVE-004, /Users/atlhnv/Codex/orbit-worktrees/NATIVE-004. NATIVE-003 закрыт. Время/длительность разбиты на core и отдельный editor, чтобы не наращивать TASK. Следующие строки — ориентир, их scope уточняется перед выдачей; не реализовывать очередь целиком. Реальная навигация добавляется с готовыми экранами, без фиктивных календарных вкладок. Нативные проекты/rename/delete/backup — отдельные последующие маленькие задания; не забыты. Web/сервера/sync PAUSED. macOS дизайн позже, macOS-R1 не потерян.

Первичное review NATIVE-0032026-10-13: core30/iOS build/legacy upgrade PASS, один R1 в Gregorian UI adapters. Выдан tasks/NATIVE-003-R1.md в task/NATIVE-003; остальные функции не назначены. Полный review в reports/NATIVE-003.md task worktree.

Итог NATIVE-0032026-10-13: R1 закрыт, product7baab2c независимо core31/iOS build PASS; legacy upgrade проверен ранее. Main merge762e7ad257e156cef5b485a58d831d6881ca1281, native source идентичен проверенной ветке. GUI смены даты/реальный iPhone остаются непроверенными. NATIVE-004 пока план, macOS-R1 PAUSED; push/deploy не выполнялись.

Назначение2026-10-13: NATIVE-004 только3product core files + targeted tests, без UI. Изначальные будущие номера005–008 были планом без assignment; уточнены005editor/006Today/007Day/008Three/009Month. Последующие файлы/ветки не выданы.
