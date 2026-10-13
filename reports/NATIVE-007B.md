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
