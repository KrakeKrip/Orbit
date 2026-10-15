# NATIVE-CALENDAR-PREVIEW — 2026-10-15

База 7e85906867273d059221c49a906ad9ec94e4ad05, отдельный worktree/ветка task/NATIVE-CALENDAR-PREVIEW. Прямое уточнение пользователя по IMG_1251/1252: при нажатии карточка задачи должна быть видна сверху меню, а не пропадать. Codex реализовал сам; независимый review не заявляется.

Изменён один product-файл DayTimelineView.swift. Обычный Menu заменён Button с anchored native popover, compact adaptation=popover. Внутри сначала цветная task card с названием/интервалом (title до 3 строк, полная строка остаётся AX), затем прежние общие OrbitTaskMenuActions. Исходная painted-геометрия/position/UUID не меняются; task block остаётся в сетке. Выбранное действие выполняется после исчезновения popover, отмена снаружи ничего не вызывает. Native long-press contextMenu сохранён, preview согласован с цветной card. Core/store/schema не менялись.

Проверки: Xcode27 Simulator build и signed generic iOS build существующим Team — BUILD SUCCEEDED, финальная версия после lineLimit(3) пересобрана обоими target. git diff --check PASS. Core/web suites не повторялись (UI-only).

GUI CUA на своём временном iPhone17 Simulator iOS27: создана синтетическая Calendar preview (сегодня,09:00/30); tap card показал название и 09:00–09:30 над всеми 5 actions, исходная card видна в сетке. Пиксельный screenshot просмотрен: /Users/atlhnv/Codex/orbit-outputs/NATIVE-CALENDAR-PREVIEW/01-task-above-actions.png. Время и длительность из popover → правильный sheet/title/09:00/30, Cancel → возврат. Текст введён через AX setValue. После единственной корректировки lineLimit для длинного title GUI не повторялся, обычный короткий title не затронут.

Ограничения: физический UX/long-press/AXL/500-символьный title/маленький iPhone/ночная тема в этом проходе не проверены. Это native popover с card header, не заявляется системная lift-анимация UIContextMenu. Данные личного телефона не считывались, синтетические операции только на own Simulator. Установка и запуск новой сборки фиксируются ниже.

Device update: devicectl install success (update in place без uninstall/erase), launch success. Физическое взаимодействие владельца с этим меню не заявляется.
