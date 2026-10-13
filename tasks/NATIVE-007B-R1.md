# NATIVE-007B-R1 — календарь помещается и все задачи доступны

ASSIGNED,2026-10-13. Одна layout-коррекция по reports/NATIVE-007B.md R1/R2/R3. Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007B`, branch task/NATIVE-007B. Product review SHA5d9bcb5deb1b65850430ae295bde71c57ed3bb69; starting correction SHA — coordinator HEAD из handoff. Проверить root/branch/HEAD/status, прочитать AGENTS/review/этот TASK.

Scope только CalendarDayScreen.swift, DayTimelineView.swift и R1-секция reports/NATIVE-007B-executor.md; README разрешён только для уточнения неверных claims. Не менять root docs/OrbitIOSApp/core/model/store/projection/editors/targets/tests/другие задачи.

- R1:12+untimed не вытесняют date controls/grid, все untimed доступны прокруткой/ограниченной областью. Выбрать простой bounded scroll layout (общая корректная прокрутка или bounded untimed region), без огромного controller/refactor и бизнес-пагинации. Shared model сохраняется, selectedDay не сбрасывается от layout refresh.
- R2: lane widths от реального container, не UIScreen. Все6–8overlap tasks доступны визуально и по действующим controls; dense overflow обработан явно, не clipped off-screen и не discarded. Fit или рабочая overflow navigation допустимы; ничего не сохранять в data model. Правильный half-open greedy assignment не переписывать без необходимости.
- R3: actual цветная геометрия short interval не превращается в20pt-прямоугольник. Отделить hit/selection от duration; две соседние15min и две1min tasks не накрывают/не теряют друг друга, доступны полные title/range/editor actions. Не менять plannedTime/duration ради UI. Для тесных/маленьких блоков допускается минимальный доступный способ выбора existing task action, без новой detail страницы/framework.
- В том же renderer исправить hour-08 vs hour-8 либо убрать недействующий initial scroll; добавить24:00 boundary без25-го часа. Calendar onAppear model.reload разрешён, не менять вручную selectedDay.

Checks: один iOS Simulator build CODE_SIGNING_ALLOWED=NO/own DerivedData/DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer. Targeted source/geometry proof для1/2/6/8lanes и adjacent short segments; own tmp probe допустим, постоянный новый test target/QA-framework нет. Core/schema unchanged: core67/legacy/web/DB/7200oracle не запускать.

Own temporary iPhone Simulator, real-core synthetic fixtures:
1.12untimed +timed: date controls и timeline доступны, всеuntimed достижимы, показать screenshot. Dynamic Type accessibility-large — не ломает эту компоновку.
2.2 и8overlaps: всеblock tasks доступны, не скрываются справа. Adjacent15min/1min сохраняют правильные boundaries/ID/action.
3. Дойти до00:00 и23:00–24:00, увидеть24:00; overnight positive on next day и exact-midnight exclusion не меняются.
4. По возможности реально открыть существующий interval editor тапом/accessible action из блока, Save/Cancel и context action. Зафиксировать проверенное/UNVERIFIED отдельно. Не тратить часы на повторение неработающего CUA scroll: при конкретном limitation остановить GUI эксперимент и предоставить source/geometry evidence, не выдавать его за GUI PASS. Не обходить защиту и не добавлять production debug override. Отчёт не называет выбранный день пустым только потому, что нужный блок выше текущего fold.

Обычный новый scoped commit, diff --check/clean tree. Полный reports/NATIVE-007B-executor.md В ФАЙЛ, в чат4–5коротких строк статус/full SHA/итог/checks/report. Остановиться до Codex review;3days/Month/AI/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktree/CRM/3000/hooks/xcode-select/system settings/signing не трогать. Cleanup только own tmp/device после сохранения evidence.
