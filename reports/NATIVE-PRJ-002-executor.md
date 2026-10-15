# NATIVE-PRJ-002 — экран проектов

2026-10-16, база 55dd2214dc77026216e7d234e7b63a1e81f3d422, task/NATIVE-PRJ-002. Codex implementation/self-check по «делаем»; независимый review не заявляется.

## Реализация

- Четвёртая реальная вкладка Проекты: empty state, create в шапке, список с folder/pencil; tap — редактор имени. Task FAB отсутствует. Assignment/task-detail/delete/archive не имитируются.
- IOSInboxModel: projects/projectListError/reloadProjects/saveProject, тот же существующий private store. Общий reload (в том числе scene active) обновляет проекты. Ошибка чтения показывает Повторить; успешный write не становится failure из-за последующей read error. Ошибка записи оставляет draft для retry.
- Одна ProjectNameSheet для create/rename, новый presentation UUID при открытии, скопированные name/projectID; Save/Cancel, keyboard done, autofocus, core validation, native editor surface/theme. При AXL обнаружено усечение длинного rename title — сокращён до Проект.
- Product diff ровно 3 iOS файла: IOSInboxModel, OrbitIOSApp, новый ProjectsScreen. Core/schema/tasks/mutations не менялись.

## Сборки

Первый build обнаружил неподдерживаемый Section(title,content,footer); заменён явным header/content/footer. Две последующие Simulator builds после fix и после короткого title — BUILD SUCCEEDED. Xcode27, свой DD, CODE_SIGNING_ALLOWED=NO. Signing/телефон не использовались. Core98/web не повторялись: их source не менялся. git diff --check PASS.

## GUI и persistence

Отдельный iPhone17/iOS27 Simulator orbit-prj002-codex (1C95E921-8B8F-4398-92EC-2092418517DE), synthetic store. Все UI interactions через CUA. simctl — install/launch/lifecycle/screenshots/Dynamic Type.

- Через Today UI создана контрольная task Preserve task, снят read-only SQL baseline всех столбцов строки.
- Empty Projects: настоящая четвёртая вкладка, empty/create, без task FAB (01-empty.png).
- Create: blank→видимый отказ, 121 ASCII→отказ с draft, corrected retry Работа→Save (02-created.png). Кириллица введена AX setValue, физический набор не заявляется.
- Rename: seeded Работа; Отменённое имя→Cancel сохраняет исходное; reopen не восстанавливает отменённый draft. Blank→отказ→Рабочие планы→Save, прежний UUID.
- Projects→Today→Projects: task/project на месте, FAB только Today.
- Dark через собственный Settings UI: list/rows правильных цветов (03-dark-list.png). AXL list/form/software keyboard проверены. Заголовок усекался, после исправления и final rebuild проверен целый Проект (04-dark-axl-editor-final.png; 04-dark-axl-editor.png — промежуточный кадр до title fix).
- Terminate/install-over-existing/relaunch: тот же UUID/project/name и task. После установки путь собственного контейнера сменился; перед финальным SQL заново получен через simctl. Снимки после relaunch и Cancel совпали с ожидаемыми. Финальный normal-font список 05-final-projects.png визуально проверен.
- SQL: одна task row бит-в-бит идентична по всем столбцам; ровно один project; rename изменил только ZNAME/служебный Z_OPT, UUID/createdAt целы. Отменённые формы не добавили rows.

Evidence /Users/atlhnv/Codex/orbit-outputs/NATIVE-PRJ-002/: screenshots/build logs/synthetic JSON вне Git.

## Ограничения

Полное окно Device Hub не доставляло coordinate clicks (noWindowsAvailable), AX работал. Стандартный Simulator app недоступен; native toolbar compact Device Hub восстановил координатные клики, табы проверены вживую. JSON снимок bytes исправлен на hex; итоговое сравнение всех полей выполнено.

UNVERIFIED: swipe-to-dismiss (две попытки CUA drag не сдвинули sheet), pull-to-refresh, injected read/save disk failures, VoiceOver, маленькая ширина/другие версии iOS и физический iPhone. Явный Cancel/discard подтверждены; недоставленный swipe не выдаётся за проверку закрытия жестом. Полный frame-by-frame анализ sheet transition не выполнялся; физический haptic feel не проверен.

Личные базы/телефон/чужие симуляторы/серверы не тронуты. Push/установка на iPhone не выполнялись.
