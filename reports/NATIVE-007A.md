# NATIVE-007A — независимый review Codex

2026-10-13. Вердикт NEEDS_FIXES: одна небольшая коррекция с двумя пунктами (helper + его tests). Product SHA `1e53a778fe92b91ef00b97254edaa122c691e5d5`, assignment `8b98ed88a4856c59846ad5056a7326a3d0405f3b`, source base `2b14c779ad2abff50e6b30bc87457c8f9e580fb2`. Tree чистое, cumulative diff check PASS; ровно один product helper, targeted test, README/report.

## Независимые проверки

Sources/tests/TASK/report прочитаны полностью. Untimed selection и chronological sort корректны по коду; range validation делегирует принятому TaskTimeInterval.end до minute parsing. Read-only helper не мутирует model/store, DST/calendar/conversions/lane layout отсутствуют. Completed/overlap сохраняет, positive overnight clips correctly; IDs UUID+day стабильны.

DEVELOPER_DIR Xcode27 swift test: exit0, 66/66. Этот один проход НЕ снимает две находки ниже: boundary test закрепляет неправильный flag, tie-test зависит от случайных UUID. Отдельный executable probe компилировал неизменённые реальные core sources и использовал только синтетические in-memory OrbitTask с fixed IDs. Детерминированное evidence:

```
R1 До полуночи: intoNext=true, nextCount=0; expected false/0
R1 Сутки: intoNext=true, nextCount=0; expected false/0
R2 correct end-first order, original UUID-only assertion=false; expected false for these deterministic IDs
```

iOS build этого раунда не запускался Codex: блокирующие pure-contract findings воспроизведены, compile helper прошёл swift test/probe. Executor iOS build заявлен PASS; после коррекции будет один independent iOS compile check. GUI отсутствует по заданию, календарная сетка НЕ реализована. Evidence: `/Users/atlhnv/Codex/orbit-outputs/NATIVE-007A-review-evidence/`. Web/legacy/DB/GUI не запускались, main/чужие worktree/CRM/3000/hooks не затронуты.

## R1 [P2] — ложное продолжение при точной полуночи

TaskDayProjection.swift:119: при end.date != selected day continuesIntoNextDay всегда true. Но 23:30/30 и 00:00/1440 заканчиваются ровно в00:00, не имеют положительной части следующего дня. В следующем дне segments пусто, но флаг исходного segment утверждает обратное. TASK явно определяет flags как positive neighbouring coverage, exact-midnight false. Будущий календарь получит ложный указатель продолжения.

Исправить flag минимально: true только когда положительная часть действительно существует после границы суток. Геометрию/zero segment exclusion/core end не переделывать. В exactMidnight test сейчас assert true сам ошибочен: заменить на false; full-day00:00 test также должен assert false. Overnight23:30/90 и duration1440/09:00 должны оставаться true на стартовом дне и fromPrevious=true на следующем.

## R2 [P2] — случайный ложный провал sort test

TaskDayProjectionTests.swift:166–169: два сегмента имеют одинаковый start540, но разные ends555 и600. Контракт сначала сортирует END, UUID применяется лишь при равенстве start И end. Тест требует UUID-sort для разных ends. makeTask создаёт случайные UUID; верный product comparator поэтому может случайно падать на этом assertion. Независимый fixed-ID probe: shorter end UUID FFFF..., longer end UUID000...; правильный результат FFFF,000; старый test assertion false.

Сохранить проверку end-priority и overlaps. Настоящий UUID tie проверить на двух задачах с одинаковыми start/end и явно фиксированными различными UUID, входной порядок обратный ожидаемому. Не менять верный product sort под ошибочный тест и не ослаблять tests до count-only.

Scope/checks — tasks/NATIVE-007A-R1.md. Одна коррекция двух файлов, без UI/новой архитектуры. NATIVE-007A не принят, merge/push/deploy отсутствуют;007B не назначен.

## Повторное review R1/R2 — PASS

2026-10-13, product SHA `addcfd3d3e434136ab4787cf94cd239fe5e78edc`. Source diff ровно helper boundary flag, targeted tests и отчёт; geometry/next-day exclusion/accepted end/comparator не менялись. Exact-midnight flag теперь проверяет positive end minutes:23:30/30 и00:00/1440 false, positive overnight случаи true. Старый ошибочный UUID assertion убран при сохранённых end-priority/overlap checks. Новый genuine tie test использует одинаковые start/end, fixed разные UUID и reverse input, ожидаемый UUID order/repeat stable.

Независимо: DEVELOPER_DIR Xcode27 swift test --filter TaskDayProjection exit0,11/11; iOS Simulator build на новых own DerivedData/CODE_SIGNING_ALLOWED=NO exit0,BUILD SUCCEEDED (только AppIntents metadata warning). Cumulative diff --check PASS/clean tree. Полный66 suite прошёл на исходном product в предыдущем review; после scoped fix выполнены релевантные11 без повторов legacy/web/GUI. Нельзя обозначать этот раунд полным67test прогоном — он targeted.

R1/R2 закрыты. NATIVE-007A принят как read-only foundation, без календарного UI. Следующий007B — отдельный ограниченный Day grid UI;3дня/Месяц/drag/новый quick-add не назначены. Push/deploy отсутствуют. Логи сохранены в NATIVE-007A-review-evidence.
