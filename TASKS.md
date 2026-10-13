# Orbit — активная очередь

2026-10-13: iOS первым, local-first. Пользователь одобрил направление концепта: удобство задач Todoist и календаря TickTick, Today Список/Расписание; Календарь День/3 дня/Месяц, без Недели. Концепт не равен реализованному календарю.

| TASK | Статус | Один результат |
| --- | --- | --- |
| NATIVE-001 | NEEDS_FIXES / PAUSED | macOS R1 explicit store path открыт; core/macOS base импортирован как зависимость NATIVE-002, задача macOS не DONE |
| NATIVE-002 | DONE (Inbox scope) | локальный iOS Inbox, build/core20, Simulator evidence; main merge14a9778, интеграционные build/core20 PASS; реальный iPhone не проверен |
| NATIVE-003 | DONE | назначить/изменить/убрать дату task в iOS Inbox, disk persistence и сохранность старых stores |
| NATIVE-004 | DONE | shared core интервала: core50/iOS build/legacy upgrade/7200 civil oracle PASS; UI отдельно |
| NATIVE-005 | DONE | iOS interval editor, R1 title закрыт, build/GUI evidence; локальный merge6d12ae2 |
| NATIVE-006 | TODO (план, не назначен) | Сегодня: реальный список задач на дату |
| NATIVE-007 | TODO (план, не назначен) | календарный День с временной сеткой |
| NATIVE-008 | TODO (план, не назначен) | 3 дня на общей шкале времени |
| NATIVE-009 | TODO (план, не назначен) | календарный Месяц |

NATIVE-004 принят и локально интегрирован; NATIVE-005 принят, активного assignment пока нет. NATIVE-003 закрыт. Время/длительность разбиты на core и отдельный editor, чтобы не наращивать TASK. Следующие строки — ориентир, их scope уточняется перед выдачей; не реализовывать очередь целиком. Реальная навигация добавляется с готовыми экранами, без фиктивных календарных вкладок. Нативные проекты/rename/delete/backup — отдельные последующие маленькие задания; не забыты. Web/сервера/sync PAUSED. macOS дизайн позже, macOS-R1 не потерян.

Первичное review NATIVE-0032026-10-13: core30/iOS build/legacy upgrade PASS, один R1 в Gregorian UI adapters. Выдан tasks/NATIVE-003-R1.md в task/NATIVE-003; остальные функции не назначены. Полный review в reports/NATIVE-003.md task worktree.

Итог NATIVE-0032026-10-13: R1 закрыт, product7baab2c независимо core31/iOS build PASS; legacy upgrade проверен ранее. Main merge762e7ad257e156cef5b485a58d831d6881ca1281, native source идентичен проверенной ветке. GUI смены даты/реальный iPhone остаются непроверенными. NATIVE-004 пока план, macOS-R1 PAUSED; push/deploy не выполнялись.

Назначение2026-10-13: NATIVE-004 только3product core files + targeted tests, без UI. Изначальные будущие номера005–008 были планом без assignment; уточнены005editor/006Today/007Day/008Three/009Month. Последующие файлы/ветки не выданы.

Итог2026-10-13: NATIVE-004 DONE, product40f1b20 независимо core50/iOS build/legacy upgrade/7200 civil oracle PASS; локальный mergebd4984eba8a9e23b748bf017499e7bd3b1f41952. Native sources main совпадают с протестированной веткой. UI editor/реальный iPhone/runtime save failure не проверялись; NATIVE-005 не назначен, push/deploy отсутствуют.

Назначение2026-10-13: NATIVE-005 — только iOS interval editor поверх принятого core (source base a56137473b186efe5b87d4ae9c46881f092262df). Следующий NATIVE-006/Today не назначен. По уточнению пользователя после принятия задачи сразу выдавать следующий небольшой prompt.

Review2026-10-13: NATIVE-005 aa22fdc — одна R1: название задачи отсутствует в interval sheet. Независимый iOS build и экранный ввод23:30 + отказ25:00 без мутации PASS. Назначен tasks/NATIVE-005-R1.md только в task worktree, coordinator HEAD d3edd9abbe1f25607c8122055e953e5f27ca74cd. Без merge; NATIVE-006 не выдан.

Итог2026-10-13: NATIVE-005 DONE после R1, source961cc2d; main merge6d12ae26e3c145ccd9041efde7bf6dc443447e1f. Независимые iOS build/экранный ввод времени/invalid rejection PASS; title screenshot/source проверены. Реальный iPhone не проверен. Следующий NATIVE-006 — небольшой Today list; календарь позже.
