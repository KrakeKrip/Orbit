# NATIVE-007B — iOS: календарный вид «День»

ASSIGNED, 2026-10-13. Один результат: настоящий Day timeline над принятой проекцией007A. Три product UI файла; без3дней/Месяца/нового создания/drag/серверов/AI.

## Старт / scope

Review/source base `aaa01d42cd5196dff246a863270d61c2a2472766` — принят007A после R1/R2, projection11/iOS build PASS. Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007B`, branch task/NATIVE-007B. Starting SHA — assignment HEAD из handoff. Проверить root/branch/HEAD/status, прочитать AGENTS/PRODUCT/ARCHITECTURE/DESIGN/этот TASK и public API TaskDayProjection.

Ровно три product Swift-файла:
1. OrbitIOS/OrbitIOSApp.swift — добавить настоящую третью вкладку Календарь к существующим Today/Inbox; один model/store, startup по-прежнему Today. Разрешено применить единый orbitAccent к native TabView.
2. Новый OrbitIOS/CalendarDayScreen.swift — выбранный civil день, bounded date navigation, projection/read-error/write-error, reuse existing sheets/untimed rows.
3. Новый OrbitIOS/DayTimelineView.swift — только временная шкала/блоки и небольшой локальный overlap layout.

Все пути внутри apple/OrbitIOS/. Также README и reports/NATIVE-007B-executor.md. Не менять core/model/store/projection/helpers/tests/Today/Inbox/editors/Xcode project/root docs/macOS/web. Synchronized group включает новые файлы. Не создавать targets/dependencies/большой scheduler/новые entities/постоянный test framework. Если другой scope действительно необходим — BLOCKED с конкретной причиной, не переписывать соседние файлы молча.

## Экран и дата

- Только вид День. Вкладка Календарь реальная, без неработающих selectors3дня/Месяц/Неделя/Проекты. Native SwiftUI/system materials/системные темы + единый coral accent, никакой ручной Glass imitation.
- Первый выбранный день — local Gregorian today. Хранить selection как civil String, не UTC instant. Дата видима; Prev/Next ±1 день, «Сегодня», небольшой native date picker для выбора даты. Использовать принятые TaskPlannedDate adapters; для шага только Gregorian calendar/noon в нужной timezone. Bound1900...2199: кнопки disabled и handler guard до state change, picker range ограничен; invalid candidate не роняет view/не меняет selection. «Сегодня» вычисляет новый reference day при нажатии.
- Выбор сохраняется при переключении вкладок/возврате active; onAppear/active перечитывает общий model, не сбрасывая вручную выбранный день. Model/store второй не создавать. Current day/clock не писать в task; DST/offset conversions для plannedTime отсутствуют.
- Состояние model.listError видимо с Retry; model.writeError видимо рядом с контентом, не скрывается автоматически. Пустой день честный: сетка остаётся доступна, без mock blocks. Создание остаётся в Inbox, никаких tap-to-create/авто-даты.

## Сетка и задачи

- Один вертикальный Day grid со шкалой часов00:00...24:00, весь диапазон доступен прокруткой. Высота часа единая/линейная (например64–72pt); не ограничивать9–20 как в концепте. Разумный initial scroll к утру разрешён, но00:00/24:00 достижимы. Date controls/tab bar/safe areas не перекрываются.
- Данные ТОЛЬКО TaskDayProjector.project(selectedDay,in:model.tasks). Не использовать Today equality helper для календаря: continuation со вчера должен присутствовать. Result UUID связан с тем же task объекта model, не новые копии/seed. Нет новых сохранённых layout/end полей.
- Untimed UUID — отдельная область «Без времени» над шкалой, те же InboxRowView с existing callbacks/sheets. Не ставить их на00:00. Completed остаются доступны и отображаются спокойнее, не исчезают произвольно.
- Timed segment: y=startMinute/60*hourHeight, height=(end-start)/60*hourHeight, в пределах суток. Краткие title/selected-day time range; endMinute1440 отображается как24:00 только UI boundary, не stored start time. Continuation fromPrevious/intoNext видимо помечен и берётся из flags, не из догадок по duration. Exact-midnight false не рисует ложную стрелку продолжения.
- Overlaps ВСЕ видимы side-by-side, не в виде перекрывающих друг друга полных карточек. Минимальный локальный greedy lane layout в DayTimelineView: half-open intersects, соприкасающиеся end==next.start не конфликтуют; cluster laneCount=максимум одновременно активных lanes, stable assignment по принятому order. Не сохранять lanes и не создавать новый core layout API. Не объединять/пропускать задачи. Никакого resize/reorder/drag-and-drop.
- Tap timed block открывает существующий TaskIntervalSheet правильной исходной задачи (title/date/start/duration), в том числе на continuation следующего дня: editor редактирует ИСХОДНУЮ дату, без незаметного переноса на selected day. Для даты/complete/reopen достаточно маленького native context menu существующих операций через model; untimed uses row actions. Single sheet presentation на screen, reuse InboxSheetPresentation/TaskDateSheet/TaskIntervalSheet. Save отражается refetch/reprojection; Cancel не пишет. Mutation не дублировать.
- Toolbar/row/menu actions >=44pt. Для коротких интервалов компактная визуальная геометрия не должна терять task/interaction: расширенный hit area без ложной записанной duration допустим. Длинный title в grid можно сократить, но полный title и реальный range доступны через AX/editor. Dynamic Type controls/editor читаются; grid не выходит за экран/не закрывает навигацию. Не добавлять новую detail/settings страницу.

## Проверки без большого QA-проекта

Один iOS Simulator build CODE_SIGNING_ALLOWED=NO/own DerivedData/DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer. Core не меняется: full67/legacy/7200oracle/web/DB/auth не повторять. Локальный lane алгоритм проверить по source и фиксированным overlapping fixtures; own tmp небольшой probe допустим, новый test target не добавлять.

Собственный temporary iPhone Simulator, real-core synthetic fixture до launch (как007B predecessor006, без личных данных): selected today untimed;09:00/60;09:30/60 overlap; adjacent10:30/30; completed; yesterday23:30/90 continuation; today23:30/30 exact midnight. GUI проверить:
1. Три вкладки/общие UUID, Calendar date/Prev/Next/Today/picker. Untimed отдельно, блоки в правильных часах. Все24часа доступны, верх/низ не обрезаны.
2. Overlapping9/9:30 реально видны оба; adjacent10:30 не получает ложного overlap. Next day показывает правильное positive continuation; exact-midnight не даёт zero block/стрелку.
3. Tap block открывает нужный сохранённый interval/title; изменённый interval отражён после Save, Cancel без записи. Complete/reopen через доступный context menu/row, ошибка model не скрыта. Inbox/Today сохраняют прежние flows.
4. Dynamic Type/layout, два screenshot Day grid (с overlap) и overnight/empty day вне product tree `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007B/`.

Read fixture provisioning/SQLite не считать GUI assignment. Source checks для boundary1900/2199 достаточно, если AX picker недоступен: честно UNVERIFIED, не тратить часы на wheel. При tooling failure не отключать защиту/не внедрять постоянные debug overrides. Публиковать фактическую проверку отдельно от непроверенного. Не менять xcode-select/system clock/timezone/AppleID/signing/чужие simulators/Colima/CRM/3000/hooks; cleanup только own temporary device/files после evidence.

## Передача

Обычный scoped commit, diff --check/clean tree. Подробный отчёт СОХРАНИТЬ В ФАЙЛ reports/NATIVE-007B-executor.md: start/latest SHA/files/commands/exits/lane policy/GUI evidence/screenshots/limitations. Чат только4–5коротких строк: статус/full SHA/итог/checks/report. Остановиться до Codex review. 3дня/Месяц/новый quick-add/voice GPT/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy, main/другие worktree/root docs не трогать.
