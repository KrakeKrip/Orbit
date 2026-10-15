# NATIVE-UI-FEEDBACK-001 — реализация Codex

Дата: 2026-10-15. База: b589a02294b6f9c7f3c3495999e76cfa0189d96b. Ветка task/NATIVE-UI-FEEDBACK-001, отдельный worktree. Пользователь прямо поручил реализацию Codex и подтвердил scope «сначала интерфейс и баги». Это самопроверка исполнителя, не независимая приёмка.

## Сделано

- Native iOS26+ glass/glassProminent кнопки FAB и управляющих действий с fallback; компактная иконка текущего вида вместо segmented picker. Один shared header, две независимые workspace bindings сохранены. Три горизонтальные линии настроек в Inbox/Today/Upcoming.
- Настройки на устройстве: system/light/ivory/dark/OLED и выключатель haptics, AppStorage отдельно от task DB. Семантические canvas в списках/сетке/редакторах, явная поверхность sheet предотвращает просвечивание coral FAB; FAB скрыт во время создания.
- Формы create/date/time/rename согласованы через Form и общие button/surface стили. Русские даты и явный Gregorian UI calendar. Draft/save/cancel и store callbacks сохранены. Временной editor убрал дублирующий префикс preview.
- Общие task menu actions: complete/reopen/date/time/rename/delete во всех списках и календарных cards/overflow; undated time disabled. Stable rename/delete host календаря. Круг completion независим.
- Calendar menu source: modifiers до position, без прежнего offset; отдельный preview для contextMenu. Lane x теперь учитывает gutter между полосами, геометрия длительности не растягивается. Snappy при изменении segments с учётом Reduce Motion.
- Haptics при menu tap/долгом нажатии, смене tab/mode/day, плюс и settings; реальное ощущение не проверяется Simulator. Upcoming horizontal drag с threshold/direction guard переключает local civil день, границы валидируются; вертикальный scroll не перехватывается по направлению обработчика.

## Фактические проверки

- Simulator xcodebuild, Xcode27, CODE_SIGNING_ALLOWED=NO: BUILD SUCCEEDED. Signed generic iOS build существующим owner Team: BUILD SUCCEEDED. Project signing в Git не менялся. SDK AppIntents metadata extraction warning (нет AppIntents dependency) не является Swift compile warning.
- git diff --check PASS. Core/schema/web не менялись, core/web suites не повторялись. В первом проходе исправлена compile-ошибка multiline ClosedRange в dateRange; после исправления сборки PASS.
- Собственный iPhone17 Simulator iOS27 с новым пустым store. Управление CUA Device Hub сначала timeout, затем восстановилось; другие средства синтеза ввода не использованы.
- GUI: настройки открываются; Ivory и OLED выбираются и видны пиксельно. Today menu List→Calendar меняет иконку. Create из Today Calendar: синтетический title через AX setValue, default date 2026-10-15 и 09:00/30 → настоящая видимая card 09:00–09:30. FAB не просвечивает через Ivory create sheet. Software keyboard показывалась при вводе (после dismiss системной typing-подсказки).
- Tap calendar card → menu возле card, не в верхнем левом углу; time editor открыл тот же title/09:00/30; Cancel сохранил card. Hold-команда 900ms также открыла меню возле card, но зеркало может сводить её к tap; native context-preview/физический hold поэтому не объявляются доказанными.
- Upcoming List swipe left → 16…22 окт и появилась «Сегодня»; swipe right → 15…21 окт, кнопка исчезла. Общий task menu и rename editor открылись из Upcoming; изменённый draft Cancel → исходный title сохранился.
- Финальная Simulator сборка после небольшой уборки установлена поверх и перезапущена без erase/uninstall: task видна; Settings показывает OLED выбранной. Переключение mode через relaunch не обещается (сессионный state).

## Evidence

/Users/atlhnv/Codex/orbit-outputs/NATIVE-UI-FEEDBACK-001/: 02-final-today-list.png (native top controls/FAB), 03-settings-ivory.png, 04-create-ivory.png, 05-calendar-task-menu.png, 06-calendar-hold.png, 07-upcoming-oled.png. 01 — промежуточный oversized controls, не финальный дизайн. Кадры 03–07 до финальной уборки: единственные отличия финала — удалён неиспользуемый helper, исправлен empty copy и canvas шапки Upcoming; формы/menu/layout те же.

## Ограничения

Полный physical smoke, ощущение haptics, настоящий hold/context-preview, VoiceOver, AXL всей матрицы, swipe Calendar, границы 1900/2199 в GUI, плотные overlap в этом проходе не проверены. Исправление anchor подтверждено tap-menu и source; не обещает доказанный physical hold. Тёмная и светлая темы отдельно не проходились полной матрицей. Runtime disk failure не вводился. Личные задачи телефона не читались/не изменялись тестовыми операциями. Крупные функции отложены: docs/NATIVE-FEEDBACK-BACKLOG.md.

## Установка на iPhone

devicectl install: success, обновлён существующий bundle local.orbit.ios, без uninstall/erase. Signed build использовал существующий owner Team только CLI override; project signing не менялся. devicectl launch: отказ Locked — телефон заблокирован; физический запуск новой версии не подтверждён. Владельцу разблокировать iPhone и открыть Orbit. Предыдущий запуск старой сборки уже подтверждён пользователем, это не подменяет проверку новой сборки. Личные task-данные не считывались; сохранность не подтверждалась чтением личного store, использован штатный update in place без schema changes.

Изменения прошли самопроверку Codex и локально интегрируются в main; независимый review и полная приёмка физического UX не заявляются.
