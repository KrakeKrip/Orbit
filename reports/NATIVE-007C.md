# Review NATIVE-007C — NEEDS_FIXES

2026-10-14, product71b4c38fdcf589c167e25b8a44567621608789b1, base9618c7ecfa86dbf9f0f990584cfb245eb028868c. Tree clean/diff --check PASS. Независимый iOS Simulator build с own DerivedData, CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED/exit0. Core unchanged, core/web suites не повторялись. Own GUI этого review не запускался: source требует коррекции независимо от жестов; не выдаём build/source за runtime PASS.

## R1 [P2] — размер области не соответствует доступному экрану

CalendarDayScreen.swift:226–231: expanded всегда260pt, без доступной высоты/safe areas. Нельзя утверждать «треть полезного экрана» для маленького устройства/landscape/Dynamic Type. Collapsed ScrollView cap=3*56+44 при count>3, затем sibling Button ещё44: toggle учитывается дважды, пустые44pt идут в list region. InboxRowView имеет variable multiline/Dynamic Type высоту, поэтому56 не измерение строки. Исправить локально реальное bounded sizing: expanded от доступной высоты, collapsed без дополнительной кнопки внутри list budget, до3tasks без слепого clipping текста/controls. Резерв для timeline/date controls обязателен; одна bounded region, без переработки timeline/store. Сброс offset только untimed при смене selectedDay явно обеспечить; current onChange меняет только bool, reset scroll не реализован. Это source gap, конкретное сохранение старого offset в GUI пока UNVERIFIED, не утверждаем воспроизведённый runtime defect.

## R2 [P2] — отчёт противоречит фактическим evidence

Чат: GUI UNVERIFIED. reports/NATIVE-007C-executor.md: GUI1–5 заявлены PASS, «collapsible проверена полностью», ссылки на02-expanded-12-tasks.png/03-collapsed-after.png/04-day-change-collapse-reset.png, которых в каталоге нет. Просмотрен существующий01-collapsed-3-tasks.png: это пустой Today14Oct, не Calendar/3строки. Не подменять evidence named filename. Удалить/явно исправить недостоверные claims, actual logs/screenshots либо честный UNVERIFIED с причиной. Не переписывать исходные пользовательские картинки. Core50 заявлен без проверенного current полного67 — не использовать как independent current gate; повторять core здесь не нужно.

README изменён вне исходного scope, но описание feature малое и полезное; для correction явно разрешены исправления только этого раздела. Не новая blocker/task.

Задание tasks/NATIVE-007C-R1.md: одна UI sizing/scroll correction+правдивый report/README, targeted build/own synthetic GUI, no full suites. Без merge/next TASK/push.


## Cumulative review R1/R2/R3, 2026-10-14 — NEEDS_FIXES (финальный icon fix)

Product9cefc4d7979eac7f6bbb264043e069d2d9c666cd, base9618c7e. Source scope CalendarDayScreen/CompactCalendarTaskRow/DayTimeline menu relocation, README/executor docs; core/store/projector unchanged. Diff --check clean, tree clean. Latest independent generic iOS Simulator build own DerivedData — результат в evidence ios-final-build.log. Core/web/full tests здесь не запускались.

Проверено чтением: real content sizing заменяетfixed260/double toggle; локальная .id(selectedDay) только expandeduntimed; compact source row безverticalinfinity, circle внутри tintedrect, no date/icons; menu переносит реальные timedsourcecallbacks и leaves paint/lanes unchanged. Просмотрен latest executor screenshot09: компактные3rows/lefttoggle/secondarycounter/standalone menu bar absent, screenshot10 и executor claims — отдельный evidence, own latest GUI не повторялся. Старые GUI claims отозваны в report. Scroll/gridoffset/contextlongpress/реальныйiPhone остаются UNVERIFIED; build не доказательство gestures.

R4 [P2], подтверждённая source ошибка: CalendarDayScreen untimedToggleButton поворачивает SF chevron.up.chevron.down на180°. Симметричный pair визуально остаётся тем же. Прямое решение пользователя: collapsed upper↑ lower↓; expanded upper↓ lower↑. Render ДВА отдельных SF Image с conditional direction, не whole-pair rotation. Fixed source UUID/collapse/AX44/callbacks сохранить.

Дополнительная маленькая sizing гигиена в том же CalendarDayScreen: при<=3tasks gutter использует Color.clear с fixedwidth и без height; Color flexible по vertical и может брать surplusheight, что противоречит compact1–3/no пустаяarea. Runtime manifestation в данном round не воспроизводился, это source risk. Убрать verticalflexibility только этого placeholder (zero/natural fixedheight) без изменения rowhit/panel/grid. Собственная GUI1task по возможности, никаких новых большогоlayoutрефакторинга.

После этого один targeted iOS build+два fresh screenshots state icon, без full повторов, stop independent acceptance. NATIVE-MIN5 подготовлен отдельно, branch/worktree до acceptance007C не выданы. Header может использовать native two-line fallback; новую итерацию его дизайна без пользователя не открываем.
