Итог: DONE,2026-10-14, productfe8e58d3a93f1e8e657eaa0ed4b5ba92a8668856. Review reports/NATIVE-007C.md; ниже historicalassignment. Navigation отдельныйCalendartab заменяетсяNAV001/NAV002 по прямому уточнению пользователя.

# NATIVE-007C — раскрываемая область «Без времени»

ASSIGNED, 2026-10-14. Один маленький UI результат: верхний список в календарном Дне сворачивается до трёх задач, раскрывается и прокручивается внутри своей области. Пользовательские reference IMG_1210/1212 показывают принцип; не копировать их весь экран. Только Day, 3 дня пока не реализовывать.

## База и scope

Accepted source base 5e5274964465142093471535d7618ddda34d07fb (локальный merge NATIVE-007B). Starting SHA — assignment HEAD из handoff. Worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-007C, branch task/NATIVE-007C. Проверить Git root/branch/HEAD/status, прочитать AGENTS/ DESIGN/этот TASK. Не выполнять предыдущие R1/R1b.

Product scope CalendarDayScreen.swift; один небольшой новый локальный SwiftUI subview в apple/OrbitIOS/OrbitIOS/ допустим, если уменьшает сложность. Existing InboxRowView/model callbacks переиспользовать, их implementation не менять. Also reports/NATIVE-007C-executor.md. DayTimelineView/core/projector/model/store/editors/Today/Inbox/nav/Xcode project/macOS/web/root docs НЕ менять. Без новых dependencies/frameworks.

## Поведение

- «Без времени» использует ровно projection.untimedTaskIDs выбранного civil дня, порядок и UUID сохраняются; не включать undated или timed, не менять completion policy. Никаких task writes от раскрытия/прокрутки/смены дня.
- По умолчанию свёрнуто: до 3 строк; если задач больше, показать «Ещё N» и раскрывающую стрелку. При 0 — компактная честная пустая строка; при 1–3 не показывать фиктивное «Ещё». Не резервировать пустые строки.
- Раскрытие доступным control >=44pt: больше строк, кнопка «Свернуть», state/label/AX identifier понятны. Height не растёт от общего количества: максимум примерно треть полезной высоты экрана, с независимой вертикальной прокруткой при избытке. Не возвращать unlimited VStack, не выталкивать дату или timeline. На обычном iPhone expanded показывает больше3 компактных строк. Dynamic Type/малый экран: доступность и сохранение сетки важнее фиксированного числа видимых строк; все реальные строки доступны scroll, текст/control не обрезаются вслепую.
- Строки сохраняют существующие complete/reopen/date actions и открытие настоящего sheet правильного source UUID. Compact visual, native fonts/surfaces/dividers/coral; не рисовать fake Liquid Glass. Не добавлять здесь новое создание/drag/delete.
- Раскрытие/сворачивание не пересоздают timeline и не запускают повторный scrollTo(hour-8): после прокрутки grid позиция остаётся. SelectedDay тоже остаётся. Проверить .id/условные ветки/реальный lifecycle, не добавлять global caches/controller.
- При смене выбранного дня — свернуть область (до3) и сбросить scroll только untimed списка; timeline/date navigation прежние. При complete/date action/reactive refresh — обновить реальные строки/N без устаревших clones, collapse не писать в БД. Если count снизился <=3, не держать фиктивную кнопку.

## Соразмерные проверки

Один iOS Simulator build DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer, CODE_SIGNING_ALLOWED=NO, own DerivedData. Core/schema неизменны — core/legacy/web/full suites не повторять. Own temporary Simulator+real-core synthetic fixture: выбранный день с12untimed+1timed, соседний день с2untimed, empty day. GUI: default3+«Ещё9»; expanded >3 и оставшаяся видимая grid/date controls; достижимость последней строки внутренним scroll; collapse3; смещение grid не сбрасывается при toggle; day switch2/no fake more и empty. Открыть дату одной строки и Cancel без записи, complete/reopen existing path (counts/content корректны). Один Dynamic Type smoke; own synthetic SQLite before/after при чисто UI переключениях без изменений. 2–3 screenshot collapsed/expanded вне product tree /Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/. Tooling ограничения честно UNVERIFIED; не тратить часы на недоставляемые coordinate gestures.

Обычные scoped commits, diff --check/clean tree. Отчёт СОХРАНИТЬ В ФАЙЛ reports/NATIVE-007C-executor.md: start/full latest/files/commands/exits/GUI/screenshots/limits/cleanup. Чат только4–5коротких строк статус/SHA/итог/checks/report. Остановиться до независимого review Codex. Без merge/push/amend/rebase/reset/stash/deploy, main/других worktree/personal stores/CRM/3000/hooks/system settings/xcode-select/signing/AppleID не трогать. NATIVE-007D/drag/resize/3дня/Месяц/AI не начинать.
