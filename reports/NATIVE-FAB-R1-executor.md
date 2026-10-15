# NATIVE-FAB-R1 — 2026-10-15

База ef8bf57, task/NATIVE-FAB-R1, отдельный worktree. Scope уточнён пользователем во время работы: увеличить «+», убрать исчезновение, вернуть короткий tap календарной task, усилить haptics, убрать full-screen заливку перед Settings. Codex implementation/self-check, независимый review не заявляется.

## Изменения

- Shared FAB: label40→48pt, symbol24→27pt, native glassProminent сохранён (итоговый диаметр зависит от native style, не выдумывается как измеренный). Удалена opacity0 при presentation!=nil: кнопка остаётся частью фонового экрана во время native sheet transition, без позднего повторного появления после dismiss. Пока sheet открыт, hit-testing и AX FAB отключены; opaque/system sheet закономерно закрывает находящуюся под ним кнопку.
- Короткий тап: move gesture simultaneous вместо high priority; edit начинается только в .second(true,...) после hold threshold. Ранее .first(true) ошибочно вызывал begin на touch-down, и простой тап включал selection. List hold recognizer вообще не устанавливается на calendar source вместо disabled gesture mask. 250ms guard после завершённого hold/drag не даёт тому же release открыть popover. Обычный tap не начинает edit.
- Haptics: selection → medium/intensity0.85, hold → rigid/intensity1; пользовательский выключатель сохранён. Физическое ощущение на Simulator не проверяется.
- Editor/theme: presentation-root preferredColorScheme заменён локальным environment colorScheme, сохранён выбранный theme environment. Главное исправление вспышки — удалить принудительный presentationBackground из общей editor surface; native sheet управляет своей backing surface/transition, Form canvas остаётся локальным. Тёмные Form rows/text не откатились к белым.

## Фактические проверки

Оригинальный MP4 6.8с отсмотрен по кадрам: скрытие кнопки при создании/возврате воспроизводится по её явной opacity в исходнике. Xcode27: финальный Simulator build и signed generic iOS build существующим Team override — BUILD SUCCEEDED. git diff --check PASS. Core/schema/store не менялись, 93 unit и web suites не повторялись.

Свой iPhone17/iOS27 Simulator, CUA Device Hub, единственная synthetic task Tap check (создана через UI, title AX setValue),09:00/30. Create/open/save и FAB возврат видны на settings-create-transitions.mp4; контакт кадров98.1…99.1с просмотрен: кнопка видна по мере ухода sheet, без прежнего искусственного скрытия. Этот длинный промежуточный ролик сохраняет старый backing-layer дефект Settings, не выдаётся за финальное подтверждение Settings.

Сначала одной замены colorScheme оказалось недостаточно: промежуточная запись показала пустую заливку до контента. После удаления presentationBackground повторная settings-final.mp4 отсмотрена по transition-кадрам (~13с): underlying list/task/controls остаются видны, Settings поднимается снизу без предыдущего blank/full-screen repaint. Тёмные строки и читаемый текст подтверждены при открытой теме Dark. После этой записи правились только tap recognizers, theme implementation не менялась.

Итоговый tap regression на последней сборке: coordinate tap60ms по исходно невыделенной task → popover с preview09:00–09:30 с ПЕРВОГО нажатия. Dismiss→hold700ms → рамка/точки, без меню. Body drag→10:00–10:30. Новый tap60ms по перенесённой task → popover10:00–10:30. Оба пути подтверждены реальным AX/pixels; failed промежуточные попытки тапа привели к обнаружению ошибочной .first phase, не объявлялись PASS. Перенос после изменения приоритета gesture сохранён.

Evidence: /Users/atlhnv/Codex/orbit-outputs/NATIVE-FAB-R1/ (settings-final.mp4 — итоговый Settings transition, settings-create-transitions.mp4 — промежуточный backing background с финальным FAB поведением). Синтетические данные, личные данные телефона не считывались/не менялись тестами.

Device install success, launch success, in-place local.orbit.ios без uninstall/erase. Project signing не менялся. Ограничения: реальное ощущение вибрации/physical gesture UX, AXL/VoiceOver/вся матрица тем/экранов/все ручки/системное прерывание в этом проходе не проверялись. После проверки только уточнён комментарий в TaskActionPopover, executable code не менялся. Текущие ограничения drag/resize из прошлого отчёта сохраняются.
