# NATIVE-TASK-GESTURES — 2026-10-15

База 6e74c39 (main после NATIVE-CALENDAR-PREVIEW), ветка task/NATIVE-TASK-GESTURES, отдельный worktree. Прямое поручение пользователя по IMG_1254/1255/1256: карточка над меню в списках, календарное удержание для переноса и двух точек границ. Реализация Codex, самопроверка, независимый review не заявлен.

## Реализация

- TaskActionPopover вынесен из DayTimelineView, переиспользуется InboxRowView (Inbox/Today/Upcoming List) и CompactCalendarTaskRow. Tap/hold в списке открывает preview + прежние actions. Исходный label не скрывается нативным Menu. Pending action выполняется после dismiss, отмена не пишет. Круг complete независим.
- В timed Calendar native contextMenu удалён. Tap — прежний popover. Hold 0.4с — выбор/белая обводка/точки; sequenced hold→drag двигает тело. После выбора можно двигать тело повторным drag. Верхняя правая точка — start (end fixed), нижняя левая — end (start fixed). Tap пустой сетки снимает выбор.
- Draft из замороженных date/time/duration/UUID; каждый update считается от исходного translation, не накапливается. Изменяется локальная копия render segments, не SwiftData объект. На release ровно один вызов прежнего model.setPlannedInterval (если есть изменение). Перед ним snapshot сверяется с live task. Отказ показывает inline error и возвращает persisted projection. Отмена распознавателя сбрасывает draft без write.
- Pure TaskTimelineAdjustment — gesture-only правила: move clock snap5, duration preserved; start/end resize duration snap10, minimum5/max1440, opposite endpoint fixed. Начало остаётся на исходной civil date; overnight end разрешён через прежний TaskTimeInterval.end. UI не разрешает увести весь сегмент за текущий видимый день. На continuation скрыта ручка несуществующей границы. Manual minute wheels/core write/read contracts/схема не изменены, legacy1–4 не нормализуются (move отвергается, можно сначала resize).
- Greedy lanes пересчитываются по preview segments, selected geometry без lag-анимации, остальная перестановка с прежним snappy. Скролл отключён только пока идёт edit, до hold обычный scroll не блокируется направленным распознаванием.

## Проверки

- swift test --filter TaskTimelineAdjustment: 4/4 PASS (move/resize/snap/fixed edge/min-max/overflow/invalid/legacy).
- Полный swift test: 93/93 PASS, 9 suites. iOS Simulator build и signed generic iOS build существующим CLI Team override — BUILD SUCCEEDED. Project signing не менялся. git diff --check PASS. В промежуточных сборках исправлены 2 несовпадения локального render типа с core DTO; финальная сборка чистая, кроме обычного SDK AppIntents metadata notice.
- CUA Device Hub, свой iPhone17 Simulator iOS27, одна синтетическая task Gesture task, созданная через UI (title AX setValue), 09:00/30.
- Today List tap → цветная карточка title/09:00–09:30 над действиями, исходная строка видна. Screenshot 01-list-preview.png просмотрен.
- Calendar hold700ms → точки без menu, ничего не записано самим hold. Затем body drag примерно+1ч → 10:00–10:30; lower-left drag → 10:00–11:10; upper-right drag → 09:40–11:10 (end fixed); lower-left вверх → 09:40–09:45, minimum5. Каждый исход подтверждён AX + пикселями. Screenshot 02-selected-resized.png (до min5).
- Terminate/relaunch без erase: в List popover показывает 09:40–09:45. SQLite read-only после relaunch: одна строка, UUID E55E3B9970FC4CF7AE9653DCD74290FA, title Gesture task, plannedTime09:40, duration5. Реальные данные телефона не читались/не тестировались.

Evidence: /Users/atlhnv/Codex/orbit-outputs/NATIVE-TASK-GESTURES/.

## Честные границы

На Simulator проверена последовательность hold→release→drag выбранного тела и обе ручки. Единый continuous hold→drag без отпускания реализован sequence, отдельным непрерывным CUA жестом не доказан. Сложные overlaps/AXL/VoiceOver/overnight gestures/ошибки диска/отмена системным прерыванием/реальный палец в этом проходе не проверены. Edge auto-scroll при drag и перенос через даты не реализованы; видимый день можно заранее прокрутить, правится время исходной даты. Это первый вариант gesture UX, не полная копия TickTick. Личные task-операции и schema/migration/signing не менялись. Новые задачи из untimed drag / quick-create drag / 3days / Month вне этого запроса.

Результат установки на iPhone записывается ниже. Без uninstall/erase, push/deploy.

Device update: install success, launch success. Обновление поверх существующего local.orbit.ios; физические жесты владельца не заявляются проверенными.
