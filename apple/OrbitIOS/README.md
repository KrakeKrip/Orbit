# Orbit — iOS Inbox (NATIVE-002/003/004/005)

Один экран «Входящие» для iPhone (Todoist-настроение: крупный системный заголовок,
компактные строки с круглым контролем завершения слева, спокойный системный фон,
один сдержанный coral/red accent у главного действия). Локальное SwiftData
хранилище в собственной песочнице приложения через закоммиченный пакет
`apple/Orbit` (product `OrbitCore`). Без сервера, аккаунтов, синхронизации,
CloudKit (`cloudKitDatabase: .none` уже в core), без новых зависимостей.

## Структура

- `OrbitIOS.xcodeproj` — минимальный handwritten-проект (objectVersion 70,
  `PBXFileSystemSynchronizedRootGroup` для папки `OrbitIOS`, локальная package
  reference `../Orbit`, shared scheme `OrbitIOS`). Без project generators.
- `OrbitIOS/OrbitIOSApp.swift` — app entry: открытие store при старте,
  явное состояние ошибки хранилища (без удаления файла и без in-memory fallback).
- `OrbitIOS/IOSStore.swift` — единственный URL хранилища внутри sandbox:
  `Application Support/Orbit/store.sqlite` (каталог создаётся перед открытием).
  macOS CLI resolver (`OrbitStoreLocation.resolveStoreURL`) на iOS не вызывается,
  launch-override не принимается.
- `OrbitIOS/IOSInboxModel.swift` — `@MainActor @Observable` состояние экрана:
  операции через OrbitCore (валидация/список/complete/reopen/plannedDate/
  setPlannedInterval), успех только после явного `save()`, при ошибке draft
  сохраняется.
- `OrbitIOS/TodayWorkspaceScreen.swift` — контейнер раздела «Сегодня»
  (NATIVE-NAV-001): единственный owner текущего локального Gregorian дня
  (пересчёт на appear/active/не реже раза в минуту; при смене дня reload
  общей модели — оба вида обновляются вместе) и compact native
  переключатель «Список / Календарь» (segmented, identifier
  `today-mode-switcher`). Выбранный вид — presentation-состояние:
  сохраняется при Today → Входящие → Today в рамках сессии, никогда не
  пишет задачи и не создаёт копий; оба вида работают над одним
  `IOSInboxModel`/store.
- `OrbitIOS/UpcomingWorkspaceScreen.swift` — контейнер раздела
  «Предстоящее» (NATIVE-NAV-002, третья нижняя вкладка; отдельной вкладки
  «Календарь» нет): единственный owner выбранного civil дня (старт —
  локальный Gregorian today) и вида «Список / Календарь» (старт — Список,
  identifier `upcoming-mode-switcher`). День и вид независимы от Today,
  сохраняются при переключениях вкладок и видов в рамках сессии (не пишутся
  в tasks/store/UserDefaults), reload модели на appear/active их не
  сбрасывает; оба вида — sibling-экраны над тем же `IOSInboxModel`, без
  nested NavigationStack. С NAV-002-R1 здесь же живёт обновляемый reference
  текущего локального дня (appear/scene active/лёгкий таймер ~30с), который
  делает кнопку «Сегодня» контекстной; обновление reference никогда не
  сбрасывает ручной выбор и вид.
- `OrbitIOS/UpcomingListScreen.swift` — список «Предстоящее»
  (NATIVE-NAV-002): inclusive-окно 7 дней от выбранного дня (арифметика
  только через принятые Gregorian/noon-адаптеры с явным календарём),
  задачи сгруппированы по своей valid plannedDate большими существующими
  строками `InboxRowView` — open и completed остаются в своей дневной
  группе в порядке модели, без новых list-правил; undated/невалидные вне
  окна. На верхней границе 2199-12-31 окно обрезается до последней валидной
  даты, caption показывает фактический диапазон по-русски. NATIVE-UI-MODE:
  компактная верхняя mode-строка (`NativeModeHeader` с существующим
  `UpcomingModeSwitcher`, identifier `upcoming-mode-switcher`) сразу под
  navigation bar (заголовок inline — mode-строка не зависит от высоты
  заголовка), под ней прежние date controls (Prev/Next/picker);
  «Сегодня» —
  контекстная (NAV-002-R1): видна только когда выбранный день отличается
  от текущего локального, после jump/ручного выбора today исчезает без
  резерва пустой строки, при нажатии пересчитывает current day; честный
  empty state «В выбранном диапазоне задач нет» с доступными контролами;
  те же editor sheets и `writeError`-баннер.
- `OrbitIOS/TodayScreen.swift` — список «Сегодня» (NATIVE-006/NAV-001):
  read-only срез задач на день из входа `day` через `TaskDaySelection`;
  те же строки/actions/editors, что в Inbox (complete/reopen, date/interval
  editors); заголовок «Сегодня» + видимая локальная дата; NATIVE-UI-MODE:
  переключатель «Список / Календарь» в общей верхней mode-строке
  (`NativeModeHeader` с существующим `TodayModeSwitcher`, identifier
  `today-mode-switcher`) сразу под navigation bar — то же место/insets/
  высота, что в календарном виде, без toolbar-обёртки и двойного контура
  (заголовок inline, чтобы mode-строка не зависела от высоты заголовка);
  честный empty state «На сегодня
  задач нет» с действием «Добавить во Входящих» (переключает на живую
  вкладку, не создаёт задачу). Без сетки/overdue/quick-add. Дата-подпись
  раздела — по-русски через view-local `RussianDateCaption` (NAV-002 P3:
  явный ru_RU/Gregorian форматтер в CalendarDayScreen.swift; системная
  locale не меняется, `InboxRowView` не тронут — подписи дат внутри строк
  остаются системными).
- `OrbitIOS/NativeModeHeader.swift` — NATIVE-UI-MODE: одна общая
  композиция верхней mode-строки для всех четырёх листовых видов
  (Today/Upcoming × Список/Календарь): существующий segmented switcher
  раздела ведущим в одной top-строке с теми же insets (8/6), высотой
  (44pt минимум контрола) и `.bar`-фоном, что и календарные date controls,
  сразу под navigation bar; опциональный trailing (в списках пусто) не
  смещает контрол; никакого toolbar item/второго контура вокруг
  segmented control. В календарных видах ту же строку образуют
  существующие day controls, а browsing-контекст переиспользует
  `UpcomingModeSwitcher` (по одному определению контрола на раздел, без
  дублирующих `Picker` на экране). Binding — прежний workspace mode,
  состояние presentation-only.
- `OrbitIOS/CalendarDayScreen.swift` + `OrbitIOS/DayTimelineView.swift` +
  `OrbitIOS/CompactCalendarTaskRow.swift` — календарный вид дня
  (NATIVE-007B/007C/007C-R2/007C-R3/NAV-001/NAV-002), переиспользуется в двух
  контекстах: fixed-day внутри «Сегодня» (`fixedDay` != nil) — компактная
  шапка с русским caption текущего дня, переключателем «Список /
  Календарь» и «⋯» меню, БЕЗ Prev/Next/picker/«Сегодня»; browsing-контекст
  «Предстоящего» (`browsingDay` != nil, NAV-002) — владелец дня внешний:
  Prev/Next ±1 день с guard 1900–2199, «Сегодня», compact DatePicker с
  view-local ru_RU locale (системная locale не меняется), переключатель
  «Список / Календарь» раздела (identifier `upcoming-mode-switcher`) и
  native «⋯» меню («Меню календаря», hit ≥44pt) пишут через binding
  владельца — экран не держит второго owner выбора дня (write-through с
  no-op-защитой от feedback loops, пикер следует за днём); с NAV-002-R1
  browsing-шапка сгруппирована в компактные ряды, которые помещаются в
  viewport (mode+«⋯» сверху, дата/arrows ниже, контекстная «Сегодня» —
  только когда выбранный день не равен reference current day, без резерва
  строки и без clipping/offset-маскировки), fixed-day контекст без jump;
  при стандартном шрифте ряд может не помещаться — `ViewThatFits` переносит
  «Сегодня» + «⋯» на вторую компактную строку, без возвращения large title.
  «⋯» содержит «Задачи дня» — реальные TIMED сегменты выбранного дня
  (полное source-название + диапазон с маркерами ↑/↓) с существующими
  interval/date/complete-reopen действиями; при отсутствии сегментов —
  честная disabled-строка «Нет задач с временем», без fake actions. Это
  единственный доступный путь к tiny/dense блокам — отдельная панель над
  сеткой удалена (007C-R3); untimed-задачи отдельной **collapsible областью
  «Без времени»** из компактных карточек (007C-R3 + уточнение IMG_1218/1219:
  короткий tinted rounded rectangle ~26pt с cornerRadius 7, completion-круг
  ~13pt внутри слева от однострочного title .subheadline с tail truncation
  (полный title в AX), высота content-derived без flexible spacers, hit
  regions соседних рядов не перекрываются, Dynamic Type растит карточку;
  плотная группа с 2pt-зазорами, левый край карточек совпадает с task-областью
  сетки (56pt); toggle раскрытия — маленькие paired chevrons нативной кнопкой
  в левой gutter-колонке над часовой линейкой (44×44 hit внутри gutter, AX
  «Показать ещё N / Свернуть без времени», identifier untimed-toggle), «Ещё N»
  при collapsed — мелкая secondary подпись под карточками по их левому краю,
  без отдельной button-панели; при ≤3 задач toggle/подписи нет; tap по title —
  существующий date sheet, context menu — дата/время/complete через
  существующие callbacks)
  (NATIVE-007C: default до 3 chips + «Ещё N», раскрытие в adaptive bounded
  scroll — viewport ~⅓ измеренной высоты content area с резервом
  date controls/toggle/сетки, короткие списки не оставляют пустой области,
  «Свернуть», сброс только untimed-скролла при смене дня);
  ниже — сетка 00:00–24:00 (64pt/час, initial scroll
  к 08:00) с timed-блоками из `TaskDayProjector.project`: side-by-side
  overlap через локальный greedy lane layout (touching segments не
  конфликтуют), continuation-маркеры ↑/↓ из флагов проекции (exact midnight
  — без маркера), end 1440 отображается как 24:00 (только UI). Тап по
  блоку — существующий interval editor исходной задачи; context menu —
  существующие complete/reopen и date-операции. Без 3 дней/Месяца/drag/
  quick-add; создание остаётся в Inbox.
- `OrbitIOS/InboxScreen.swift` — экран: NavigationStack large title «Входящие»,
  секции «Открытые»/«Завершённые», круглый completion-контроль ≥44pt с a11y
  label «действие: задача» (никогда не открывает меню), перенос длинных
  названий, композер в нижнем safe area (клавиатура его поднимает),
  inline-ошибка, честный empty state; один editor за раз (presentation
  kind+UUID). Строки NATIVE-LIST-001: постоянных clock/calendar иконок нет —
  тело строки (title+метаданные, полный source title в AX) открывает
  компактное native меню «Дата…» / «Время и длительность…» через
  существующие editor callbacks; у undated-задачи время disabled с подписью
  «сначала назначьте дату» (today молча не ставится); ряды ниже за счёт
  вертикального padding; подпись даты — по-русски через `RussianDateCaption`
  (флаг `showsDateLabel`: Inbox true, Today/дневные секции Upcoming false —
  там дата уже в заголовке секции), подпись времени start–end/(+1 день)
  сохраняется; `InboxRowView.dateLabel` остан для caption редактора.
- `OrbitIOS/TaskDateSheet.swift` — маленький редактор даты (NATIVE-003):
  native wheel `DatePicker`, draft по умолчанию — сегодняшний local civil день,
  явные «Сохранить»/«Отмена» (открытие/отмена ничего не пишут), «Убрать дату»
  для назначенной; отказ показывает ошибку и оставляет редактор для retry.
- `OrbitIOS/TaskIntervalSheet.swift` — редактор времени/длительности
  (NATIVE-005/TIME-WHEEL): компактные tappable summary rows «Начало» и
  «Длительность»; тап раскрывает нативные wheel-колёсики (максимум одна
  группа за раз). Начало — часы 0…23 и минуты 00…59 (civil wall-clock
  компоненты, без date→instant/DST пути; минуты старта не ограничены
  шагом 5). Длительность — часы 0…24 и минутное колесо ТОЛЬКО
  0/5/10/…/55 (пользовательский шаг для новых выборов); 00 ч 00 и
  24 ч 05+ запрещают «Сохранить» с коротким hint (core — финальная
  валидация). Legacy-значения вне сетки (1…4, 6, 7, 61…) показываются
  точной readable подписью «N мин — сохранено» с пояснением, не
  нормализуются и не скрываются; колёсики вступают в силу только после
  явного движения пользователя, «Отмена» сохраняет старые значения.
  Readonly «Закончится в ЧЧ:ММ» / «… (+1 день)» — из принятого
  `TaskTimeInterval.end`, не сохраняется. Дата — по-русски через
  `RussianDateCaption`. Открытие/раскрытие/swipe/«Отмена» не пишут;
  Save передаёт пару целиком в существующий `model.setPlannedInterval`,
  отказ показывает существующую ошибку и сохраняет draft.

## Дата и время задачи (NATIVE-003/004/005)

`plannedDate` — nullable civil строка `YYYY-MM-DD` (Gregorian 1900–2199,
валидация `TaskPlannedDate`, store-операция `setPlannedDate` с явным save и
rollback, невалидное значение отвергается до мутации). Дата не превращается в
UTC instant и не зависит от timezone; `Date` — только UI adapter `DatePicker`.
Назначение даты не скрывает задачу и не меняет порядок списка (Today/календарь
— будущие TASK). Старые stores обновляются лёгкой миграцией optional-поля:
прежние строки, UUID и completion сохраняются, plannedDate=nil — проверено
upgrade-прогоном на store, созданном принятым кодом NATIVE-002.

## Требования

- Xcode 27.0 через `DEVELOPER_DIR` (системный `xcode-select` не меняется),
  iOS 17+ baseline, Simulator build с `CODE_SIGNING_ALLOWED=NO`,
  bundle id `local.orbit.ios`. Подпись/teams/Apple ID не настраиваются.

## Сборка и запуск

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd apple/OrbitIOS

xcodebuild -project OrbitIOS.xcodeproj -scheme OrbitIOS -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath <own tmp> \
  CODE_SIGNING_ALLOWED=NO build
```

Core-тесты (независимо): `DEVELOPER_DIR=... swift test` в `apple/Orbit`.

## Хранилище

Только внутри собственной песочницы приложения
(`<app container>/Library/Application Support/Orbit/store.sqlite`). Stores Mac и
iPhone независимы; синхронизации нет и не обещается.

## Статус NATIVE-002 (проверено 2026-10-13)

Собрано и проверено на Simulator (Xcode 27.0, iOS 27.0 runtime, iPhone 17,
`CODE_SIGNING_ALLOWED=NO`): add по кнопке «+» и клавиатурному «Готово»,
complete/reopen круглым контролом, terminate→relaunch без reinstall — задачи и
состояния восстанавливаются с диска; blank rejection с видимой ошибкой; длинный
название переносится на несколько строк; Dynamic Type на accessibility-large;
композер не перекрывается клавиатурой. Скриншоты — вне product tree
(пути в `reports/NATIVE-002-executor.md`). Реальный iPhone НЕ ПРОВЕРЕН.

Совместимость OrbitCore с iOS обеспечена разрешённой однострочной заменой
fallback в `apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift`
(`NSHomeDirectory()` вместо `homeDirectoryForCurrentUser`); поведение macOS
не изменено (20/20 core tests).
