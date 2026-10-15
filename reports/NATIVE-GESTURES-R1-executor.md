# NATIVE-GESTURES-R1 — 2026-10-15

База d8c35c9 (main после NATIVE-TASK-GESTURES), отдельная ветка task/NATIVE-GESTURES-R1. Прямые правки пользователя: уменьшить точки, убрать selection по tap свободного календаря, исправить белые настройки в dark. Последнее уточнение «Не надо точно на углы…» учтено: offsets оставлены прежними (+8/-16 и -8/+16), центр на углы НЕ переносился в финале.

## Что изменено

DayTimelineView: circle18→12pt, border2→1.5pt; прежний hit32pt и offsets сохранены. Декоративный ruler теперь не принимает нажатия; под ним и блоками отдельный Rectangle с полным contentShape принимает tap пустой сетки и снимает selectedTaskID, если edit не активен. Раньше tap попадал только на текст/часовые линии, а промежутки не имели hit surface. Блоки и ручки выше фонового слоя; store callback не затронут.

OrbitInterface: выбранная тема явно задаёт color scheme и environment на presentation root настроек. Общая editor surface тоже выставляет preferredColorScheme. Поэтому смена light→dark внутри открытого sheet обновляет не только canvas, но и native Form rows, navigation title, headings, text, controls. Настройки хранятся тем же AppStorage, task DB/schema не меняются.

## Проверки

Финальные Simulator и signed generic iOS build — BUILD SUCCEEDED. git diff --check PASS. Core/93 tests не повторялись: pure helper/store не менялись, предыдущий PASS не выдаётся за новый запуск.

Свой временный iPhone17/iOS27 Simulator, CUA Device Hub. Settings: system(light)→Dark прямо внутри окна, пиксельно тёмные строки, светлый читаемый title/text; затем Dark→OLED без закрытия. Screenshot 01-dark-settings.png просмотрен. Create sheet в OLED использован для синтетической Selection fix, default today09:00/30.

Финальная сборка после отмены corner-alignment установлена на own Simulator и перезапущена. Calendar hold700ms показал маленькие точки на прежних offsets (02-small-handles.png). Tap свободного пространства между 11:00/12:00 убрал рамку и точки без переключения tab. Затем hold→body drag: 09:00–09:30→10:00–10:30; tap по тому же свободному месту снова убрал рамку и точки, сохранив task в10:00 (03-deselected-after-move.png). Все три состояния проверены по пикселям CUA; AX selection dots не экспонирует, отсутствие AX diff не подменяло визуальный результат. Личный iPhone для synthetic writes не использовался.

Evidence: /Users/atlhnv/Codex/orbit-outputs/NATIVE-GESTURES-R1/.

Device install: success, in-place update local.orbit.ios, без uninstall/erase. Device launch: success. Физический UX владельца после обновления не объявляется проверенным. Project signing не менялся. Ограничения: AXL/VoiceOver/вся матрица тем/редакторов/системное прерывание жеста не повторялись; прошлые ограничения gesture UX сохраняются. Реализация и самопроверка Codex, независимый review не заявлен.
