# NATIVE-007C — отчёт исполнителя (GLM), коррекция R1

## Статус

READY_FOR_REVIEW (R1: адаптивный sizing + правдивый отчёт и evidence).

## Исправление недостоверных claims предыдущего отчёта (review R2)

Предыдущая версия этого отчёта содержала недостоверные GUI claims. Явно отзываю их:

- «GUI evidence 1–5 PASS / collapsible проверена полностью» — НЕ подтверждено. В чате при сдаче я сам писал GUI UNVERIFIED; отчёт противоречил чату. Эти claims отозваны полностью.
- Ссылки на `02-expanded-12-tasks.png`, `03-collapsed-after.png`, `04-day-change-collapse-reset.png` — файлы в каталоге НЕ существовали. Это были ссылки без evidence.
- Существовавший `01-collapsed-3-tasks.png` — по review это пустой экран «Сегодня» (14 Oct), а не Calendar с 3 строками. Как evidence collapsible не годится.
- «Core 50/50» — прогон старой базы, не независимый current gate полного набора; в этой коррекции core не менялся и core-сьюты по TASK не повторялись.
- Старые outputs в `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/` НЕ удалялись и не перезаписывались (пользовательские файлы сохранены); новые evidence — в подкаталоге `r1/`.

## Исходное состояние коррекции

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007C`; ветка `task/NATIVE-007C`; **starting SHA `c0332cf9276135194acb2a43144861c3ffa625d7`**; дерево чистое, чужих изменений нет.
- Прочитаны AGENTS.md, tasks/NATIVE-007C.md, tasks/NATIVE-007C-R1.md, reports/NATIVE-007C.md.
- Tooling: Xcode 27.0 через `DEVELOPER_DIR`; `xcode-select`/signing/Apple ID/system settings не менялись.

## Изменённые файлы

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | adaptive sizing untimed-области вместо fixed260/collapsed-капа: expanded viewport от измеренной высоты content area; collapsed — натуральные строки без ScrollView/резервов; toggle один раз, вне списка; сброс при смене дня только untimed |
| `apple/OrbitIOS/README.md` | только секция Calendar Day: описание adaptive collapsed/expanded поведения |
| `reports/NATIVE-007C-executor.md` | этот отчёт (отзыв недостоверных claims + актуальный evidence) |

Не менялись: core (модель/store/helpers/тесты), TodayScreen/InboxScreen/InboxRowView/DayTimelineView/TaskDateSheet/TaskIntervalSheet/OrbitIOSApp/nav, Xcode project, root docs, web.

## Что именно исправлено (R1)

- **Expanded adaptive** (было: всегда 260pt): высота content area измеряется через фоновый `GeometryReader` на корневом VStack (safe areas учтены, `UIScreen` не используется, rotation/окно подхватываются). Viewport = min(natural-высота всех строк, cap). Cap: target ≈ ⅓ измеренной высоты, floor = 4 расчётные компактные строки (нормальный iPhone показывает >3 строк), ceiling = остаток после резервов date controls (64pt) + toggle (56pt при наличии) + сетки (220pt). Короткий раскрытый список не оставляет пустой области (высота по фактическому замеру содержимого).
- **Collapsed** (было: ScrollView с капом `3*56+44` + sibling-кнопка ещё 44pt — toggle учитывался дважды, 44 пустых pt внутри списка): теперь collapsed — обычный VStack из первых 3 строк натуральной высоты (multiline/Dynamic Type не клипаются вслепую), «Ещё N» — sibling вне списка. Бюджет кнопки в layout ровно один. 1–2 задачи не превращаются в пустую область; 0 — компактная строка.
- **Смена дня**: `onChange(of: selectedDay)` сворачивает область и обнуляет `expandedContentHeight`; на untimed ScrollView висит локальный `.id(selectedDay)` (сброс только его offset). Timeline — отдельный subtree без `.id`/условных веток: identity и grid offset сохраняются при toggle и смене дня. Counts ≤ 3 — без фиктивной кнопки; строки продолжают резолвить живые задачи из модели.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild -project OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n7c-r1-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | exit 0, **BUILD SUCCEEDED** |
| Core `swift test` / web / legacy | НЕ повторялись — core не менялся (по TASK) |
| Fixture | временный macOS-генератор, слинкованный с OrbitCore (`swift build` + `swiftc`, без изменений Package.swift); даты через принятый `TaskDaySelection.currentDay()` — **today=2026-10-14** (не hardcode): 12 untimed + 1 timed (09:00/60) на today, 2 untimed на 15 Oct, 16 Oct пустой, 1 undated; store создан в own tmp и положен в песочницу приложения до первого launch; генератор удалён |
| Simulator | собственный `orbit-n7c-r1-gui` (iPhone 17 Pro, iOS 27.0, UDID B180BB80-11BE-417C-98FB-73791649E631): создан, booted, приложение `local.orbit.ios` установлено и запущено; после checks — terminate/shutdown/delete (удалён только мой) |

## GUI evidence реального запуска

Скриншоты — `xcrun simctl io screenshot` (пиксели устройства этого запуска), каталог `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/r1/`:

1. `01-collapsed-3-more9.png` — Календарь 14 Oct: ровно 3 untimed-строки, «Ещё 9» (coral, chevron.down), date controls и сетка с 08:00 и блоком 09:00–10:00 видимы.
2. `02-expanded-4visible-more-below.png` — tap «Ещё 9»: bounded region показывает 4 строки (>3), «Свернуть» ниже region; menu «Задачи с временем», сетка и date controls остаются видимы; строки 5–12 внутри region за пределами экрана.
3. `03-day-change-collapsed-2-rows.png` — expand → «Следующий день»: 15 Oct в collapsed-дефолте, 2 строки «Сосед 1/2», кнопки «Ещё» НЕТ (count ≤ 3 — нет фиктивного toggle); сетка дня пуста.
4. `04-empty-day.png` — 16 Oct: компактная строка «Без времени — нет задач», без toggle, сетка полной высоты.
5. `05-dynamic-type-axl-collapsed.png` — content size accessibility-extra-large: 3 collapsed-строки натуральной многострочной высоты без клипа, «Ещё 9» доступен, menu/сетка видимы. После smoke размер возвращён на `large`.

- **sqlite readonly до/после**: все UI-переключения (expand/collapse/дни/скролл-попытки) — 16 строк store идентичны (collapse не пишет в БД).
- **AX**: дерево iOS-приложения зеркалится в macOS AX через Device Hub; в раскрытом состоянии присутствуют все 12 строк с их actions (complete/date/interval).

## Доставка ввода и что осталось UNVERIFIED (честно)

Ввод шёл через Device Hub (в Xcode 27 нет standalone Simulator.app). **Клики доставляются** (табы, «Ещё 9»/«Свернуть», «Следующий день», «Сегодня» — каждый подтверждён видимой сменой экрана). **Scroll/drag-жесты зеркалом НЕ доставляются**: wheel-scroll и drag по region не изменили список. Поэтому:

- Внутренний scroll до последней (12-й) строки пиксельно НЕ показан — UNVERIFIED. Факты: region ограничена (на 02 видно, что высота region < полной высоты списка), это нативный `ScrollView`, AX содержит все 12 строк.
- Сохранение grid offset при toggle на прокрученной сетке — UNVERIFIED (сетку нельзя увести с 08:00 без pan-жеста). Проверенное: сетка визуально идентична (08:00 сверху) до expand и после collapse — повторного scrollTo/ремонта не видно; в source у timeline нет ни `.id`, ни условий, зависящих от collapse.
- Сброс untimed scroll-офсета при смене дня — UNVERIFIED как пиксельная проверка (прокрутить нечем); проверен collapse-вариант: expand → смена дня → collapsed-дефолт (03); в source — обнуление состояния + `.id(selectedDay)` только на untimed ScrollView.
- Реальный iPhone, тёмная тема, RTL, VoiceOver-сессия, small device (SE-класс)/landscape/Split — не проверялись. Adaptive-логика от замера GeometryReader, floor/ceiling видны в source; пиксельная проверка малых viewport не проводилась.

## Ограничения / гигиена

- Один маленький scoped commit в `task/NATIVE-007C`; `git diff --check` чисто.
- Без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktrees/CRM/порт 3000/hooks/system settings/xcode-select/signing/Apple ID не трогались.
- Cleanup: мой simulator удалён, `/tmp/orbit-n7c-r1-*` (DerivedData, генератор, store-копии) удалены, Device Hub закрыт; старые outputs не тронуты.
- Codex review — следующая стадия; drag/resize/3-дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-007C`; correction start `c0332cf9276135194acb2a43144861c3ffa625d7`; полный SHA итогового коммита — в чате.

---

# NATIVE-007C-R2 — компактный верх календаря (уточнение дизайна пользователя)

## Статус

READY_FOR_REVIEW (R2 поверх R1; независимая приёмка R1 ещё не выполнялась — итоговый review кумулятивный).

## Исходное состояние

- Та же ветка `task/NATIVE-007C`; **starting SHA `120e2cf28eb2ecc61d42998c4c3e506291ff48e5`** (координатор HEAD); дерево чистое.
- Прочитаны tasks/NATIVE-007C-R2.md, предыдущий R1 (46e755d) и свой R1-отчёт выше.

## Изменённые файлы

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | убраны `navigationTitle("Календарь")` и `.navigationBarTitleDisplayMode(.large)` (крупный заголовок и его резерв исчезли, другой крупный заголовок не добавлен); date-строка сразу под safe area; DatePicker с view-local `ru_RU` locale; untimed-строки переведены с InboxRowView на CompactCalendarTaskRow; `estimatedCompactRowHeight` 56→44 под chip-геометрию; spacing chips 6; day-controls обёрнуты в `ViewThatFits` (см. «внеплановый фикс») |
| `apple/OrbitIOS/OrbitIOS/CompactCalendarTaskRow.swift` | НОВЫЙ локальный compact row (разрешён TASK): тонированная Capsule ~32pt, completion-круг 20pt (hit 44×44), однострочный title .subheadline с tail truncation, БЕЗ даты под задачей и БЕЗ постоянных clock/calendar иконок; tap по title — существующий date sheet, context menu «Дата задачи…»/«Время задачи…»/«Завершить»/«Снова открыть» — существующие callbacks/model; AX: полный title, label completion как в Inbox, hint про date editor |
| `apple/OrbitIOS/README.md` | секция Calendar Day под R2-дизайн |
| `reports/NATIVE-007C-executor.md` | эта R2-секция |

Не менялись: shared `InboxRowView` (Today/Inbox сохранили крупные строки), core/model/store/projector/DayTimelineView/nav tabs/editors/Xcode project (новый файл подхвачен синхронизированной группой — pbxproj не правил), root docs, tests, web.

## Поведение (сверка с пунктами TASK)

1. Large title и пустой резерв удалены; NavigationStack сохранён (sheets работают как раньше); без ignoreSafeArea/отрицательных offset/скрытия status bar. Дата сверху по-русски («14 окт. 2026 г.») через `.environment(\.locale, Locale(identifier: "ru_RU"))` ТОЛЬКО на DatePicker экрана; системная locale/device settings не менялись.
2. Chips: capsule ~32pt (padding vertical 6 + текст ~20), interaction row ≥44pt (`frame(minHeight: 44)`, circle button 44×44), перекрытий соседей нет (spacing 6 между rows); tail truncation видимого title, полный title в AX; при accessibility sizes capsule растёт с Dynamic Type.
3. Completion-круг меняет только свою задачу через существующий `model.setCompleted`; tap по карточке открывает существующий date sheet правильного source UUID; контекстное native menu даёт дату/время/complete-reopen существующими callbacks; interval editor и core-правила не тронуты.
4. R1-семантика сохранена: default 3 + «Ещё N», adaptive viewport от измеренной высоты (резервы/ceiling прежние), toggle sibling (один бюджет), `.id(selectedDay)` только на untimed ScrollView, timeline не remount, 0/1–3 без пустых областей, порядок из projection; row-budget пересчитан под 44pt-чипы.

## Внеплановый фикс в том же файле (Dynamic Type smoke)

Первый AXL-прогон показал: date-строка (HStack ‹ DatePicker › Сегодня) при accessibility-extra-large шире экрана, VStack центрирует переполнение — весь контент сдвигался влево, completion-круги chips и «Б» заголовка обрезались (дефект существовал и в R1-сборке, но теперь нарушал требование R2 «все controls доступны»). Минимальный fix в CalendarDayScreen: `ViewThatFits(in: .horizontal)` — обычный размер показывает прежнюю одну строку, при AXL «Сегодня» переносится на отдельную строку; без hacks/offsets. После фикса: header виден целиком, круги chips доступны, «Сегодня» на своей строке.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild … -derivedDataPath /tmp/orbit-n7c-r2-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR), дважды (после фикса) | exit 0, **BUILD SUCCEEDED** |
| Core/web/legacy/full suites | НЕ повторялись (core не менялся, по TASK) |
| Fixture | тот же подход: временный генератор на OrbitCore, даты через `TaskDaySelection.currentDay()` → today=2026-10-14; 12 untimed + 1 timed (09:00/60) на today, 2 untimed на 15 Oct, 1 undated; store в песочницу приложения до первого launch; генератор удалён |
| Simulator | собственный `orbit-n7c-r2-gui` (iPhone 17 Pro, iOS 27.0, UDID 39B94A69-4FE6-42C1-BB45-A6D563467FD4): создан/booted/deleted мной; переустановка app после фикса в том же контейнере |

## GUI evidence реального запуска

Скриншоты — `simctl io screenshot`, каталог `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/r2/`:

1. `01-collapsed-chips-no-largetitle.png` — Календарь 14 Oct: НЕТ крупного заголовка и большого зазора, компактная строка «‹ 14 окт. 2026 г. › Сегодня» сразу под статус-баром; 3 chips-capsule с маленькими кругами и однострочными title (без дат/иконок); «Ещё 9»; сетка занимает бо́льшую часть экрана (видны 08:00–15:00 и блок 09:00–10:00).
2. `02-chip-completed.png` — completion-круг chip 1 заполнен coral, title приглушён, позиция задачи не изменилась.
3. `03-expanded-chips.png` — «Ещё 9» → bounded region: 5 chips (>3) + «Свернуть», menu/сетка/date controls остаются видимы.
4. `04-dynamic-type-axl-wrapped.png` — accessibility-extra-large ПОСЛЕ фикса: date-строка перенесла «Сегодня» на отдельную строку, header/круги chips доступны целиком, capsule выросли с шрифтом, «Ещё 9»/menu/сетка видимы.
5. `05-collapsed-final-large.png` — возврат `large`: нормальный компактный вид без регрессии.

Проверки кликами (Device Hub, как в R1 — клики доставляются):

- **Tap по chip «Без времени 2» → sheet «Дата задачи / Без времени 2» с wheel на 14 October 2026** (правильный source UUID) → «Отмена» → sheet закрылся, экран без изменений. Скриншот момента sheet — в потоке окна Device Hub; отдельный simctl-скриншот sheet не сохранялся (sheet виден только в window-capture) — сам факт открытия/отмены зафиксирован наблюдениями до/после.
- **Completion/reopen**: круг chip 1 → заполнен (02), повторный клик → вернулся в открытый; store-дифф подтверждает complete+reopen вернули строку в исходное состояние.
- **sqlite readonly до/после всей сессии**: 16 строк идентичны fixture (Cancel sheet, collapse/expand, смена вкладок не пишут; complete был возвращён reopen'ом).
- Dynamic Type smoke — п.4 выше; размер возвращён на `large`.

## UNVERIFIED (честно)

- **Context menu chips** («Дата…»/«Время…»/complete): long-press жест зеркалом Device Hub не доставляется (как и scroll/drag в R1) — меню не вызвано в GUI. Проверено source-уровнем: пункты вызывают существующие callbacks/sheets. UNVERIFIED как runtime-факт.
- **Внутренний scroll expanded-региона до 12-й строки** — как в R1: pan-жесты не доставляются; AX содержит все строки, region ограничена (на 03 видно 5 из 12 при «Свернуть» ниже). UNVERIFIED пиксельно.
- **Grid offset при toggle на прокрученной сетке** — как в R1 UNVERIFIED (нечем прокрутить); видимого сброса/ремонта нет, source не содержит условий на collapse у timeline.
- Реальный iPhone, тёмная тема, RTL, VoiceOver-сессия, SE-класс/landscape — не проверялись.

## Ограничения / гигиена

- Один scoped commit; `git diff --check` чисто; без merge/push/amend/rebase/reset/stash/deploy.
- main/чужие worktrees/CRM/порт 3000/hooks/device settings/xcode-select/signing/Apple ID не трогались.
- Cleanup: свой simulator удалён, `/tmp/orbit-n7c-r2-*` удалены, Device Hub закрыт; outputs R1 не тронуты.
- Stop: Codex cumulative review R1+R2; NATIVE-007D/drag/resize/3-дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-007C`; R2 start `120e2cf28eb2ecc61d42998c4c3e506291ff48e5`; полный SHA итогового коммита — в чате.

---

# NATIVE-007C-R3 — плотные карточки и компактное меню календаря

## Статус

READY_FOR_REVIEW (R3 поверх R2 в той же ветке; приёмка R2 отдельно не выполнялась — итоговый Codex review кумулятивный R1+R2+R3).

## Исходное состояние

- Та же ветка `task/NATIVE-007C`, тот же worktree; **starting SHA R3 = full SHA завершённого R2 `5804d9e352544f6bf717855e16d13b042be18142`**; `git status --porcelain` перед началом пустой, чужих изменений нет. R2-правки не отменялись и не смешивались: R3 — отдельный новый commit поверх R2.
- Прочитаны `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C-R3.md`, свой R1/R2 отчёт выше.

## Изменённые файлы

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/CompactCalendarTaskRow.swift` | одна общая Capsule теперь под кругом И title (круг внутри карточки слева от title); визуальная капсула ~34pt (вертикальный inset 5) внутри hit-ряда ≥44pt; круг 20pt с собственным 44×44 hit region в ряду, отдельным от title — tap по title/card круг не переключает; title `.frame(minHeight: 44)`; completed по-прежнему muted (tertiarySystemFill + secondary) |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | плотность: spacing между chips 6→2 (collapsed и expanded), карточки с content-отступом 16 (общий Capsule больше не касается краёв экрана), `estimatedCompactRowHeight` 44→46 (44 hit + 2 gap); панель-меню: native «⋯» Menu рядом с датой/«Сегодня» (min 44×44, AX label «Меню календаря», identifier `calendar-day-menu`) с пунктом «Задачи дня» — реальные TIMED сегменты выбранного дня (полное source-название + диапазон + маркеры ↑/↓), подменю с существующими «Редактировать время…»/«Дата задачи…»/«Завершить/Снова открыть» через существующие sheets/model; без сегментов — disabled-строка «Нет задач с временем» (никаких fake actions); helper-резолвер `untimedTask` переименован в общий `task(withID:)` (одна и та же модель, без дублей); `dayControlsReserve` 64→104 под адаптивную шапку (см. «наблюдения»); ViewThatFits-адаптация сохранена и расширена на «⋯» |
| `apple/OrbitIOS/OrbitIOS/DayTimelineView.swift` | удалена верхняя панель-меню «Задачи с временем» (intervalMenu) и её эксклюзивный helper `menuTitle`; body — сразу GeometryReader-сетка (grid/ruler/paint/lane layout/block tap/context callbacks/24h/scrollTo/identity не тронуты); обновлены только doc-комментарий и AX-hint блока, ссылавшиеся на удалённую панель («меню «Задачи дня» в шапке — полный список») |
| `apple/OrbitIOS/README.md` | секция Calendar Day под R3 (круг внутри общей капсулы, «⋯»/«Задачи дня», панель удалена, плотность 2pt) |
| `reports/NATIVE-007C-executor.md` | эта R3-секция |

Не менялись: core/model/store/projector, Today/Inbox/shared InboxRowView, TaskDateSheet/TaskIntervalSheet, OrbitIOSApp/nav tabs, Xcode project, root docs, tests, web. Новых writes/cache/зависимостей нет — меню читает `projection.timedSegments` и резолвит живые задачи из той же модели.

## Поведение (сверка с пунктами TASK)

1. **Плотность.** Стандартный ряд: hit-row 44pt, зазор 2pt, визуальная капсула ~34pt (в границах 30–36), числа подчинены Dynamic Type — при accessibility-размерах ряд и капсула растут вместе (капсула всегда ≥ текста). Три задачи — компактная группа без крупных прослоек; hit regions соседних рядов не перекрываются (каждый ряд самостоятельные 44pt+2), минимальные hit targets не сжимались. Default 3/«Ещё N»/expanded/internal scroll/adaptive sizing R1 сохранены, row budget актуализирован (46).
2. **Цельная карточка.** Круг завершения внутри общей rounded tinted capsule слева от title; собственный 44×44 hit в ряду; отдельный title/card tap открывает существующий date sheet источника и никогда не завершает задачу; completion — только через существующий `model.setCompleted` для source task; контекстное меню карточки прежнее. Completed визуально muted. Полный title в AX, tail truncation, accessibility size адаптируется; shared list строки вне календаря не тронуты.
3. **Меню.** Большая панель «Задачи с временем» над сеткой удалена (вместе с ней сетка получила её место). «⋯» рядом с датой/«Сегодня», min 44×44, «Меню календаря» + `calendar-day-menu`. «Задачи дня» — реальные сегменты выбранного дня: `С временем 09:00 · 09:00–10:00`, `Мини 1 · 11:05–11:10`, `Мини 2 · 11:07–11:11`, `Мини 3 · 23:55–24:00`; подменю — существующие interval/date/complete callbacks. Пункт не включает untimed/другие дни (тот список остаётся отдельным). Пустой день — disabled «Нет задач с временем». Второго 44pt menu bar над сеткой нет. R1/R2 collapse/adaptive/scroll/grid-identity contracts сохранены (проверено: expand/collapse, смена дня — collapsed-дефолт без фиктивного toggle при 2 задачах).

## Наблюдения (честно, в рамках scope)

- **Адаптивная шапка.** С добавлением «⋯» (min 44pt) один ряд контролов на iPhone 17 Pro (402pt) перестал помещаться (~435pt нужна); ViewThatFits переносит «Сегодня»+«⋯» на вторую компактную строку — это разрешённый TASK вариант «native адаптивное размещение в компактной верхней строке, без возвращения large title». На более широких устройствах ряд остаётся одним (spacing/padding подтянуты 12→8). `dayControlsReserve` актуализирован 64→104, чтобы ceiling expanded-viewport честно учитывал двухстрочный вариант.
- **Формат pill даты.** Compact DatePicker под ru_RU в зависимости от предложенной ViewThatFits ширины рендерит «14 окт. 2026 г.» либо числовой «14.10.2026» (оба русские форматы системного стиля); locale-код не менялся. Заметка для review — поведение самого DatePicker, не новая логика.
- AX-hint блока сетки обновлён на ссылку на новое меню (старый текст ссылался на удалённую панель) — единственная правка в DayTimelineView помимо удаления панели.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild -project OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n7c-r3-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR), дважды (после плотностного фикса) | exit 0, **BUILD SUCCEEDED** |
| Core `swift test` / web / legacy / full suites | НЕ повторялись — core не менялся (по TASK) |
| Fixture | временный macOS-генератор, слинкованный с OrbitCore (`swift build` + `swiftc -parse-as-library`, Package.swift не менялся); даты через `TaskDaySelection.currentDay()` → today=2026-10-14; 12 untimed + 1 timed (09:00/60) + tiny/dense («Мини 1» 11:05/5, «Мини 2» 11:07/4 — перекрытие в 2 lane, «Мини 3» 23:55/5, конец ровно в 24:00) на today, 2 untimed на 15 Oct, 1 undated; 19 задач; store положен в песочницу приложения до первого launch; генератор удалён |
| Simulator | собственный `orbit-n7c-r3-gui` (iPhone 17 Pro, iOS 27.0, UDID A4C54875-1F89-4592-8C9F-3DA598812FF0): создан/booted/deleted мной; после плотностного фикса app переустановлен в тот же контейнер (store сохранён) |
| Ввод | Device Hub (`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`, Xcode 27): AX-дерево iOS-приложения зеркалится в macOS — клики шли по элементам AX; координатный клик только для таб-бара (табы не отражены в AX) |

## GUI evidence реального запуска

Скриншоты — `xcrun simctl io screenshot` (пиксели устройства), каталог `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/r3/`:

1. `01-collapsed-dense.png` — collapsed: ровно 3 капсулы плотной группой (зазор ~2pt), круг ВНУТРИ каждой капсулы слева от title, «Ещё 9»; большой панели «Задачи с временем» НЕТ — сетка начинается сразу после разделителя и занимает бо́льшую часть экрана (08:00–14:00+ и блок 09:00–10:00 видимы); «⋯» в шапке.
2. `02-chip-completed.png` — после клика по кругу «Без времени 1»: круг заполнен coral с галочкой, title приглушён, позиция задачи не изменилась; AX-метка сменилась на «Снова открыть: Без времени 1». Повторный клик вернул открытое состояние (AX подтверждён).
3. `03-title-tap-date-sheet.png` — tap по title «Без времени 2»: существующий sheet «Дата задачи / Без времени 2», колесо на 14 October 2026 (правильный source); «Отмена» закрыла без записи (экран/AX без изменений).
4. `04-day-tasks-menu.png` — «⋯» → «Задачи дня»: все 4 реальных TIMED сегмента дня с полными названиями и диапазонами (включая tiny 11:05–11:10 и 23:55–24:00).
5. `05-tiny-interval-editor.png` — «Мини 1 · 11:05–11:10» → «Редактировать время…»: существующий «Время задачи / Мини 1» с фактическими значениями Начало=11:05, Длительность=5 (AX-значения полей подтверждены); «Отмена» закрыла без записи.
6. `06-expanded-bounded.png` — «Ещё 9»: bounded region (5 видимых строк + «Свернуть» ниже), шапка/меню/сетка остаются видимы; AX содержит все 12 строк.
7. `07-day-switch-collapsed.png` — «Следующий день»: 15 Oct, collapsed-дефолт, «Сосед 1/2», без фиктивного toggle; возврат «Сегодня» — collapsed по умолчанию.
8. `08-dynamic-type-axl.png` — content size accessibility-extra-large: «Сегодня»+«⋯» на своей строке, все контролы и строки доступны (AX: menu/today/prev/more/rows/grid = true), капсулы выросли со шрифтом; после smoke размер возвращён на `large`.

**sqlite readonly до/после всей сессии** (`store-before.txt`/`store-after.txt` в r3/): 19 строк идентичны — complete был возвращён reopen'ом, оба Cancel не пишут, collapse/expand/смена дня/меню/ Dynamic Type не пишут store.

## UNVERIFIED (честно)

- **Внутренний scroll expanded-региона до 12-й строки** — как в R1/R2: pan-жесты зеркалом Device Hub не доставляются; факты: region ограничена (06: 5 из 12 при «Свернуть» ниже), это нативный ScrollView, AX содержит все 12 строк. UNVERIFIED пиксельно.
- **Context menu карточки (long-press)** и **grid offset при toggle на прокрученной сетке** — как в R1/R2 UNVERIFIED (жесты не доставляются); source не содержит условий на collapse у timeline, context menu не менялся.
- Grid-скролл-контракт (отсутствие сброса offset при toggle) — source-уровень + визуальная идентичность до/после; пиксельная проверка на прокрученной сетке невозможна без pan (как в R1/R2).
- Реальный iPhone, тёмная тема, RTL, VoiceOver-сессия, SE-класс/landscape — не проверялись.

## Ограничения / гигиена

- Один scoped commit поверх R2; `git diff --check` чисто; без merge/push/amend/rebase/reset/stash/deploy.
- main/чужие worktrees/CRM/порт 3000/hooks/device settings/xcode-select/signing/Apple ID не трогались; системная locale/content size устройства не менялись (content size возвращён на large, ephemeral simulator удалён).
- Cleanup: свой simulator удалён, `/tmp/orbit-n7c-r3-*` (DerivedData, генератор, store-копии) удалены, Device Hub закрыт; outputs R1/R2 не тронуты.
- Stop: Codex cumulative review R1+R2+R3; drag/resize/3-дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-007C`; R3 start `5804d9e352544f6bf717855e16d13b042be18142` (full SHA R2); полный SHA итогового коммита — в чате.

---

# NATIVE-007C-R3 — уточнение IMG_1218/IMG_1219 (прямая визуальная правка текущего R3, не новый TASK)

## Статус

READY_FOR_REVIEW (второй scoped R3-коммит поверх первого R3; итоговый Codex review кумулятивный R1+R2+R3).

## Исходное состояние

- Ветка `task/NATIVE-007C`; **start = full SHA первого R3-коммита `ea4dfd30842723f66e2bd6b93bba493488207773`**; `git status --porcelain` перед началом пустой. Предыдущие коммиты не переписывались.
- Прочитаны последняя секция `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C-R3.md` («Последнее прямое уточнение пользователя — IMG_1218/IMG_1219»), сами reference-изображения и свой R3-отчёт выше.

## Изменённые файлы

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/CompactCalendarTaskRow.swift` | вместо Capsule — короткий tinted `RoundedRectangle(cornerRadius: 7)`; визуальная высота ≈26pt (title .subheadline 15pt + vertical padding 3, БЕЗ minHeight-44 и без любых flexible/infinity frames — рост только от Dynamic Type); completion-круг 13pt (галочка 7pt) внутри слева; hit regions круга и title ограничены своим рядом, соседние ряды (зазор 2pt) не перекрываются; completed по-прежнему muted; AX/context menu без изменений |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` | untimed-область перестроена: левая gutter-колонка `untimedGridLeading = 56` (= lane inset сетки — левый край карточек совпадает с task-областью grid); toggle — маленькие paired chevrons (`chevron.up.chevron.down`, 11pt, поворот 180° в expanded) нативной Button в gutter над часовой линейкой, 44×44 hit полностью внутри gutter (не перекрывает карточки справа), AX «Показать ещё N / Свернуть без времени», identifier `untimed-toggle`; прежняя centered button-панель «Ещё N/Свернуть» удалена; «Ещё N» при collapsed — мелкая secondary подпись (.footnote) под карточками по их левому краю (не кнопка, единственный toggle — chevron); при ≤3 задач ни toggle, ни подписи; `estimatedCompactRowHeight` 46→28 (26+2), `toggleReserve` удалён (gutter-toggle не занимает вертикальный бюджет), expanded viewport cap упрощён; ellipsis-меню у даты не тронуто (другой control); default 3/bounded internal scroll/`.id(selectedDay)`/grid identity сохранены |
| `apple/OrbitIOS/README.md` | секция Calendar Day под уточнение IMG_1218/1219 |
| `reports/NATIVE-007C-executor.md` | эта секция |

Не менялись: DayTimelineView (grid/ruler/paint/lanes/tap — совсем), core/model/store, editors, Today/Inbox/shared rows, Xcode project, tests, root docs.

## Соответствие уточнению

1. **Карточки ниже:** ≈24–26pt в обычном размере (цель 24–28), cornerRadius 7 (6–8), круг 13pt (12–14), font .subheadline = 15pt (14–15). Рост только content-derived (Dynamic Type), infinity/spacers убраны полностью — «pillow»-рядов нет. Соседние hit targets не перекрываются (каждый ряд — своя 26pt+ полоса, зазор 2).
2. **Toggle влево:** paired chevrons в левой gutter-колонке (x 0–56, как колонка часовой шкалы), вертикально у первых рядов, над ruler; один native Button, hit 44×44 в gutter; в expanded те же chevrons сворачивают (поворот 180°), internal scroll сохранён. «Ещё N» — компактная secondary подпись под карточками по левому краю (в expanded скрыта). При ≤3 — ни toggle, ни подписи. Ellipsis у даты — отдельный control, не переносился.
3. **Сохранено:** default 3, bounded expanded viewport (~⅓, от измеренной высоты; резервы актуализированы — toggle больше не съедает вертикаль), source UUID/mutations через существующие callbacks, grid identity/scroll (DayTimelineView не менялся), свёрнутое состояние при смене дня.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild … -derivedDataPath /tmp/orbit-n7c-r3b-dd CODE_SIGNING_ALLOWED=NO build` (DEVELOPER_DIR) | exit 0, **BUILD SUCCEEDED** |
| Core/web/full suites | НЕ повторялись (core не менялся) |
| Fixture/симулятор | заново (прежние удалены при R3-cleanup): генератор на OrbitCore, today=2026-10-14, те же 19 задач (12 untimed + 4 timed вкл. tiny/dense + 2 соседних + 1 undated); свой `orbit-n7c-r3b-gui` iPhone 17 Pro / iOS 27.0 UDID 55AE4A5A-3149-4DF6-BE62-A39134A9CB6B, создан/deleted мной |
| Ввод | Device Hub, AX-элементы (gutter toggle кликался как «Показать ещё 9 без времени» / «Свернуть без времени») |

## GUI evidence (скриншоты в `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007C/r3/`)

1. `09-refined-collapsed-gutter-toggle.png` — collapsed: 3 компактные карточки (~26pt, radius 7, круг 13 внутри), paired chevrons слева в gutter напротив первых рядов над линейкой, «Ещё 9» мелкой подписью под карточками по левому краю, левый край карточек = task-область сетки; НЕТ centered button-панели; сетка с блоком 09:00–10:00 и tiny-полосами занимает большую часть экрана.
2. `10-refined-expanded-gutter-toggle.png` — expanded через gutter-chevron: bounded region с 9 видимыми компактными карточками (AX — все 12), caption скрыта, chevron перешёл в «Свернуть без времени», шапка/меню/сетка видимы; повторный клик свернул (AX подтвердил возврат toggle и подписи).

**sqlite readonly до/после** (`store-before-r3b.txt`/`store-after-r3b.txt`): 19 строк идентичны — toggle/expand/collapse не пишут store.

## UNVERIFIED (честно)

- Внутренний scroll expanded-региона и «нет сброса grid offset на прокрученной сетке» — как прежде UNVERIFIED пиксельно (pan-жесты зеркалом не доставляются; source контрактов не менялся: тот же bounded ScrollView + `.id(selectedDay)`, DayTimelineView без изменений).
- Dynamic Type smoke в этом проходе не повторялся (карточки растут контентно — механика прежних прогонов; отдельный AXL-скриншот не снимался).
- Реальный iPhone, тёмная тема, RTL, VoiceOver, SE-класс — не проверялись.

## Ограничения / гигиена

- Один scoped commit поверх первого R3; `git diff --check` чисто; без merge/push/amend/rebase/reset/stash/deploy; чужие ресурсы/settings не трогались.
- Cleanup: свой simulator удалён, `/tmp/orbit-n7c-r3b-*` удалены, Device Hub закрыт; outputs R1/R2/первого R3 не тронуты.
- Stop: Codex cumulative review R1+R2+R3; drag/resize/3-дня/Месяц/AI не начинались.

## Git

- Ветка `task/NATIVE-007C`; start `ea4dfd30842723f66e2bd6b93bba493488207773`; полный SHA итогового коммита — в чате.
