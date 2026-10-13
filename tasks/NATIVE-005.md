# NATIVE-005 — iOS: редактор времени и длительности

NEEDS_FIXES (R1), 2026-10-13. Одна коррекция названия задачи назначена в task worktree: tasks/NATIVE-005-R1.md; review reports/NATIVE-005.md. Исходный scope ниже сохранён. Один результат: пользователь назначает, изменяет и убирает временной интервал уже датированной задачи из Inbox. Принятый core не переписывать; календарь/Today/навигация отдельно.

## Старт

Review/source base: `a56137473b186efe5b87d4ae9c46881f092262df` — принятый NATIVE-004 (core50, iOS build, legacy upgrade PASS). Ветка `task/NATIVE-005`, worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-005`. Starting SHA — HEAD assignment-коммита, получить через git rev-parse HEAD до изменений и записать в отчёт. Проверить root/branch/status; прочитать AGENTS.md, PRODUCT.md, ARCHITECTURE.md, DESIGN.md и этот TASK. Старые задания не исполнять.

## Scope: три продуктовых файла

1. `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift`: один wrapper принятой store.setPlannedInterval и русские сообщения typed errors; минимально дополнить сообщение ошибки даты для endOutOfRange.
2. `apple/OrbitIOS/OrbitIOS/InboxScreen.swift`: action времени, краткая подпись, минимальная маршрутизация sheet.
3. Новый `apple/OrbitIOS/OrbitIOS/TaskIntervalSheet.swift`: небольшой native SwiftUI editor.

Также разрешены краткая секция `apple/OrbitIOS/README.md` и `reports/NATIVE-005-executor.md`. Core/schema/TaskPlannedDate/TaskDateSheet/macOS/web/Xcode project/root coordination docs не менять. Проект уже использует filesystem-synchronized group. Не добавлять dependencies, targets, scheduler, большие controllers, fault framework или новый постоянный UI-test target. Если реальный blocker требует другого scope — сообщить Codex, не исправлять молча.

## Поведение

- У строки с plannedDate появляется clock-action «Время задачи: <title>», область нажатия >=44pt. Без даты clock-action отсутствует: сначала назначается дата существующим calendar-action. Никакого автоматического назначения сегодня.
- По clock-action открывается один sheet «Время задачи»: название, назначенная дата, два подписанных TextField — «Начало» (HH:mm) и «Длительность, мин». Native Form/системные цвета, существующий coral accent, Dynamic Type, доступные labels/identifiers; поля и действия доступны при клавиатуре. Использовать editable текстовые поля, не wheel-DatePicker и не преобразование Date/UTC для времени. Подпись формата и диапазона длительности видима. Это маленький editor, не переделка дизайна Inbox.
- При каждом новом открытии draft берётся из текущих сохранённых time/duration. Если интервала нет: только draft defaults 09:00 / 30. Открытие, изменение полей, Cancel и swipe-dismiss не пишут в store. После Cancel/reopen отвергнутый draft не воскресает.
- «Сохранить» вызывает одну store-операцию через model, пара передаётся целиком. Core — источник правил: ASCII HH:mm, duration 1...1440, дата обязательна, end в 1900...2199; duration input разбирается безопасно без overflow и дробей. Некорректный/пустой input не превращается в nil/nil, default или нулевое значение. Не вводить собственную календарную арифметику. Успех только после store save, затем reload и dismiss. Отказ показывает понятную русскую ошибку, сохраняет draft и sheet для исправления/retry. Не прятать ошибки в console и не сообщать успех после отказа.
- «Отмена» закрывает без записи. «Убрать время» видима для сохранённого интервала, вызывает nil/nil; дата остаётся. При ошибке не закрывать sheet.
- В строке рядом с датой показывать сохранённый start–derived end; например 09:00–09:30. При переходе через полночь 23:30–01:00 (+1 день). Использовать TaskTimeInterval.end, не хранить end и не применять timezone conversion. Без интервала остаётся прежняя подпись даты. Не менять порядок/видимость задач и completion.
- Существующий date editor работает как раньше: смена даты сохраняет валидный interval, «Убрать дату» очищает date/time/duration принятой core-операцией; строка после reload отражает это. Сообщение endOutOfRange при смене даты должно быть понятным, TaskDateSheet переписывать не требуется.
- Одновременно представляется один date или interval sheet. Минимальный enum/идентичность presentation по kind+task UUID допустим в InboxScreen; не добавлять новую архитектуру. Draft каждой новой presentation инициализируется заново. Store операции синхронные MainActor, искусственную сетевую pending-машину не вводить.

## Соразмерные проверки

Один `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` в apple/Orbit: сохранить 50 существующих tests. Один iOS Simulator build CODE_SIGNING_ALLOWED=NO в own DerivedData. Core не меняется: legacy migration и 7200 calendar oracle повторять не нужно; web/npm/DB/auth/E2E не запускать.

В собственном временном iPhone Simulator, синтетические данные, реальный GUI:
1. Назначить дату существующим editor, открыть новый sheet, сохранить 09:00/30 — строка показывает interval.
2. Изменить на 23:30/90 — показать (+1 день); terminate/relaunch без reinstall подтверждает persistence.
3. Изменить draft и Cancel/reopen — прежние сохранённые значения; открытие не пишет.
4. Некорректный HH:mm (например 25:00) и duration 0 либо 1441 — видимая ошибка, draft сохранён, исходный interval не изменён; исправление затем Save успешно.
5. «Убрать время» оставляет дату; снова назначить interval и «Убрать дату» очищает все три поля. Достаточно существующих core tests для изменения даты: не тратить часы на недоступный AX wheel.
6. Краткий smoke add/complete/reopen; keyboard/layout на iPhone и accessibility-large. Два скриншота: editor и строка с interval, вне product tree `/Users/atlhnv/Codex/orbit-outputs/NATIVE-005/`.

GUI evidence отделять от build/unit/readonly SQLite. Если tools не позволяют действие, честно пометить UNVERIFIED и указать конкретную причину; не заменять GUI утверждение прямой DB записью. Повтор проверок — только после изменений/ошибки, не гонять все gates дважды по привычке. Никакой проверки личных stores/устройств. Удалять только собственные временные Simulator/файлы после сохранения evidence; не менять xcode-select, Apple ID/signing, Colima/CRM/localhost:3000/hooks.

## Передача и остановка

Обычные scoped commits, git diff --check и clean tree. Подробный отчёт сохранить в `reports/NATIVE-005-executor.md`: start/latest SHA, files, commands/exits, GUI/persistence evidence, screenshots и ограничения. НЕ выводить полный отчёт в чат. В чат только 4–5 коротких строк: READY_FOR_REVIEW или BLOCKED, full SHA, итог, checks, путь к отчёту.

Остановиться до независимого Codex review. NATIVE-006/Today/календарь/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy; main/другие worktrees не менять.
