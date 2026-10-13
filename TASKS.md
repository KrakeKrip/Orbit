# Orbit — активная очередь

2026-10-13: iOS первым, local-first. Пользователь одобрил направление концепта: удобство задач Todoist и календаря TickTick, Today Список/Расписание; Календарь День/3 дня/Месяц, без Недели. Концепт не равен реализованному календарю.

| TASK | Статус | Один результат |
| --- | --- | --- |
| NATIVE-001 | NEEDS_FIXES / PAUSED | macOS R1 explicit store path открыт; core/macOS base импортирован как зависимость NATIVE-002, задача macOS не DONE |
| NATIVE-002 | DONE (Inbox scope) | локальный iOS Inbox, build/core20, Simulator evidence; main merge14a9778, интеграционные build/core20 PASS; реальный iPhone не проверен |
| NATIVE-003 | NEEDS_FIXES (R1) | назначить/изменить/убрать дату task в iOS Inbox, disk persistence и сохранность старых stores |
| NATIVE-004 | TODO (план, не назначен) | время и длительность задачи |
| NATIVE-005 | TODO (план, не назначен) | Сегодня: реальный список задач на дату |
| NATIVE-006 | TODO (план, не назначен) | календарный День с временной сеткой |
| NATIVE-007 | TODO (план, не назначен) | 3 дня на общей шкале времени |
| NATIVE-008 | TODO (план, не назначен) | календарный Месяц |

Сейчас выдан только tasks/NATIVE-003.md, worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-003. Следующие строки — ориентир, их scope уточняется перед выдачей; не реализовывать очередь целиком. Реальная навигация добавляется с готовыми экранами, без фиктивных календарных вкладок. Нативные проекты/rename/delete/backup — отдельные последующие маленькие задания; не забыты. Web/сервера/sync PAUSED. macOS дизайн позже, macOS-R1 не потерян.

Review NATIVE-0032026-10-13: core30/iOS build/legacy upgrade PASS, один R1 в Gregorian UI adapters. Выдан tasks/NATIVE-003-R1.md в task/NATIVE-003; остальные функции не назначены. Полный review в reports/NATIVE-003.md task worktree.
