# NATIVE-PRJ-004 — папки проектов и общие настройки

IMPLEMENTED / SELF-CHECK, 2026-10-16. PRJ003/004 выполнены Codex (self-check): принадлежность задач, проектные List/Calendar, общий Settings и нижний «+». Core101/101, previous-source upgrade, финальная iOS-сборка и живой GUI PASS. CUA после восстановления окна снова доставляет действия; прежний блокер закрыт. Подробные сценарии и ограничения — reports/NATIVE-PRJ-003-004-executor.md. Вибрация на физическом устройстве ещё требует проверки владельца.

Пользователь дополнительно запросил нижний плюс в стандартном положении и тактильные шаги календаря. Один общий floating-action modifier используется во всех разделах: индекс создаёт проект, папка создаёт задачу с preset project/date. Это заменяет прежнее ограничение «без FAB на Projects». UI использует тот же store/UUID и CalendarDayScreen. Today/Upcoming/Inbox выборки не изменяются. Удаление проектов и синхронизация не добавлены.

GUI: две папки, List/Calendar, проектные preset, общий create picker, move/clear/Cancel, фильтр чужого timed interval, roundtrip mode/tab, relaunch, dark/AXL и совпадение положения Settings на 8 экранах. Финальные нижние FAB проверены отдельно, Cancel оставил 3 задачи/2 проекта без изменений. Физический виброотклик, VoiceOver, small-width и long-press rename отдельно UNVERIFIED.
