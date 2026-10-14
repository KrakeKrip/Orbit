# NATIVE-NAV-002 — NEEDS_FIXES

2026-10-14. Product `185a19b47f9d14bb5316dbb6bea1e9751b47a25b`, assignment base `6442000f8e0097bcf3ea9cce5c4e2b6151664756`. Дерево чистое, diff --check PASS. Независимая iOS Simulator сборка с собственным DerivedData, CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED, exit0. Core/grid/store неизменны; web/core/full/legacy не повторялись. Собственный GUI этого review не запускался: проверены исходники и actual executor screenshots.

## Что соответствует заданию

Настоящая третья вкладка, один store/model; UpcomingWorkspace владеет selected day/mode независимо от Today. List группирует accepted TaskDaySelection по максимум7 возрастающим civil датам, следующий кандидат добавляется только при valid1900–2199; no extra final step. Calendar binding напрямую использует owner value, picker sync идемпотентен, fixed Today context сохранён. Русские section captions исправлены. Полночь/timezone/pan/longpress/real-device checks остаются UNVERIFIED, не заявляем их по build/source.

## R1 [P2] — contextual «Сегодня» не реализована

Прямое уточнение пользователя и supplemental prompt требуют скрывать jump при selected day == local today. UpcomingListScreen:204/212 и CalendarDayScreen:258/269 безусловно вставляют todayButton; reference current day вообще не хранится/не обновляется. Executor screenshot08 показывает кнопку на14Oct при local14Oct. Исправить в BOTH List/Calendar и всех fallback ветках; no reserved empty control row. Current local day обновлять appear/active/lightweight timer, manual selected day/mode не сбрасывать. Никаких schema/write side effects.

## R2 [P1] — календарная шапка растягивает экран за viewport

CalendarDayScreen:250–274: fallback оставляет mode fixedSize + Prev/DatePicker/Next в одном HStack, который и без today/menu слишком широк. Actual executor screenshot04-upcoming-calendar-carried-plus1.png: слева обрезан «Список», за край вышли hour labels (видно «3:00» вместо08:00, «0:00» вместо10:00); не просто невидимый action, horizontal proposal растянул весь content. Исправить responsive header: truly fitting rows/compact adaptive control arrangement, без clipping/отрицательных offset/UIScreen hardcoded ширины и без изменений ruler/grid. Normal iPhone + один AXL/small-width screenshot должны показать whole mode controls/date arrows/ellipsis и ПОЛНЫЕ hour labels.

Один correction TASK на header controls/reference-day wiring, 3UI files +report. Membership/range/core/paint/editors/navigation не переделывать, новые сценарии не добавлять. Scope/commands — tasks/NATIVE-NAV-002-R1.md. No merge/LIST001 start до повторного review.
