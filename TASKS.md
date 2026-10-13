# Orbit — активная очередь

2026-10-13: по решению пользователя iOS первый; web очередь PAUSED.

| TASK | Статус | Результат |
| --- | --- | --- |
| NATIVE-001 | NEEDS_FIXES / PAUSED | macOS технический Inbox проверен; R1 explicit store path открыт |
| NATIVE-002 | TECHNICAL_REVIEW_PASS / WAITING_FOR_VISUAL_APPROVAL | iPhone Inbox, локальный core, Simulator и визуальное review одного экрана |
| NATIVE-003 | TODO, не назначен | следующий небольшой результат после оценки iOS экрана |

Только tasks/NATIVE-002.md разрешён сейчас. Никаких серверных работ и расширения функций. macOS дизайн позже. NATIVE-001 не объявлен принятым, промежуточный source base bd22a87 разрешён пользователем; main не содержит native implementation, merge не выполнялся.

Review2026-10-13: product0a351a2 в task/NATIVE-002 проверен независимо (iOS build, core20, собственный Simulator add/complete/relaunch); подробности reports/NATIVE-002.md в task worktree. Merge не выполнен, дизайн пользователь пока не одобрил; следующая реализация не выдана.
