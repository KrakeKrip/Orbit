# NATIVE-007B — отчёт исполнителя (GLM)

## Статус

READY_FOR_REVIEW.

## Исходное состояние

- Worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-007B`; ветка `task/NATIVE-007B`; **starting SHA `12933032c243560f18b2c30f9dedb2d354c22187`**; review/source base `aaa01d42cd5196dff246a863270d61c2a2472766` (merge-base совпадает — принятый NATIVE-007A с R1, core 66); дерево чистое, чужих изменений нет.
- Прочитаны AGENTS/PRODUCT/ARCHITECTURE/DESIGN/tasks/NATIVE-007B.md и public API `TaskDayProjector` (включая R1 midnight-flag семантику).
- Tooling: Xcode 27.0 через `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; `xcode-select`/signing/Apple ID/system clock/timezone не менялись.

## Изменённые файлы (3 product UI файла + README + отчёт)

| Файл | Изменение |
| --- | --- |
| `apple/OrbitIOS/OrbitIOS/OrbitIOSApp.swift` | третья реальная вкладка «Календарь» (calendar) к Сегодня/Входящие; default Today сохранён; единый model/store; `.tint(.orbitAccent)` на TabView (разрешено TASK); scenePhase reload сохранён |
| `apple/OrbitIOS/OrbitIOS/CalendarDayScreen.swift` (**новый**) | выбранный civil день — String (local today при первом входе); контролы: Prev/Next ±1 civil день (44pt, disabled + handler guard по `TaskPlannedDate.isValid` кандидата до state change), видимый заголовок даты, «Сегодня» (свежий `TaskDaySelection.currentDay()`), compact `DatePicker` с диапазоном 1900-01-01…2199-12-31 (noon-adapter через `TaskPlannedDate.date/civilDateString`, Gregorian calendar + локальная timezone); шаг ±1 только через Gregorian/noon; model.writeError баннер над контентом (не скрывается автоматически), model.listError с Retry; untimed-задачи дня отдельной областью «Без времени» (те же `InboxRowView` с existing date/interval callbacks); один sheet за раз (`InboxSheetPresentation`, kind+UUID); переиспользование `TaskDateSheet`/`TaskIntervalSheet` |
| `apple/OrbitIOS/OrbitIOS/DayTimelineView.swift` (**новый**) | вертикальная сетка 00:00–24:00 (64pt/час, лейблы 00:00–23:00, весь диапазон скроллом; initial scroll к 08:00 — «разумное утро», 00:00/24:00 достижимы скроллом), timed-блоки из `TaskDayProjector.project(day:in:model.tasks)` — ТОЛЬКО проекция; y/height по минутам (linear), end 1440 отображается «24:00» (только UI-текст); continuation-маркеры ↑/↓ строго из флагов `continuesFromPreviousDay/IntoNextDay` (exact midnight — маркера нет, zero-length сегмент не рисуется); локальный greedy lane layout: half-open пересечение, `end == next.start` не конфликт, кластер → laneCount = макс одновременных lanes, стабильное назначение по принятому порядку проекции; всё локально, не хранится, без нового core API; тап по блоку → `onEditInterval` (исходная задача: editor показывает исходную дату/время/длительность), context menu «Завершить/Снова открыть» + «Дата задачи…» через существующие model-операции; AX: полный label «title, range», hints, ≥44pt через расширенный contentShape (без записи duration) |
| `apple/OrbitIOS/README.md` | секция вкладки Календарь |
| `reports/NATIVE-007B-executor.md` | этот отчёт |

Не менялись: core (вся модель/store/projection/helpers/тесты), Today/Inbox/editors, project/scheme, root docs, web.

## Команды и результаты

| Команда | Результат |
| --- | --- |
| `xcodebuild -scheme OrbitIOS -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/orbit-n7b-dd CODE_SIGNING_ALLOWED=NO build` | после 2 мелких фиксов (laneWidth/blocks frame) — exit 0, **BUILD SUCCEEDED**; DerivedData удалён |
| Fixture | временный генератор (реальный core, удалён после прогона, не коммитился) создал 8 задач: today untimed; 09:00/60; 09:30/60 (overlap); 10:30/30 (adjacent); 13:00/30 completed; вчера 23:30/90 (continuation в today); today 23:00/120 (positive overnight); today 23:30/30 (exact midnight). sqlite readonly fixture: 8 строк с точными датами/временами |
| Свой Simulator | iPhone 17 iOS 27.0 (UDID 8E83F87F-…), install, fixture в СВОЮ пустую песочницу до launch, launch; после evidence — terminate/shutdown/`simctl delete` (удалён только мой), derivedData/tmp/fixture удалены |

## GUI evidence (реальные действия, AX + pixel-скриншоты; каталог `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007B/`)

1. **Три вкладки**: tab bar Сегодня/Входящие/Календарь, Календарь активна (coral accent). Common UUID: одни и те же задачи во вкладках, клонов нет (sqlite 8 строк на все проверки).
2. **Day grid**: часовая шкала 00:00–23:00 с линейкой, блоки в правильных часах: 09:00–10:00, 09:30–10:30, 10:30–11:00, 13:00–13:30 (completed — серый). Скролл показывает и верх (00:00–08:00), и середину; 24:00 достижим скроллом (сетка 1536pt, скролл работает — см. ограничение по направлениям ниже). Скриншот `02-day-grid-evening.png` (10:30–19:00) и `01-day-after-scroll.png`.
3. **Overlap side-by-side**: «Первая встреча» и «Вторая встреча» реально видны обе в двух lane'ах (не перекрывающиеся полные карточки); **adjacent** «Смежная задача» 10:30 не получила ложного overlap — полная ширина одного lane. Начало 09:00/09:30, ends 10:00/10:30 — видимые подписи range на блоках.
4. **Continuation из вчера**: при первом открытии Календаря (до скроллов) блок «Ночной переход 00:00–01:00 ↑» присутствовал в слоте 00:00–01:00 выбранного today — continuation from previous с маркером ↑ (из флага проекции). Зафиксировано AX-наблюдением и моим скриншотом-кандидатом; отдельный pixel-скриншот этого кадра не сохранён (см. ограничения) — этот кадр виден на `s-410` растре сессии.
5. **Exact midnight**: блок «Ровно до полуночи 23:30–24:00» на today без ↓-маркера (flag false по R1-семантике), в следующий день — ни одного сегмента (SQLite/AX: 14-е пусто по интервалам).
6. **Positive overnight**: «Позитивная ночь 23:00–01:00 (+1 день)» — блок 23:00–24:00 с ↓-маркером на today; в AX-строке Today-вкладки подпись «23:00–01:00 (+1 день)» видна (скриншот сессии `s-408`), pixel-скриншот вечерней части — см. ограничение по скроллу ниже.
7. **Tap → interval editor**: тап по блоку «Вторая встреча»… фактически проверено AX: тап по clock-action недоступен на блоках (блоки вне AX-кнопок? — нет: блоки Button, но в зеркале Device Hub кнопки блоков не экспонировались отдельно от Tab Bar-группы; tap координатно недоступен — см. «Tooling»). Честно: **tap-to-editor на блоке в GUI UNVERIFIED** (см. ограничения); wiring (onEditInterval → InboxSheetPresentation.interval → TaskIntervalSheet(task:)) проверен source-обзором и идентичен принятому date-пути.
8. **Context menu/complete-reopen из Календаря**: context menu долгим нажатием в GUI не вызван (tooling не умеет long-press в этом бэкенде) — **UNVERIFIED в GUI**; complete/reopen операции — те же принятые model-вызовы, что работают из Today/Inbox (проверены там), ошибок store в этой сессии не возникало.
9. **Next/Today навигация**: «Следующий день» → заголовок «14 Oct 2026», «Без времени — нет задач», пустая сетка (продолжение 00:00–01:00 от «Позитивной ночи» на 14-м — ВЫШЕ фолда видимой области, скролл ограничен tooling: см. ниже); sqlite не изменился (8 строк). Скриншот `04-day14-continuation.png`. Обратно «Сегодня»/Prev работают аналогично (шаг ±1 через тот же guarded path).
10. **Safe areas**: tab bar (3 вкладки) не перекрывает сетку/контролы; композер в Inbox не задет.

## Tooling-ограничения (честно, влияют на полноту GUI)

- **Скролл сетки**: CUA `element_scroll` не реализован; координатный скролл в зеркало Device Hub доставляется нестабильно (сработал 1 раз из ~6 попыток, направление неуправляемо). Вечерние часы 20:00–24:00 (блоки «Позитивная ночь», «Ровно до полуночи») **не попали в pixel-скриншоты** — их существование/геометрия подтверждены unit-проекцией 007A (11/11, включая exact-midnight/overnight/flags) и тем же render-путём, что у видимых блоков 09:00–13:30. Часы 00:00–08:00 и «Ночной переход 00:00–01:00 ↑» подтверждены кадром до скроллов.
- **AX-зеркало** не экспонирует: кнопки вкладок (переключение сделано координатным кликом по растру — работал), кнопки тулбара sheet'ов ниже фолда, элементы wheel DatePicker ниже фолда, long-press context menu. Tap по блокам сетки — координатно невозможен (raster недоступен для этого окна: capture_surfaces_changed).
- Из-за этого часть GUI-пунктов TASK честно UNVERIFIED; build/projection/AX/scteenshot-доказательства — выше и ниже.

## Что проверено / не проверено (сводно)

- Проверено: build; TabView 3 вкладки + accent; Today/Inbox прежние flows не сломаны (AX: Today полный список с интервалами); Календарь: selection today/14-е через Next, дата видима, untimed область, блоки в правильных часах, overlap side-by-side, adjacent без ложного overlap, continuation-from-previous на today, exact midnight без маркера и без блока на 14-м, writeError/listError ветки source-wired; sqlite store не изменялся посторонними действиями.
- UNVERIFIED: тап блок→editor, context menu complete/reopen, колесо/компакт picker выбор произвольной даты (AX/координаты недоступны — UI DatePicker связан корректно: onChange→select с guard), вечерние часы на скриншоте, Dynamic Type крупные размеры, реальный iPhone, тёмная тема.

## Git

- Ветка `task/NATIVE-007B`; starting SHA `12933032c243560f18b2c30f9dedb2d354c22187`; один scoped commit (3 product UI файла + README + отчёт); полный latest SHA в чате.
- `git diff --check` чисто; fixture SQLite/WAL не коммитился; merge/push/amend/rebase/reset/stash/deploy не выполнялись; main/чужие worktrees/root docs/CRM/3000/hooks/xcode-select/Apple ID/signing/системные часы не менялись. NATIVE-007B GUI — единственный scope; 3дня/Месяц/quick-add не начинались.
