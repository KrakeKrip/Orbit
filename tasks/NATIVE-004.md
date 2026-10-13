# NATIVE-004 — локальный временной интервал задачи (core only)

ASSIGNED,2026-10-13. Одна цель: хранить валидный старт HH:mm и длительность рядом с принятой civil датой. Только shared core и targeted tests; editor/UI — отдельный NATIVE-005. Никакого календарного UI/навигации/серверов.

## База / старт

Review/source base61568f2328066104e6515b604904b383af96ea46 — принятый NATIVE-003,31core tests/iOS build PASS. Ветка task/NATIVE-004, worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-004. Starting SHA coordinator assignment HEAD — в handoff, записать до правок. Проверить root/branch/status; прочитать AGENTS/PRODUCT/ARCHITECTURE и этот TASK. Исторические задания не исполнять.

## Жёсткий scope

Ровно3 product Swift-файла:
1. apple/Orbit/Sources/OrbitCore/OrbitTask.swift;
2. apple/Orbit/Sources/OrbitCore/OrbitTaskStore.swift;
3. один новый apple/Orbit/Sources/OrbitCore/TaskTimeInterval.swift.
Targeted Tests/OrbitCoreTests/TaskTimeIntervalTests.swift и дополнения OrbitTaskStoreTests.swift; при необходимости одна краткая секция apple/Orbit/README.md; reports/NATIVE-004-executor.md.

Не менять TaskPlannedDate/R1 Gregorian adapters, TaskTitle, store location, macOS/iOS UI/project/scheme, root coordination docs/web. Не добавлять targets/dependencies/repository frameworks/полный scheduler. Временный baseline fixture generator из accepted code разрешён только в own tmp для upgrade evidence, не как продуктовая функция.

## Данные и инварианты

Два nullable поля plannedTime:String? и durationMinutes:Int?, default nil, у той же OrbitTask entity. Прежние callers/init args, UUID/title/createdAt/completedAt/plannedDate и sort остаются совместимыми.

- plannedTime строго ASCII HH:mm,00:00..23:59;24:00 не start, пробелы/секунды/offset/нестандартная ширина отвергнуты.
- durationMinutes целое1..1440. Ни дробей, ни0/negative; validate bounds до арифметики, без integer overflow на Int.max.
- nil time + nil duration = без временного интервала. Нельзя только time или только duration.
- Ненулевой интервал требует валидную plannedDate. Нельзя автоматически подставлять «сегодня» в core.
- Дата + nil/nil остаётся задачей без времени. Убрать интервал → оставить дату.
- Убрать дату через прежний setPlannedDate(nil) → очистить time и duration одним save; изменение даты сохраняет interval, если итоговый кандидат валиден. Ошибка оставляет прежние3значения неизменными.

Это civil wall-clock интервал, не UTC instant и не таймер фактически прошедших секунд. Никаких timezone offsets в storage. Длительность может перейти через полночь: например2026-10-13,23:30,90 → derived end2026-10-14,01:00. Не обрезать/сбрасывать duration. End не хранится; маленький pure helper считает end civil date/clock. Точное попадание в полночь даёт00:00 следующей даты. End за Gregorian пределами1900–2199 отвергается до мутации (например2199-12-31,23:59,1); calendar rendering/splitting — будущий TASK. Gregorian/civil arithmetic детерминирована, не зависит от system calendar/DST; внутренний UTC Gregorian calendar можно использовать только как вычислитель civil компонентов, не как конверсию пользовательских значений.

Не добавлять deadline/recurrence/notifications/revision/user/timezone settings. Часовой сетки в этом TASK нет.

## Store / маленький public API

Одна новая операция setPlannedInterval(plannedTime?,durationMinutes?,for UUID) по уже существующей task/date. Naming обычный Swift, архитектуру не наращивать. Fetch по UUID; unknown id → existing taskNotFound. Валидировать весь candidate до изменения свойств, explicit один save + rollback при save throw. Прежний setPlannedDate дополняется только необходимой поддержкой invariants: nil очищает pair, новая дата проверяет совместимость retained pair. Model mutation только нужные свойства. Свой новый error type разрешён; OrbitStoreError не расширять ради правки чужих exhaustive switches. Повтор равного интервала безопасен/без новых tasks, completion/title/order не затронуты.

## Обратная совместимость / targeted checks

До изменения schema сохранить own legacy fixture от accepted NATIVE-003 code:2синтетические задачи (одна dated, другая completed), точныеUUID/title/completion/date и baseline schema без новых полей. Новый core открывает КОПИЮ fixture, старые значения совпадают, time/duration=nil. Фикстура должна быть от настоящего baseline module/entity, не произвольная похожая V1-model. Не коммититьSQLite/WAL/SHM. Сохранить evidence/hash/provenance в report, cleanup только own tmp.

Unit/persistence одного нормального прогона:
- valid/invalid clock+pair+date requirement, duration bounds/overflow input;
- end в тот же день, midnight, next-day, end-range boundary; отдельный fixed non-Gregorian/system-timezone case подтверждает civil результат;
- assign/change/clear interval, date clear clears pair, date move preserves pair, invalid candidate keeps old values; unknownUUID; unchanged completion/title/id/order;
- disk reopen сохраняет interval; baseline fixture upgrade не теряет старые значения.
Существующие31tests сохранить. Без большого fault framework и SQLite triggers (известный SwiftData framework trap).

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test + swift build в apple/Orbit; один iOS Simulator build CODE_SIGNING_ALLOWED=NO в own DerivedData как compile regression для shared model (UI untouched). Отдельный baseline build/run оправдан только fixture generation. Новые GUI actions/screenshots не нужны: UI временного редактора пока НЕ реализуется и не заявляется PASS. Web/npm/DB/auth/E2E не запускать; не менять xcode-select/Apple ID/signing/system preferences/личные stores/чужие simulators.

## Передача

Обычные scoped коммиты, git diff --check/clean tree. Полный reports/NATIVE-004-executor.md: start/latest SHA,files,commands/exits,legacy/derived-end/disk evidence,непроверенное. Чат только4–5коротких строк: статус,full SHA,итог/checks,report path. Остановиться до review Codex; NATIVE-005/UI/календарь/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy, main/чужие worktrees/CRM/3000/hooks не трогать.
