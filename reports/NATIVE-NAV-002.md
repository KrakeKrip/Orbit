# NATIVE-NAV-002 — NEEDS_FIXES

2026-10-14. Product `185a19b47f9d14bb5316dbb6bea1e9751b47a25b`, assignment base `6442000f8e0097bcf3ea9cce5c4e2b6151664756`. Дерево чистое, diff --check PASS. Независимая iOS Simulator сборка с собственным DerivedData, CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED, exit0. Core/grid/store неизменны; web/core/full/legacy не повторялись. Собственный GUI этого review не запускался: проверены исходники и actual executor screenshots.

## Что соответствует заданию

Настоящая третья вкладка, один store/model; UpcomingWorkspace владеет selected day/mode независимо от Today. List группирует accepted TaskDaySelection по максимум7 возрастающим civil датам, следующий кандидат добавляется только при valid1900–2199; no extra final step. Calendar binding напрямую использует owner value, picker sync идемпотентен, fixed Today context сохранён. Русские section captions исправлены. Полночь/timezone/pan/longpress/real-device checks остаются UNVERIFIED, не заявляем их по build/source.

## R1 [P2] — contextual «Сегодня» не реализована

Прямое уточнение пользователя и supplemental prompt требуют скрывать jump при selected day == local today. UpcomingListScreen:204/212 и CalendarDayScreen:258/269 безусловно вставляют todayButton; reference current day вообще не хранится/не обновляется. Executor screenshot08 показывает кнопку на14Oct при local14Oct. Исправить в BOTH List/Calendar и всех fallback ветках; no reserved empty control row. Current local day обновлять appear/active/lightweight timer, manual selected day/mode не сбрасывать. Никаких schema/write side effects.

## R2 [P1] — календарная шапка растягивает экран за viewport

CalendarDayScreen:250–274: fallback оставляет mode fixedSize + Prev/DatePicker/Next в одном HStack, который и без today/menu слишком широк. Actual executor screenshot04-upcoming-calendar-carried-plus1.png: слева обрезан «Список», за край вышли hour labels (видно «3:00» вместо08:00, «0:00» вместо10:00); не просто невидимый action, horizontal proposal растянул весь content. Исправить responsive header: truly fitting rows/compact adaptive control arrangement, без clipping/отрицательных offset/UIScreen hardcoded ширины и без изменений ruler/grid. Normal iPhone + один AXL/small-width screenshot должны показать whole mode controls/date arrows/ellipsis и ПОЛНЫЕ hour labels.

Один correction TASK на header controls/reference-day wiring, 3UI files +report. Membership/range/core/paint/editors/navigation не переделывать, новые сценарии не добавлять. Scope/commands — tasks/NATIVE-NAV-002-R1.md. No merge/LIST001 start до повторного review.


## Повторное review R1/R2 — ACCEPTED, 2026-10-14

Product `8551416bac154d0b22197bf068fbe4a2aa82d7e6`, correction base `322b55761f6fcfb83c625e4a23d9874e784963d9`. Scope3UI files+executor section, дерево/cumulative diffcheck чист. Independent generic iOS Simulator build ownDerivedData/CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED/exit0. Core/store/grid/range unchanged, full/core/web/legacy не повторялись.

R1 закрыт: referenceDay отдельно от selectedDay, обновляетсяappear/active/30s, passedобаviews; canonicalcomparison condition во всехnormal/fallback ветках, hiddenjump неоставляетownrow. fixedToday безjump. R2 закрыт: mode/menu top row отдельно от date row, fallback меняетjump row; actual executor r1-02 screenshot просмотрен — controlswhole, normal08:00/09:00/10:00 labelswhole. Список/header/Calendar membership и selected-owner контракт сохраняются.

Actual runtime6jumpstates/storeunchanged/AXL — executor evidence, ownlatestSimulator не повторялся. Midnight/pan/longpress/realdevice/smallwidth отдельно ещёUNVERIFIED, AXLrulertruncation inherited (gridnotchanged). Не заявляем source за runtime. Русские captionP3NAV001 закрытыUIhelper, timezone-runtime assumptions deviceQAпозже.

Пользователь отдельно отметил, что modecontrol меняетposition междуList/Calendar. Это не включено в текущиеR1/R2, сохранить планом отдельного commonheader UI refinement, не расширятьтекущийTASK/следующийLIST001. NAV002 accepted вnavigation/selectedday/List7/CalendarDay scope. NextLIST001: менюдаты/временипоtap/безиконок/меньшеlistheight, потомMIN5/Projects/gestures. No push/deploy.
