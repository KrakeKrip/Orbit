# NATIVE-005 — независимый review Codex

2026-10-13. Вердикт NEEDS_FIXES: одна небольшая UI-коррекция R1 [P2]. Проверенный product SHA `aa22fdce6cd662df5143555a2e0a72a3ef956636`; assignment `0985c32198eefadfcdad33c8a3c2bcf4ff9a1fab`, source base `a56137473b186efe5b87d4ae9c46881f092262df`. Tree чистое, diff --check PASS. Ровно три product UI файла, README и executor report; core/schema/project/macOS/web не менялись.

## Проверено независимо

- Прочитаны все изменения, TASK и отчёт, screenshots editor и accessibility-large Inbox. Typed errors русские; model вызывает одну core store operation, invalid draft не превращается в clear/default. Save/Clear закрывают sheet только после успеха; Cancel/swipe не вызывают store. Single kind+UUID presentation, стартовый draft из сохранённых значений, defaults только при nil; interval label использует принятый pure helper. Calendar/core не дублируются.
- iOS Simulator xcodebuild в собственной новой DerivedData, DEVELOPER_DIR Xcode27, CODE_SIGNING_ALLOWED=NO: exit0, BUILD SUCCEEDED. Единственный warning — пропущенная AppIntents metadata extraction. Core50 заявлены исполнителем; Codex независимо проверил те же неизменённые core sources в NATIVE-004, повтор здесь не нужен.
- Собственный временный iPhone17 Simulator: реальный GUI add synthetic Review task, назначение даты существующим editor, открытие interval с defaults09:00/30; AX подписи обоих TextField действительно Начало/Длительность. Экранными числовыми клавишами (не AX setValue) введено23:30; Save → строка23:30–00:00 (+1 день), повторное открытие →23:30/30. AX setValue25:00 + Save → видимая русская ошибка, draft сохранён, sheet открыт. Readonly SQLite собственной песочницы подтверждает прежние23:30/30 без изменения. Обычный ввод времени теперь независимо подтверждён.
- В открытом editor AX и source не содержат название task. Скриншот исполнителя подтверждает то же. Отдельные Cancel/Clear/relaunch/accessibility-large flows заявлены GLM; Codex не повторял их целиком. При последующей попытке scroll CUA вернула noWindowsAvailable, это tooling limitation, не доказательство UI-дефекта. Реальный iPhone/runtime disk save-failure не проверены. Не считать build доказательством этих flows.
- Логи/evidence вне дерева: `/Users/atlhnv/Codex/orbit-outputs/NATIVE-005-review-evidence/`. Собственный Simulator удаляется после review; чужие устройства/stores не затронуты. Web/CRM/Colima/3000/hooks/xcode-select не менялись.

## R1 [P2] — отсутствует название редактируемой задачи

`TaskIntervalSheet.swift:29`: Form сразу начинается с полей времени, далее дата; task.title нигде не отображается. TASK требует sheet с названием задачи и датой, как в принятом date editor. При расширенном sheet фоновая строка скрыта, и пользователь не может проверить, какой задаче назначает время. Generic заголовок «Время задачи» этого контекста не даёт.

Добавить видимое название task в самом sheet, с переносом для длинного текста и Dynamic Type, сохранив простой native Form. Не менять поля, валидацию, store, presentation и список. Это один product файл + executor report. Проверки соразмерны: один iOS build и GUI открытие редактора двух разных задач (правильный title после нового открытия; длинный title читается); без полного core/legacy/web прогона. Scope/передача — tasks/NATIVE-005-R1.md.

NATIVE-005 не принят, merge отсутствует; NATIVE-006 пока не выдаётся. Push/deploy не выполнялись.

## Повторное review R1 — PASS

2026-10-13, product SHA `961cc2dcb06db77a7d4eda1b9037278e195dd64a`. Изменён только TaskIntervalSheet.swift (+11 строк) и отчёт. Видимая секция «Задача» содержит актуальный task.title, системный body medium, перенос без lineLimit/фиксированной высоты, отдельный accessibility id. Остальной editor/source не менялся. Скриншот06-r1-long-title-editor.png независимо просмотрен: полное название читается на двух строках; открытие двух задач/Cancel без записи подтверждено executor GUI/readonly evidence, Codex новый GUI-прогон не выполнял.

Независимый iOS Simulator build на новых DerivedData, DEVELOPER_DIR Xcode27/CODE_SIGNING_ALLOWED=NO: exit0, BUILD SUCCEEDED; только прежний AppIntents metadata warning. Cumulative git diff --check a561374..HEAD PASS, дерево чистое. Core и исходные GUI-проверки не повторялись без изменения соответствующего кода. R1 закрыт; NATIVE-005 принят в scope interval editor. Реальный iPhone/disk failure/тёмная тема остаются непроверенными.
