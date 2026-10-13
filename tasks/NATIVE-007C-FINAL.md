# NATIVE-007C-FINAL — разные направления стрелок раскрытия

ASSIGNED,2026-10-14. Один tiny fix, branch task/NATIVE-007C, worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-007C. Product9cefc4d7979eac7f6bbb264043e069d2d9c666cd; correction start coordinatorHEAD из prompt. Проверить root/branch/HEAD/status; AGENTS/reports/NATIVE-007C.md latest review/этот TASK.

Scope ТОЛЬКО CalendarDayScreen.swift+FINAL section reports/NATIVE-007C-executor.md. No CompactCalendarTaskRow/DayTimeline/grid/header/menu/core/store/editor/otherdocs/tests changes. No new features, no reformat wholefile.

1. untimedToggleButton сейчас Image chevron.up.chevron.down rotation180 — симметричный icon не меняется. Render VStack из ДВУХ SF chevrons без whole-pair rotation: collapsed upper chevron.up +lower chevron.down; expanded upper chevron.down+lower chevron.up. Spacing/font/leftgutter/44x44hit+AX identifier/labels/collapsecallback сохраняются. Animationoptional, направление реально меняется, не relyon180 rotation.
2. В untimedSection при<=3tasks пустой gutterColor.clear не оставлять verticallyflexible: fixedzero/naturalheightplaceholder в44? gutterwidth56 прежний, реальные карточки naturalheight, no invisible area reserves. Не распространять .id/remount наtimeline. Это маленькая source гигиена в томжефайле, не redesign.

Один iOS Simulator build ownDerivedData/DEVELOPER_DIR/CODE_SIGNING_ALLOWED=NO. Source показать explicit collapsed/expandedpair. Ownsynthetic localcurrentday>3task screenshotscollapsed/expanded с видимымразнымicon; если toolingблокируетпереключение—честноUNVERIFIED, не выдумывать. При возможности 1taskday подтверждениеno giantempty area; не продлеватьрадижестов. Core/web/full/legacy не повторять, no newtests/framework. Никаких unrelateddevice/systemsettings/resources.

Обычный scoped newcommit, diff --check/cleantree. Reportactualcommands/exits/evidence/cleanup вFILE, чат4–5shortlines status/fullSHA/итог/checks/report. StopCodexreview, minimum5/drag/resize/3days/Month/AI не начинать. Без merge/push/amend/rebase/reset/stash/deploy/main/чужих worktrees/CRM/3000/hooks/xcode-select/signing/AppleID/settings.
