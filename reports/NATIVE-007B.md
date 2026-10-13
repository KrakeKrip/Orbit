# NATIVE-007B — независимый review Codex

2026-10-13. Вердикт NEEDS_FIXES — одна bounded layout коррекция двух UI файлов. Product SHA `5d9bcb5deb1b65850430ae295bde71c57ed3bb69`; assignment `12933032c243560f18b2c30f9dedb2d354c22187`; review/source base `aaa01d42cd5196dff246a863270d61c2a2472766`. Clean tree/cumulative diff check PASS; ровно3product UI файла + README/executor report. Core/schema/store/accepted editors не менялись.

## Независимые проверки

- Прочитаны все sources/report/TASK, screenshots02-day-grid-evening и04-day14-continuation. Правильно: actual third tab с одним model/store; DayProjector reuse; source-task callbacks/editors; civil date guarded navigation, existing complete/reopen/date calls, visible list/write errors. Lane assignment корректно использует half-open intersections и transitive clusters, product projection не дублируется. Date selection сохраняется в State; root active reload общий model. Calendar-specific onAppear reload отсутствует — небольшая уборка допустима, существующие model updates уже реактивны.
- Независимый iOS Simulator build на собственных новых DerivedData, DEVELOPER_DIR Xcode27/CODE_SIGNING_ALLOWED=NO: exit0,BUILD SUCCEEDED; только AppIntents metadata warning. Core tests не повторялись, core неизменен.
- Собственный temporary iPhone17 Simulator,21synthetic task из реального core (12untimed +8overlaps09:00/60 +23:30/30). Fixture поставлен только в свою новую пустую app sandbox до launch. Реальный CUA GUI: переключение Today→Calendar; при12untimed на растре виден почти исключительно untimed список, date controls визуально исчезают, timeline сжат у нижнего края. AX ещё содержит controls/tasks, но это не значит, что они доступны обычным касанием. R1 ниже воспроизведён визуально, не только предположен по source.
- Phase2: только own fixture через core.setPlannedDate(nil) снял12untimed dates; app terminated, synthetic store переустановлен в ту же свою песочницу, relaunch. Calendar теперь показывает ruler; timed row09:00 частично видна у низа, правые колонки обрезаны. Отдельный probe извлёк неизменённые blockX/laneWidth methods, подставил explicit viewport402pt вместо UIScreen API:6lanes right416 (overflow14);8lanes right536 (overflow134). Поддержка AX восьми элементов не исправляет их visual clipping.
- CUA координатный scroll/drag не изменил viewport, AX click timed element не открыл editor. Это limitation/UNVERIFIED, не отдельный доказанный callback-дефект. Tap-editor/context menu/вечерние23–24/DynamicType GUI не подтверждены ни Codex, ни executor полностью. Нельзя считать отсутствие карточки на screenshot11–19 доказательством пустого дня: positive overnight fixture на14-м должен иметь00–01 по projector, вне текущего fold. Отчёт исполнителя содержит неоднозначные «пустое14-е» и «24:00 достижимо»; уточнить claims после targeted verification.
- Timeline axis и short-event geometry дополнительно проверены source. UI-ruler создаёт только0..<24, значит отдельного24:00 label нет; scrollTo("hour-08") не совпадает с ids("hour-8"). Небольшие cleanup пункты ниже.

Evidence вне tree: `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007B-review-evidence/` — independent build log, actual core fixture generator/log, extracted width probe/log, текст GUI outcome. CUA raster находится в review-сессии, отдельный PNG Codex не сохранял. Own Simulator shutdown/delete после evidence; чужие устройства/stores/CRM/Colima/3000/hooks не тронуты.

## R1 [P1] — untimed список вытесняет календарь

CalendarDayScreen.swift:34–35, untimedSection149–175: ForEach всех untimed rows в обычном несжимаемом VStack вне ScrollView. При12valid dated untimed задачах высота превышает viewport; пропадают visible date controls и рабочая область timeline. Повторено на своём Simulator, без Dynamic Type увеличения. С ростом обычного списка календарём становится невозможно пользоваться.

Ограничить/прокручивать untimed область либо включить её в корректную единую scroll композицию. Все untimed задачи остаются доступны, date controls/сетка не теряются. Не создавать store/cache/paging бизнес-логику и не удалять записи. Single/несколько scroll ownership допустимы только без бесконтрольных вложенных ScrollView и без обрезанного контента.

## R2 [P2] — правые overlap колонки недоступны

DayTimelineView.swift:156–162: available ширина берётся от UIScreen, не layout container; max60 на lane приводит к row шире viewport. Для viewport402pt уже6lanes дают416pt,8дают536pt. ScrollView только vertical, offset не даёт доступа к clipped right lanes. Должны отображаться ВСЕ segments, не скрытая часть их списка в AX.

Измерять настоящий container и обеспечить доступный layout для dense overlaps: fit/explicit overflow navigation допустимы, молчаливый clipping/отбрасывание задач нет. Сохранять half-open lane assignment и stable IDs. Не изменять верный projector/sort/интервалы ради fitting. Список действий должен давать доступ к каждой задаче, не рисовать неработающий "ещё".

## R3 [P2] — короткие соседние интервалы визуально накрывают друг друга

DayTimelineView.swift:130–135 задаёт не только hit area, но ЗАКРАШЕННУЮ высоту max(blockHeight,20). При64pt/hour,15min=16pt; соседние09:00–09:15 и09:15–09:30 correctly имеют одну lane, но две20pt карточки перекрываются на4pt. При1minute реальная высота≈1.067pt растягивается до20pt: следующая adjacent task почти полностью накрывает предыдущую. Кроме того, title/range отсутствуют при blockHeight<30/46. Это не расширение hit area, разрешённое TASK, а неверная визуальная duration/потеря читаемости.

Разделить геометрию времени и interaction: actual colored segment показывает реальный интервал; короткие/близкие задачи имеют доступный способ выбора/полный AX title+range/действующие callbacks. Не решать путем изменения duration или удаления short events. Не вводить новую detail-архитектуру, store API или сохраняемые layout fields.

## Маленькая уборка в том же scope

Исправить или явно убрать недействующее initial scroll ID hour-08 (ruler id hour-8). Добавить реальную24:00 boundary подпись, не25-й полный час и не изменение scale. Model.reload на Calendar onAppear допустим при сохранении selectedDay. Эти пункты не требуют отдельных TASK.

Scope/checks — tasks/NATIVE-007B-R1.md. Одна UI layout коррекция двух файлов, core/tests/mutations не менять.007B не принят/не merged;3days/Month/AI/следующий TASK не назначаются. Push/deploy отсутствуют.

## Повторное review layout R1 — PARTIAL / NEEDS_FIXES

2026-10-13, product SHA `fa7e52097182a33f8378e150057d33868b18d594`. Source diff в двух разрешённых UI файлах+report, tree/cumulative diff check PASS. Независимый iOS Simulator build: exit0,BUILD SUCCEEDED. Core unchanged, не повторялся. Screenshot06-r1-12untimed-calendar.png независимо просмотрен. R1 untimed bounded180pt и controls/grid теперь видны; R2 GeometryReader вместо UIScreen,1/2/6/8lanes помещаются — эти две находки закрыты в проверенном source/screenshot scope. Полный scroll всех12untimed и DynamicType GUI в этом раунде Codex не проверял.

Но R3 ещё не закрыт и появилась visibility regression: DayTimelineView.swift:119–124 содержит только RoundedRectangle. Из block label удалены ВСЕ Text(title/range) и видимые continuation arrows, даже для обычного60minute широкого блока. На screenshot вместо задачи видна пустая красная полоса. AccessibilityLabel сохраняет строку, но это не визуальная подпись для обычного пользователя. Прежний TASK требует readable title/range/visible continuation cues.

DayTimelineView.swift:112–115 всё ещё растягивает one-minute geometry до2pt. При64pt/hour1minute=1.066667pt, две adjacent задачи сдвинуты на1.066667pt, но каждая закрашивает2pt: overlap0.933333pt. Изменение floor20→2 уменьшает дефект, не устраняет его. Report «полосы не накрывают друг друга»/«painted height=реальная duration» не соответствует source. Тап/long-press на2pt полосе не является доступным44pt action, AX/source-only не доказывают обычный выбор каждой короткой задачи.

Для viewport402 source сейчас даёт lane widths333/165/53/39 приN1/2/6/8, right389/386/374/368; fit PASS. Report38.5 при402 неточен. Карточки пока соприкасаются без отдельного gutter, что усугубляет чтение одинаковых интервалов; небольшой явный separator/gutter допустим в том же renderer, не новая layout архитектура.

Следующая ОДНА коррекция renderer: вернуть визуальные title/range/continuation для обычных блоков; exact positive paintedHeight без растяжки; добавить доступный native Menu «Задачи с временем» для tiny/dense segments, с полными task names/range и существующими callbacks. Menu >=44pt и только реальные сегменты выбранного дня; никаких новых store/details/controller. Это конкретный способ выбора, предусмотренный исходным R3, вместо повторных обещаний тапнуть2pt. Scope/checks в tasks/NATIVE-007B-R1b.md.

Runtime tap/context/late-hour GUI остаются UNVERIFIED; не считаются новым доказанным callback defect. Этот review новый Simulator не запускал: source и предоставленный raster достаточны для оставшихся rendering findings. R1/R2 повторять/переписывать не нужно, core/data не менять. NATIVE-007B всё ещё не принят/не merged.


## Итоговое review R1b — ACCEPTED, 2026-10-14

Product ba3b3e911c20d73b1e97ac85960b0adab83532ea, correction base16fa7eb. Scope ровно DayTimelineView.swift + executor report, cumulative diff --check чист, дерево чистое. Независимый xcodebuild generic iOS Simulator с CODE_SIGNING_ALLOWED=NO и own DerivedData — BUILD SUCCEEDED, exit0. Core/model/store/projector не менялись, новые core/web/legacy suites не запускались.

R1/R2 bounded untimed/fitting закрыты ранее. R1b: normal blocks имеют visible title/range/positive continuation, внешний frame+clip ограничивает paint; height=(end-start)/60*64, без floor, adjacent1min=1.066667pt без overlap. Menu использует реальные source UUID выбранного дня, native submenus и existing callbacks; disabled пустой. Executor screenshot09 лично просмотрен: реальные пункты/подменю и captions на сетке видимы. Menu→tiny editor подтверждён executor AX evidence, повторного собственного GUI этого раунда не было; исходные own GUI/layout probes есть выше.

Ограничения не скрыты: actual block tap/context long-press/вечерний pixel/real iPhone ещё UNVERIFIED; Cancel в latest подробном отчёте явно не проверялся отдельно, несмотря на более сильную формулировку чата. SQLite unchanged заявлен исполнителем. Старый screenshot02 не доказательство latest renderer. Указание swift50/DayTimelineSelection не является текущим independent full core gate (core unchanged); current helper TaskDaySelection.

Неблокирующая неточность: laneGutter вычитается из width, но blockX шагает на width, поэтому между соседними frames нет гарантированного2pt gutter (видны скругления). Gutter optional в R1b; fit сохраняется: W402,N8→width40,right376<402. Не выдаём новую коррекцию ради косметики: плавная overlap-компоновка будет отдельным утверждённым заданием. Tiny/dense labels могут переноситься/обрезаться; full native menu остаётся доступным.

NATIVE-007B принят в bounded Day scope, не весь календарь/все gestures. Следующий только NATIVE-007C: раскрываемая область «Без времени», как согласовано пользователем. Без push/deploy.
