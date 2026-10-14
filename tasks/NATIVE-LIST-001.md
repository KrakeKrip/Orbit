# NATIVE-LIST-001 — меню по нажатию и компактные строки списков

ASSIGNED,2026-10-14. Один UI результат для Today/Upcoming/Inbox, не redesign календаря. Source base `8547b026986aa563ef31751521f23587642cb51d` — accepted NAV002. Branch `task/NATIVE-LIST-001`, worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-LIST-001`. StartingSHA assignmentHEAD из prompt. Проверить root/branch/HEAD/status; прочитать AGENTS/PRODUCT/DESIGN и этот TASK. Старые corrections не выполнять.

## Scope

InboxScreen.swift ТОЛЬКО shared InboxRowView (composer/store/open-state не менять); TodayScreen.swift ТОЛЬКО row arguments/insets; UpcomingListScreen.swift ТОЛЬКО row arguments/insets. README соответствующаясекция и reports/NATIVE-LIST-001-executor.md. Core/model/store/editors/CompactCalendarTaskRow/CalendarDayScreen/DayTimeline/Workspace/modecontrols/nav/Projects/macOS/web/targets/root docs/tests НЕ менять. No new taskdetail page/framework/controller/persistence, никаких duration-rule changes.

## Поведение

1. У обычной строки нет постоянно видимых clock/calendar иконок. Completion control остаётся слева независимым. Остальное тело строки (title+metadata) — tappable native control с полным source title в AX. Tap открывает компактное native menu/confirmationDialog: «Дата…» → существующий onEditDate/TaskDateSheet; «Время и длительность…» → существующий onEditInterval/TaskIntervalSheet (оба поля доступны в нём). Cancel menu ничего не меняет. Переиспользовать текущие source callbacks/sheet presentation, не создавать новый объединённый save flow.
2. Circle только complete/reopen, никогда не открывает menu; body/menu tap никогда не завершает task. Separate targets без overlap/nested Button. В open/completed sections menu относится к конкретному sourceUUID/title, не соседней строке. Failed mutation/model errors остаются видимыми как раньше.
3. У undated задачи menu «Дата…» работает; time/duration до даты disabled с понятной подписью либо отсутствует до назначения даты. Не ставитьtoday молча. После назначенной даты time/duration action работает; clearDate/clearTime по existing editor rules. Не менять core минимум1 пока (MIN5 отдельный TASK).
4. Меньше высота/вертикальные отступы: simple normal row ориентир44–56pt с читаемой .body/.footnote typography, без старых широких padding-групп. Уменьшить только row vertical padding/listRowInsets, не largeheader/navigation/viewselector. В длинных/multiline/accessibility строках естественное увеличение height, без hard maxHeight/clipping/уменьшения текста до нечитабельного. Body иcircle tappable>=44pt при обычнойстроке, no adjacent hit overlap. Completionvisual прежний, не переносить calendar tinycard стиль наобычныйList.
5. Повторная identical date subtitle скрыта вToday и Upcomingdaysection (там уже headerдаты): маленький sharedrow presentation flag defaultInbox true, callersToday/Upcoming false. Inbox retains meaningfulplannedDate. Time start–end/(+1день) subtitle остаётся, еслиназначено. Inbox date metadata по-русски через existingUI RussianDateCaption либо view-localformatter, без systemlocale/Corechanges. Shared intervalLabel/dateHelpers арифметику не менять. No taskmetadata loss — только presentation.
6. Исходные UUID/order/dayrange/open-completed membership/timer/selectedday/viewmodes/empty states unchanged. Modeheader unifiedposition позже отдельныйTASK; не расширятьscope. Menu state local row/nativepresentation, no globalcache/timers/delayed magic dismiss дляmaskingfailedUI.

## Соразмерная верификация

Один iOSSimulator build ownDerivedData/DEVELOPER_DIR/CODE_SIGNING_ALLOWED=NO. Core/web/full/legacy не повторять, newtestframework не добавлять. Ownsynthetic localtoday open/completed/timed/undated/longtitle:
- actualToday/Upcomingscreenshots show noactionicons/lessrowheight/no duplicateddates/time subtitlepreserved;
- bodytap→correcttitlemenu→date editor/Cancel unchanged; menu→time/durationeditor actualsavedvalues/Cancel; хотябыone legitimate scheduling Save черезexistingeditor и readonlyDB correctUUID;
- circlecomplete/reopen отдельно, menu неоткрывается; bodytap/taskdialogsнеwrite безsave;
- Inboxundateddateaction и gatingtime, datedInboxsubtitleсохраняется; longtitle+одинAXL smoke readable/enabledcontrols.
Targetedchecks only, old full Upcomingrange/Calendarpan не повторять. Screenshot/evidence реальные, tooling failures честноUNVERIFIED, cleanupтолькосвойSimulator/stores/temp. Не загружатьличныеданные. Corestorewritefail неимитироватьновымfaultframework.

Обычные scopedcommits/diffcheck/clean tree. Подробныйreport ВФАЙЛ reports/NATIVE-LIST-001-executor.md: start/fullSHA/files/actualcommands/exits/screenshots/limits/cleanup. Чат4–5shortlines status/fullSHA/итог/checks/report. StopCodexreview. MIN5/Projects/drag/resize/3days/Month/AI/commonmodeheader не начинать. Безmerge/push/amend/rebase/reset/stash/deploy/main/чужихworktree/CRM/3000/hooks/settings/xcode-select/signing/AppleID.
