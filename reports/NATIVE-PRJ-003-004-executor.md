# NATIVE-PRJ-003/004 — принадлежность задач, папки и Settings

2026-10-16. База main47ab797, ветка task/NATIVE-PRJ-003. Codex implementation/self-check; scope расширен прямым пользовательским запросом проектов-папок с List/Calendar и Settings. **IMPLEMENTED / SELF-CHECK. Core101/101, old-schema upgrade, финальная iOS-сборка и живые GUI-сценарии PASS.**

## Core

Optional OrbitTask.projectID (default nil, internal setter), store setProject с task lookup/project validation до мутации, identical no-op, один save/rollback. addTask trailing projectID nil-compatible, full validation до insert, один save; без add-then-assign. Project UUID вместо имени, duplicates допустимы. Task identity/completion/date/time/duration/order не меняются. Delete проекта/cascade не добавлялись.

Три новых теста: assign/move/clear/no-op/reopen с сохранностью task fields/соседней задачи; unknown task/project, invalid atomic-create без лишней строки, retry, old init/nil; genuine previous-source upgrade.

Полный первый прогон101/101 (11 suites) PASS. Upgrade усилен oracle от старого бинарника: project/task UUID + createdAt/completedAt сравниваются с прежними, projectID после миграции nil. После усиления3/3 targeted и полный финальный101/101 PASS. Среда macOS/Xcode27. Старые sources извлечены git show47ab797 в отдельный temp package, процесс старого бинарника завершён до upgrade; test работает на копии store/sidecars. Старые project/name/UUID/timestamps и timed completed task сохраняются. Downgrade не поддерживается, личные базы не использованы. Runtime save failure не fault-inject, rollback только source-present.

## UI code-present

- Projects index tap открывает папку; rename сохранён в native context menu.
- ProjectWorkspaceScreen: все задачи проекта в List (Open/Completed, даты/интервалы), Calendar выбранного дня через существующий CalendarDayScreen с project filter. Те же объекты/UUID/редакторы/жесты. Независимые mode/day; back к индексу, timer/lifecycle current-day reference.
- Создание в папке через общий нижний FAB (последнее уточнение пользователя): preset project, nil-date в List, выбранная дата в Calendar. Общая create form получила project Picker, целый candidate передаётся store.
- Task popover: Проект… после dismiss открывает selector на стабильном source button; Save/Cancel, change/clear, existing UUID. Tiny calendar menu тоже получил action с host на CalendarDayScreen. Today/Upcoming/Inbox membership не менялся.
- Settings icon gearshape вместо сжатой line.3.horizontal. Inbox и Projects index переведены на NativeModeHeader, как Today/Upcoming/calendar/folder; все используют горизонтальный16pt/вертикальный6pt inset. Новые дублирующие тулбары не добавлялись.
- Generic iOS Simulator build BUILD SUCCEEDED, собственный DD, unsigned. После сборки менялся только test oracle/документы; product source соответствует собранному. git diff --check PASS.

## Живой GUI — завершён после восстановления CUA

Первоначальный сбой noWindowsAvailable/offscreen блокировал переходы. После пользовательского «щас попробуй» и компактного Device Hub управление восстановилось. Использовался только CUA; обходов CGEvent/AppleScript и QA product routes нет.

Свой iPhone17/iOS27 Simulator orbit-project-folders-codex (5EB859CB-9696-499D-A23C-7A0DFB44A4E5), только синтетические данные. Через UI созданы проекты «Работа»/«Личное» и 3 задачи: рабочая timed, личная undated, личная timed с тем же временем09:00. Проектный Calendar исключает чужой timed interval; Today/Upcoming показывают обе dated задачи. Inbox прежний глобальный список, не только «без проекта».

Проверено: проектные create preset (List nil-date, Calendar selectedDay), общий create picker, меню Проект… → Cancel без изменения, move→другая папка, clear→Без проекта, возврат через Inbox. UUID/название/даты/время/длительность/completion/createdAt сохранены; только projectID и revision меняются. Tab/mode roundtrip, выбор дня, relaunch после in-place установки собственной Simulator-сборки PASS.

Dark/AXL smoke папки List/Calendar выполнен. Settings gear находится в одинаковых bounds [1063,242,1119,298]px на 8 normal-font экранах (Today/Upcoming List/Calendar, Inbox, Projects index, folder List/Calendar), header-measurements.json. На AXL в сетке остаётся прежнее сокращение ruler/title внутри точных границ блока; не заявляется отсутствие любого клипа сетки.

## Последние уточнения: нижний плюс и постукивания

Один OrbitFloatingActionModifier даёт всем разделам одинаковое safe-area положение. В индексе проектный FAB создаёт проект, внутри папки — задачу; верхние plus удалены. Финальные 05/06/07 screenshots показывают индекс/List/Calendar с нижним FAB. Все три кнопки реально открыли правильные формы; Cancel через штатное AX action. В List preset Работа/Без даты, в Calendar Работа/16окт. Финальные read-only snapshots: ровно 3 task/2 project; полностью идентичны snapshots до последних relaunch/FAB-проверок.

Календарные UISelectionFeedbackGenerator ticks добавлены при изменении effective snapped time/duration; повторный кадр на том же шаге не вызывает tick, возврат к исходному значению вызывает. Выключатель haptics учитывается. Математика move5/resize10/min5 и core не менялись. Финальная FAB+haptics iOS-сборка BUILD SUCCEEDED (ios-fab.log). Тактильные ощущения Simulator не доказывает.

## Ограничения и evidence

UNVERIFIED: физическое ощущение haptics, VoiceOver, small-width, реальная полночь, runtime save failure/fault injection, long-press rename в этом проходе. Кириллица через AX setValue, не ручной набор. Старые screenshots01–04/header-* промежуточные и могут содержать верхний плюс, финальные05–07 актуальны.

Evidence /Users/atlhnv/Codex/orbit-outputs/NATIVE-PRJ-003/. Личные stores не использовались для QA. Пользователь в конце отдельно поручил GitHub push и установку iPhone; результат доставки фиксируется отдельно после выполнения.
