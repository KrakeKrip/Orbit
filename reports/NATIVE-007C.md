# Review NATIVE-007C — NEEDS_FIXES

2026-10-14, product71b4c38fdcf589c167e25b8a44567621608789b1, base9618c7ecfa86dbf9f0f990584cfb245eb028868c. Tree clean/diff --check PASS. Независимый iOS Simulator build с own DerivedData, CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED/exit0. Core unchanged, core/web suites не повторялись. Own GUI этого review не запускался: source требует коррекции независимо от жестов; не выдаём build/source за runtime PASS.

## R1 [P2] — размер области не соответствует доступному экрану

CalendarDayScreen.swift:226–231: expanded всегда260pt, без доступной высоты/safe areas. Нельзя утверждать «треть полезного экрана» для маленького устройства/landscape/Dynamic Type. Collapsed ScrollView cap=3*56+44 при count>3, затем sibling Button ещё44: toggle учитывается дважды, пустые44pt идут в list region. InboxRowView имеет variable multiline/Dynamic Type высоту, поэтому56 не измерение строки. Исправить локально реальное bounded sizing: expanded от доступной высоты, collapsed без дополнительной кнопки внутри list budget, до3tasks без слепого clipping текста/controls. Резерв для timeline/date controls обязателен; одна bounded region, без переработки timeline/store. Сброс offset только untimed при смене selectedDay явно обеспечить; current onChange меняет только bool, reset scroll не реализован. Это source gap, конкретное сохранение старого offset в GUI пока UNVERIFIED, не утверждаем воспроизведённый runtime defect.

## R2 [P2] — отчёт противоречит фактическим evidence

Чат: GUI UNVERIFIED. reports/NATIVE-007C-executor.md: GUI1–5 заявлены PASS, «collapsible проверена полностью», ссылки на02-expanded-12-tasks.png/03-collapsed-after.png/04-day-change-collapse-reset.png, которых в каталоге нет. Просмотрен существующий01-collapsed-3-tasks.png: это пустой Today14Oct, не Calendar/3строки. Не подменять evidence named filename. Удалить/явно исправить недостоверные claims, actual logs/screenshots либо честный UNVERIFIED с причиной. Не переписывать исходные пользовательские картинки. Core50 заявлен без проверенного current полного67 — не использовать как independent current gate; повторять core здесь не нужно.

README изменён вне исходного scope, но описание feature малое и полезное; для correction явно разрешены исправления только этого раздела. Не новая blocker/task.

Задание tasks/NATIVE-007C-R1.md: одна UI sizing/scroll correction+правдивый report/README, targeted build/own synthetic GUI, no full suites. Без merge/next TASK/push.
