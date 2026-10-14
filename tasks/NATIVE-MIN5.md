Итог DONE,2026-10-14, producta23134f16819864de052c860fdf32185ab13f77a, independent70/70/iOSbuildPASS. Review reports/NATIVE-MIN5.md. Нижe historicalassignment; GUItext4→5explicitlyunverified/deferredwheel.

# NATIVE-MIN5 — минимум назначаемого интервала 5 минут

ASSIGNED, 2026-10-14. Один небольшой результат: новые назначения/изменения ненулевого интервала допускают duration5…1440; legacy1…4 сохраняются и отображаются. База `12fbee7dc651128fa1aa829570180f15c2cd92be` — принят LIST001. Branch `task/NATIVE-MIN5`, worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-MIN5`. Starting SHA assignmentHEAD из handoff. Проверить root/branch/HEAD/status; прочитать AGENTS/ARCHITECTURE/этотTASK. Старые assignments не выполнять.

## Scope

Core TaskTimeInterval.swift (маленький write validator/constant), OrbitTaskStore.swift (только setPlannedInterval duration precheck). UI TaskIntervalSheet.swift (только range hint), IOSInboxModel.swift (только error caption). Targeted existing TaskTimeIntervalTests/OrbitTaskStoreTests; TaskDayProjectionTests только для legacy-read regression если нужна. TestSupport только маленький synthetic fixture helper при необходимости. README соответствующий диапазон и reports/NATIVE-MIN5-executor.md.

OrbitTask/schema/setPlannedDate implementation/TaskPlannedDate/projector implementation/grid/rows/editors layout/menu/nav/Projects/web/macOS UI/targets/dependencies/root docs НЕ менять. No migration/сервис/новыйfaultframework. Никакой minPaintedHeight/calendargeometry или шага drag.

## Контракт

1. Один явно названный минимум НОВОГО interval write =5 в core. Write validation5…1440 вызывается в store.setPlannedInterval ДО любых property mutations/save. 1/2/3/4/0/negative/1441/Int.max отвергаются, никакого округления/clamp/автокоррекции draft. 5 и6/7 допустимы: минимум не означает кратность5. Complete pair/date/time/end validation прежние, failure не меняет UUID/title/date/time/duration/completion.
2. Legacy READ geometry1…1440 остаётся: accepted isValidDuration/end/projector должны продолжать читать stored1…4. Не просто заменить existingminimumDurationMinutes=1 на5 и тем самым скрыть данные. Добавить маленький отдельный write minimum/validator (название ясное), docs/comments различаютreadcompatibility/write rule. Store использует write validator, read end — прежний read validator. Constants не дублировать между UI/core.
3. nil/nil clear разрешён независимо от даты, без новойbusinessлогики. Completion/reopen/открытие/list/датаmove legacytask не округляют и не стирают старыйinterval. setPlannedDate использует accepted read end и не меняется. Старый1minute draft при новом intervalSave отказан с понятным минимумом5; Cancel ничего не пишет, изменить на5 или clear можно штатно.
4. TaskIntervalSheet range hint5…1440, IOSInboxModel invalidDuration error сообщает минимум5/целыеминуты. Core — окончательный источник validation; никаких UI-only checks с обходом core. Existing defaults09:00/30, fields/draft/title/errors/save/rollback/sheets неизменны. UI не должен молча исправлять persisted1 в5 при открытии.

## Meaningful checks

- targeted regressions: store1/4 reject без изменения сохранённого tuple и disk;5/6accept;1440accept/1441+Int.maxsafe reject;clear success. Legacy stored1/4 synthetic fixture создать через model в изолированном test context (не новое store API bypass для app), disk reopen после currentCore показывает исходные values; end/projectionpositive segments сохраняются. Legacydate move/complete/clear unchanged. Pure read1 boundary tests сохраняются, новые write validatortests отдельно. Не ослаблять accepted tests подновыйконтракт: изменить только testsnewwrites где это оправдано, legacyreadAssertions оставить.
- Один `swift test` по всему небольшому native package (core rule влияет на store/read regression; фактические counts/exit указать), один iOSSimulator build ownDerivedData/DEVELOPER_DIR/CODE_SIGNING_ALLOWED=NO. Без web/auth/DB/E2E/full повторов/дополнительных legacy migration harness.
- Короткий own synthetic GUI: datedtask со savedvalidinterval → в existingeditor duration4 Save → видимая ошибка/draft4 и DB unchanged; исправить5 Save → expected sameUUID/pair persist, relaunch/read-onlyпроверка. При возможности открыть legacy1 fixture и Cancel безперезаписи. No реальныеstores/device settings/чужиеsimulators. Toolingfailure честноUNVERIFIED, не тратить часы/не обходитьзащиты.

Обычные scopedcommits/diffcheck/cleantree. Подробныйreport В ФАЙЛ reports/NATIVE-MIN5-executor.md (start/fullSHA/files/actualcommands/exits/counts/evidence/limits/cleanup), чат4–5shortlines status/fullSHA/итог/checks/report. Stop independentCodexreview. Projects/commonheader/drag/resize/3days/Month/AI не начинать. Без merge/push/amend/rebase/reset/stash/deploy/main/чужихworktree/CRM/3000/hooks/settings/xcode-select/signing/AppleID.
