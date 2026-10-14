# NATIVE-UI-MODE — независимый review

2026-10-14. NEEDS_FIXES. Проверены code 2c33ac32182a0dd70458409d2d2b1516e1defd6b и report HEAD f3b9ce957d2b640db26f7685707f6f882ff825a6 относительно assignment 51c5d64a34dfab063a7aa9f9bb2ebdd458eec2ea. Дерево чистое, cumulative diff --check PASS. Независимый generic iOS Simulator build CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED. Core/web suites не повторялись: изменена только UI-композиция.

## R1 [P2]: переключатель по-прежнему меняет положение

TodayScreen.swift:26/41/45 и UpcomingListScreen.swift:43/58/62 размещают NativeModeHeader под видимым inline navigation title. CalendarDayScreen.swift:199/277 рисует собственные HStack без этого общего компонента и без navigation title. Пустой navigation bar календаря схлопывается. Поэтому при переключении Список→Календарь control поднимается на высоту navigation bar; в Upcoming дополнительно меняется левый inset из-за вложенных paddings. Это видно непосредственно на предоставленных ui-01/ui-02 и ui-03/ui-04 одного Simulator. Требование задания — одинаковая top-позиция относительно safe area, а не только одинаковый тип Picker.

В отчёте исполнитель признаёт схлопывание bar, но относит его к следующему заданию. Это основной acceptance criterion текущего TASK, поэтому не может быть отложено. NativeModeHeader используется только двумя списками; комментарий о совместном использовании всеми четырьмя представлениями не соответствует source.

Исправить одним небольшим проходом: общий mode header реально используется всеми четырьмя видами и имеет одинаковый native host относительно safe area. Разное присутствие navigation title не должно менять позицию control. Убрать двойные insets в calendar mode row. Сохранить настоящие даты/menu/callbacks/state/сетки; не компенсировать проблему offsets, пустыми spacer-барами или фиксированной высотой navigation bar.

## Что принято в текущей правке

На четырёх executor screenshots двойной внешний контур отсутствует; toolbar wrapper списков удалён, Upcoming calendar переиспользует UpcomingModeSwitcher. Workspace/core/store/editors/grid не изменены. Однако TASK целиком не принят; merge не выполнялся.

## Границы доказательств

Source/diff/build проверены независимо. Четыре предоставленных normal screenshots просмотрены Codex; собственный runtime GUI прогон этого SHA не выполнялся. Executor AX-large/state smoke — reported evidence, не независимый GUI PASS. Реальное устройство/тёмная тема/VoiceOver не проверены.

Назначен tasks/NATIVE-UI-MODE-R1.md в той же ветке. Projects не начинаются до приёмки этой коррекции.
