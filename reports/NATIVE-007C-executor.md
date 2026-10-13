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
