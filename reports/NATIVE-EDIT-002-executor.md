# NATIVE-EDIT-002 — отчёт исполнителя (GLM)

## Статус

**READY_FOR_REVIEW** (остановка до Codex review). Один bounded UI CRUD result: «Переименовать…» и destructive «Удалить…» в существующем Menu тела shared `InboxRowView` (Inbox/Today List/Upcoming List без копий UI) + rename editor + delete confirmation + тонкие model-операции через принятый core. Один iOS Simulator build **BUILD SUCCEEDED** + один целевой GUI-проход на СВОЁМ simulator `orbit-e2` со своим store — все целевые проверки PASS, ошибки/отказы видны и повторяемы (см. UNVERIFIED для honest-ограничений).

## Назначение и база

- TASK: `tasks/NATIVE-EDIT-002.md`; worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-EDIT-002`; ветка `task/NATIVE-EDIT-002`.
- Starting full SHA `19d45dedc643e1ad23c36c0e6a9e4ee336adf4aa` — root/branch/HEAD совпали, дерево чистое до изменений. База `9a16ea0041601eb12c15be040493453e8fd074d1` (ADD004 accepted merge) в истории ветки.
- Прочитаны AGENTS.md, DESIGN.md (разделы «Обычные list строки», «Навигация», NATIVE-005), tasks/NATIVE-EDIT-002.md, предыдущий reports/NATIVE-EDIT-001-executor.md (методология).

## Изменённые файлы (ровно по scope TASK — 3 UI файла + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/TaskManagementPresentation.swift` | НОВЫЙ. `TaskRenamePresentation`/`TaskDeletePresentation` (fresh UUID на каждое открытие — паттерн create-sheet: черновик всегда пересоздаётся из persist-названия, отменённый не воскресает); `TaskManagementHostModifier` — `.sheet(item:)` rename + native `.confirmationDialog` delete с `presenting:`-вариантом, хостится на стабильном теле строки (никогда внутри ephemeral Menu-контента); `TaskRenameSheet` — поле (автофокус, `submitLabel(.done)`, `onSubmit` = save), «Сохранить»/«Отмена», form-level ошибка для retry, флаг `saved` против повторного submit после успеха. |
| `apple/OrbitIOS/OrbitIOS/InboxScreen.swift` | В `InboxRowView`: 2 `@State` presentation-свойства; в СУЩЕСТВУЮЩЕМ Menu тела добавлены `Divider()` + `Button("Переименовать…")` + `Button("Удалить…", role: .destructive)` — пункты даты/времени не тронуты, круг complete/reopen независим; на тело строки (стабильный host) повешен `.taskManagementHost(...)`. Label Menu/геометрия строки/существующие date-time callbacks не менялись. |
| `apple/OrbitIOS/OrbitIOS/IOSInboxModel.swift` | `IOSInboxFormatting.renameMessage` (accepted title formatter через `validationMessage`) / `.deletionMessage` (storage formatter); `rename(title:for:) -> String?` — через `store.renameTask`, nil при успехе/reload, message при отказе; `delete(_:)` — `store.deleteTask` только после подтверждения вызывающего, паттерн `setCompleted`: отказ держит причину в shared `writeError` (баннер рендерится на всех трёх экранах), успех сбрасывает; reload в обоих путях; write-success не переклассифицируется read-failure (read failure остаётся listError). |

Не менялись: core (`OrbitTaskStore.renameTask`/`deleteTask` из EDIT-001 использованы как есть), schema, store, TaskCreatePresentation, дата-время editors, workspaces, mode header, CalendarDayScreen/DayTimeline/CompactCalendarTaskRow, геометрия строк, root docs, web. `internal setTitle` из UI не вызывается (grep: единственный caller — store). Calendar context menus не расширены. Generic router/вторая model copy/inline ikons не добавлены.

## Поведение (соответствие пунктам 1–5 TASK)

1. Menu items живут в shared row → работают в Inbox, Today List и Upcoming List (включая completed) без дублирования; круг завершения независим; date/time пункты сохранены (у undated — прежний disabled hint). Calendar не тронут; delete/rename из списка сразу видны в Calendar того же shared UUID (проверено GUI).
2. Rename editor пересоздаёт draft из актуального `task.title` при каждом открытии (fresh UUID identity); trim/валидация только через `store.renameTask`; отказ → draft + error в форме для retry; успех → close (модель уже reload); «Отмена»/swipe не пишут; noop normalized-identical — штатный store no-op (sheet закрывается как успех); UUID/date/time/completion не менялись (проверено store-дампом).
3. Delete — native `confirmationDialog` «Удалить задачу?» с видимым полным title в message (перенос длинного текста) и честным «безвозвратно — восстановить нельзя» (undo нет); открытие/отмена/тап-вне ничего не удаляют; `store.deleteTask` ровно по UUID вызванной строки и только после «Удалить»; retry требует нового подтверждения из menu.
4. Model — тонкие операции, user-error строки из принятых форматтеров; ошибки rename видимы в самой shared-форме (на любом из трёх списков), ошибки delete — в shared `writeError`-баннере, который рендерят все три экрана (не только Inbox). Один активный editor/confirmation на строку (per-row `@State`, modal исключает вторую презентацию); `saved`-флаг — successive Save не повторяет rename после успеха; dialog presentation очищается до `model.delete` — повторного delete после успеха нет (строка исчезает, state уничтожается).
5. Презентации хостятся на теле строки вне Menu; существующие date/interval sheets (per-screen hosts) не задеты; элементы ≥44pt, native fonts, ScrollView в форме, полный title доступен AX (accessibilityLabel строки — task.title); строки/empty-состояния не перерисовывались.

## Проверки (фактические)

| Проверка | Результат |
| --- | --- |
| `xcodebuild -project apple/OrbitIOS/OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-edit002-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR=/Applications/Xcode.app) | **BUILD SUCCEEDED** (exit 0) |
| `git diff --check` + `git status` | чисто; после коммитов дерево чистое; diff ровно 3 файла (+72 строки к 2 модифицированным + 1 новый) |

### Целевой GUI-проход (СВОЙ simulator `orbit-e2`, iPhone 17 / iOS 27.0, создан и удалён; store — sandbox СВОЕГО приложения; скриншоты `simctl io screenshot`; store — sqlite-копии контейнера СВОЕГО приложения; evidence `/Users/atlhnv/Codex/orbit-outputs/NATIVE-EDIT-002/`)

Синтетические данные (созданы через GUI create sheet): 4 задачи —
- **A** `0ab2f6bd-f436-4d62-b584-039195908f1a` «zadacha a» → dated+timed 2026-10-15, 09:00, 30 мин (Today-пресет, «Выбрать эту дату», время 09:00/30);
- **B** `39ff562e-6774-49ad-8543-77338553d5dc` «zadacha b» undated → завершена кругом;
- **C** `668c5c35-e937-469f-99ec-85b7404b425c` «udalit menya» undated (delete target);
- **D** `18d3799b-4f31-4fd3-8df0-c119c8b8a8ed` «ostalas d» undated (survivor).

1. **Rename из Today List (реальный клавиатурный ввод + submit):** menu A (e2-28: «Дата…», «Время и длительность…», разделитель, «Переименовать…», красное «Удалить…») → sheet показал актуальное «zadacha a» с автофокусом (e2-29) → поле очищено backspace, введено «pereimenovalo segodnya» посимвольно hardware-клавиатурой, подтверждено клавишей return → sheet закрыт, строка «pereimenovalo segodnya» 09:00–09:30 (e2-30). Store S2: **title изменён, UUID/дата/время/длительность/completion нетронуты** (`0ab2f6bd…|pereimenovalo segodnya|2026-10-15|09:00|30|-`).
2. **Cancel/reopen discard:** draft «pereimenovalo xxx» → «Отмена» → повторное открытие показало persist «pereimenovalo segodnya» БЕЗ xxx (e2-31/32); store не изменился. Отменённый draft не воскрес.
3. **Blank refusal → corrected retry:** пустое поле → «Сохранить» → sheet открыт, красная ошибка «Не удалось переименовать задачу. Введите название задачи.» (e2-33) → введено «otredaktirovano posle oshibki», submit → успех (e2-34); store: тот же UUID, новый title.
4. **Completed rename из Inbox + tooLong refusal:** menu завершённой B (undated: пункт времени корректно disabled) → sheet «zadacha b» → введено 501 символ «a» → «Сохранить» → отказ «Не удалось переименовать задачу. Название не должно превышать 500 символов.», draft сохранён (e2-37) → поле очищено, введено «zavershyonnoe b», submit → успех; круг остался заполненным, **completedAt в store бит-в-бит идентичен до- и после-rename** (813713026.91345203), тот же UUID (e2-38).
5. **Delete refusal:** menu C → «Удалить…» → native confirmationDialog: заголовок «Удалить задачу?», полный title в message с переносом, «безвозвратно», destructive «Удалить» (e2-40; в popover-стиле роль cancel — тап вне/свайп) → тап вне → **count=4, C на месте** (e2-41).
6. **Delete confirm — ровно target из набора 4:** повторное подтверждение → «Удалить» → строка исчезла; store count=3, UUID C отсутствует; **survivors со всеми полями целы**: A (renamed+date+time+duration, not completed), B (renamed+completedAt), D («ostalas d» без изменений) (e2-42).
7. **Shared Calendar отражает:** Сегодня → Календарь — блок «otredaktirovano posle oshibki» 09:00–09:30 на своём слоте, C отсутствует (e2-43). Date/time UUID не менялись.
8. **Upcoming List:** в окне 15–21 окт. строка A с тем же shared menu (Дата…/Время…/Переименовать…/Удалить…) (e2-45); полный CRUD в 3 разделах не повторялся.
9. **AXL smoke формы:** `content_size accessibility-medium` — список и menu масштабируются, rename form: поле/«Сохранить»/«Отмена» доступны и крупны, title полный (e2-46…48); возвращён `large`.
10. **Relaunch persistence:** terminate + launch — «otredaktirovano posle oshibki» 09:00–09:30 на месте, C отсутствует (e2-49); финальный store count=3.

### Не повторялось (по TASK)

Core 36/44/full suites, web/db/auth/legacy — core unchanged; полный UI date/time/create suite — эти editors/create не менялись. Unknown id / runtime save failure — намеренно НЕ fault-inject (TASK запрещает): пути отказа покрыты принятыми store-ошибками (`taskNotFound` → «Задача не найдена в хранилище.»; storage → deletionMessage/renameMessage), GUI runtime-failure не симулировался.

## UNVERIFIED / ограничения

- **Кириллица в GUI-вводе:** hardware-клавиатура симулятора в этой конфигурации транслитерирует кириллические keystroke-события (раскладка), а pasteboard-мост `simctl pbcopy` в iOS 27 симуляторе не работает (roundtrip пуст). Синтетические названия поэтому латинские, ввод — реальный посимвольный keyboard. Само приложение принимает/хранит кириллицу (core Unicode-scalar валидация не менялась и покрыта EDIT-001 тестами) — но GUI-ввод кириллицы руками в этой сессии не продемонстрирован.
- Render software keyboard на скриншотах отсутствует (hardware-keyboard режим DeviceHub, как и в R1 ADD-004): ввод/submit/фокус подтверждены, визуальный кадр клавиатуры — UNVERIFIED (tooling).
- Runtime disk failure / реальное устройство / VoiceOver / тёмная тема — вне TASK, не проверялись.
- Строки ошибок rename/delete при РЕАЛЬНОМ store-failure в GUI не показывались (fault injection запрещён): формулировки верифицированы кодом + двумя GUI-отказами валидации (blank/tooLong) тем же кодовым путём `model.rename → форматтер`.
- Упоминание: в ходе настройки ассистент один раз выделил в DeviceHub sidebar ЧУЖОЙ simulator «iPhone 18 Pro» (только AX-selection в списке, никаких действий/удалений на устройстве) и один клик мимо попал в области окна System Settings пользователя — немедленно прекращено; устройства/настройки не изменялись (проверено `simctl list`: все девайсы целы).

## Гигиена

- Обычные scoped commits (код + отчёт) от базы; без merge/push/amend/rebase/reset/stash/clean/deploy; main и чужие worktrees не тронуты; xcode-select/signing/AppleID/hooks/systemsettings не менялись (закрытое окно настроек пользователя не трогалось).
- Cleanup только СВОИХ ресурсов: simulator `orbit-e2` (shutdown+delete), `/tmp/orbit-edit002-dd`, драйверы/скрипты в `/tmp`, sqlite-копии в `/tmp`. Evidence (скриншоты + финальный store-снапшот с синтетическими данными) — `/Users/atlhnv/Codex/orbit-outputs/NATIVE-EDIT-002/` (вне product tree); дампов в product tree нет.
- iPhone QA/подписание/дедлайны/напоминания/notifications/Projects/drag/resize/3days/Month/AI не начинались. Calendar context menus не расширены.

## Git

- Код: SHA в чате (единственный кодовый commit от `19d45dedc643e1ad23c36c0e6a9e4ee336adf4aa`).
- Отчёт: финальный commit ветки (SHA в чате).
