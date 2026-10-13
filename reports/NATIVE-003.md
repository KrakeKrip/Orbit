# NATIVE-003 — независимый review Codex

2026-10-13. Вердикт NEEDS_FIXES: один scoped R1 [P2]. Product HEAD c75df417a6f144581ea827f8b2341d20cd73ab8e; assignment/review base fb338c440128d71779b84ffb425911e150d2d42d. Root/branch/HEAD совпадают, clean tree, cumulative diff --check PASS;6 product Swift файлов в разрешённом scope. Merge/push не выполнялись.

## Независимые проверки

- Прочитаны все изменённые Sources/Tests, iOS README, executor report и screenshots03/04. Store validation перед fetch/мутацией, explicit save/rollback, unknownUUID error, nullable поле сохраняет прежнюю entity/свойства. Date sheet пишет только по Save/Clear, Cancel dismiss, error остаётся в editor; дата не скрывает task и не меняет порядок.
- DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test: exit0,30/30. iOS Simulator build в отдельном чистом DerivedData CODE_SIGNING_ALLOWED=NO: exit0,BUILD SUCCEEDED. Один штатный AppIntents metadata warning, не ошибка компиляции. swift test также компилирует macOS executable.
- Отдельная executable probe собрана из неизменённых текущих OrbitCore sources с module-name OrbitCore. Открыта только собственная копия предоставленного executor synthetic legacy fixture. До открытия SQLite schema не содержит ZPLANNEDDATE. Новый store сохранил2UUID/title/completion, plannedDate=nil; затем assign2026-10-20 и новый container по тому же URL подтвердил дату и исходный completion. LEGACY UPGRADE / DATE REOPEN PASS. Исходный fixture/личные stores не открывались на запись. Генерация fixture старым кодом заявлена executor; Codex независимо подтверждает физическую legacy schema и её upgrade, а не присутствовал при генерации.
- Проверка истинного change в iOS GUI НЕ выполнена Codex; GLM также честно указал ограничение tools. Store change/disk проверки и wiring DatePicker state прочитаны. Не считать этот сценарий GUI PASS. Save-failure runtime не проверен; invalid-value tests проходят до save и не доказывают rollback branch.

## R1 [P2] — UI adapter использует негригорианские года

TaskPlannedDate.swift: civilDateString/date(fromCivilDateString) принимают Calendar.current (или supplied calendar) целиком. Calendar.current может быть Buddhist/Hebrew/Islamic, тогда year/month/day имеют другую систему, вопреки строгому Gregorian storage контракту. Это применяется TaskDateSheet и dateLabel: влияние не ограничено test helper.

Детерминированная probe над исходным helper, без изменения system settings:
- knownGregorian2026-10-13T12:00 с timezoneUTC + Calendar(identifier:.buddhist) → civilDateString2569-10-13, isValid false: сохранение обычной сегодняшней даты отказывается.
- storedGregorian2026-10-13 + Buddhist adapter → Date, который в Gregorian равен1483-10-13: editor/подпись получают неверный реальный день.

Исправить только adapters: использовать Gregorian components для storage в обоих направлениях, сохраняя нужную timezone переданного calendar. Не заменять local day на UTC day и не менять persisted String/schema. Добавить регрессии с non-Gregorian calendar (Buddhist + ещё один) и прежними timezone cases. Native DatePicker/locale может отображать системный календарь, но storage остаётся Gregorian. UI/store/schema не переписывать. Scope/checks — tasks/NATIVE-003-R1.md.

## Передача

Одна небольшая коррекция того же TASK/ветки. После неё core tests + build и точная probe/regression; нет причины повторять весь legacy GUI сценарий или web gates. NATIVE-004 не назначен. Результаты/report/exits сохранены вне product tree; собственные temp fixtures/DerivedData/probes удаляются после сохранения evidence. Реальный iPhone не проверен.
