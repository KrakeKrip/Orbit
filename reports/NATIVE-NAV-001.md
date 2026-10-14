# NATIVE-NAV-001 — ACCEPTED с небольшой отслеживаемой UI доработкой

2026-10-14. Product58ae60a8ff71264a5c9774f17dc28a86e5218985, basec454d98b5d7346ab96377b1a1577df098c94c7b3. Scope4productUI files+README/report, tree/diffcheck clean. Independent xcodebuild generic iOS Simulator, ownDerivedData/CODE_SIGNING_ALLOWED=NO — BUILD SUCCEEDED/exit0. Core/model/store/rows/grid/projector не изменены, full/core/web/legacy не повторялись.

Source review: OrbitIOSApp removesCalendar tab, TodayWorkspace ownsday/mode (appear/active/30s) и inputsacceptedlist/fixedcalendar. Sibling NavigationStacks не nested. Timer не writes, newdayreloads sharedmodel; Calendar applyFixedDay guardsvalid/change and collapsesday. Mode @State вне conditionalchildren сохраняется черезInbox вTabView; actualexecutorUIclaims об этом записаны, нового собственногоGUIвэтомreview не было. Existing UUID/callbacks/readonlystore preserving unmodified source. Повторные harmlessreloadoncurrentDay/theme не blocker, no newcache.

Просмотрены screenshots02-calendar и04-AXL: modecontrols/TodayInbox only bottomnav/calendar acceptedrender видимы; longtext/listdynamicheight не clipping. Executor reports ownsourceUUID complete/reopen/cancel+same9rows readonlystore. Midnight/timezoneGUI, pan/gridoffset/longpress/realdevice ещёUNVERIFIED; sourceclockwiring проверен, не заявляем runtime midnightPASS.

Неблокирующая P3 captionlocalization: fixedDayCaption иTodaylist используют InboxRowView.dateLabel (DateFormatter безявнойru_RU), actualscreenshots «14 Oct 2026» вопреки report «русскийcaption». В NAV002 scope ужеменяетCalendar caption/header; включить маленькийview-localru_RUfix calendar/Todaycaption безchangesdate/store/helpercore. Не выдаём новыйreviewloop радиP3, но не считаем русскуюдату проверенной. Этоне requirementизменить системнуюlocale.

NAV001 accepted: Today List/Calendar реальный; временноtwoactualtabs поstagecontract. СледующийNAV002 добавит REALUpcoming List/Calendar same model/selectedday, безfakeplaceholder/3days/Month/drag/schema. No push/deploy.
