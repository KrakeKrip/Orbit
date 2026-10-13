# NATIVE-006 — iOS: список «Сегодня»

NEEDS_FIXES (R1), 2026-10-13. Коррекция/review в task worktree: tasks/NATIVE-006-R1.md, reports/NATIVE-006.md. Исходный scope сохранён. Один результат: отдельный настоящий список задач, запланированных на текущую локальную дату. Без часовой сетки, нового editor, quick-add scheduling или полного календаря.

## Старт

Review/source base `800b189adc9442d980cb8fb5080aa5e42efa0ff7` — принят NATIVE-005, shared core50. Ветка `task/NATIVE-006`, worktree `/Users/atlhnv/Codex/orbit-worktrees/NATIVE-006`. Starting SHA — assignment HEAD из handoff; перед правками проверить root/branch/HEAD/status, прочитать AGENTS/PRODUCT/ARCHITECTURE/DESIGN и этот TASK. Старые задания не выполнять.

## Scope — три product Swift файла

1. `apple/OrbitIOS/OrbitIOS/OrbitIOSApp.swift`: минимальный native TabView с двумя реальными вкладками Сегодня/Входящие, default Сегодня. Обе используют ОДИН уже открытый IOSInboxModel/store; open-failure поведение сохраняется.
2. Новый `apple/OrbitIOS/OrbitIOS/TodayScreen.swift`: только list screen, повторное использование InboxRowView, InboxSheetPresentation и существующих date/interval sheets. Небольшое состояние текущего дня и sheet, без нового data layer/controller.
3. Новый `apple/Orbit/Sources/OrbitCore/TaskDaySelection.swift`: маленькая read-only выборка по заданной civil date, без изменения моделей/store/API mutations. Пригодна для deterministic tests.

Также разрешены один targeted `apple/Orbit/Tests/OrbitCoreTests/TaskDaySelectionTests.swift`, краткая секция `apple/OrbitIOS/README.md`, `reports/NATIVE-006-executor.md`. НЕ менять существующие core/store/date/time/helpers, InboxScreen/IOSInboxModel/editors, macOS/project/scheme/root docs/web. Не добавлять framework/dependency/targets. Если реальная блокировка требует иных файлов — сообщить координатору, не расширять молча.

## Правила Today

- Today = Gregorian local civil date устройства, через уже принятый TaskPlannedDate.civilDateString и системную timezone. Reference instant читать один раз на обновление, не хранить «сегодня» навсегда при launch и не писать его в задачи.
- В список попадают ровно задачи с plannedDate == today, включая с временем и без времени. Nil/yesterday/tomorrow не попадают. Дата старта определяет принадлежность: вчерашний overnight interval не добавляется в список сегодняшнего дня; отображение продолжений в сетке — NATIVE-007.
- Это первый list slice, без overdue/deadline/recurrence buckets (соответствующих полей ещё нет). Не добавлять их как фиктивные данные. Существующий Inbox остаётся списком ВСЕХ задач, не превращать его в undated-only и не перемещать/копировать записи между вкладками.
- Маленькая выборка принимает explicit valid civil date и массив tasks, возвращает те же объекты в исходном стабильном порядке, без мутаций/новых UUID; невалидная дата -> пустой результат. Completed не выбрасывать в helper: UI разделяет Открытые/Завершённые как Inbox.
- Заголовок «Сегодня», видимая локальная дата, честный empty state «На сегодня задач нет». Нет seed задач/фальшивых счётчиков/переключателя несуществующего «Расписания».
- Существующие строки и controls: complete/reopen, date/interval editor с актуальным task/title. Смена/очистка даты обновляет выборку сразу после успешного save; задача может исчезнуть из Today, но сохраняется в Inbox с тем же UUID. Завершение переводит в секцию Завершённые, reopen возвращает в Открытые.
- Read/storage errors и model.writeError видимы, отказ не изображать успехом; Retry обновляет реальный store. Не создавать второй store/model для Today, не копировать tasks в независимый cache.
- На появлении Today и возврате приложения в active обновить current day и перечитать model. Пока Today открыт, пересчитать day не реже раза в минуту; significant clock/timezone change должен обновлять день без relaunch. Использовать простые SwiftUI lifecycle/notification/periodic механизмы, без scheduler engine. Это только read context: даты/время задач не конвертировать и не перезаписывать.
- Native TabView, системные материалы/цвета и существующий coral accent; нативная система сама оформляет tab bar на iOS27. Не рисовать имитацию Glass. Только две доступные вкладки, никаких пустых Calendar/Projects.
- Создание остаётся в существующем Inbox composer. Кнопка/empty-state action «Добавить во Входящих» переключает на живую вкладку Inbox; не создаёт задачу автоматически и не подставляет today. Новый quick-add Today с атомарной датой — отдельная функция, не реализовывать add+setDate двумя saves.
- Сохранять safe areas: tab bar/Inbox composer/keyboard не перекрывают друг друга. Dynamic Type/длинные titles/44pt controls как принятый Inbox. Один sheet за раз на Today, свежий draft при открытии; существующие editor invariants не переписывать.

## Проверки, без лишних повторов

Targeted deterministic core tests для TaskDaySelection: включение dated timed/untimed; исключение nil/другой даты; completed остаётся; stable order/те же UUID; invalid civil date; отсутствие изменения task fields. Текущие50 tests сохранить, один нормальный swift test проход с DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer.

Один iOS Simulator build CODE_SIGNING_ALLOWED=NO в own DerivedData. Schema/store не меняются: legacy migration/7200 oracle/web/DB/auth/npm не повторять.

Own temporary iPhone Simulator, только synthetic данные:
1. Набор today untimed + today timed + today completed + yesterday/tomorrow/nil. Today показывает только свои, Inbox все те же задачи; переключение вкладок не клонирует записи.
2. Complete/reopen из Today отражается в обеих вкладках; date/interval sheet открывается с правильным title/значениями. Clear date убирает из Today и оставляет в Inbox.
3. Empty state/action переводит в настоящий Inbox composer; add там работает как раньше, без авто-даты. Relaunch сохраняет данные, Today читает актуальный local day.
4. Keyboard/safe areas и accessibility-large, два screenshot Today и Inbox с tab bar вне product tree `/Users/atlhnv/Codex/orbit-outputs/NATIVE-006/`.

Для фильтра GUI разрешён own synthetic fixture generator из реального core в tmp (explicit dates относительно одного reference instant), установка store только в СОБСТВЕННУЮ новую пустую Simulator песочницу до launch. Не считать такое fixture provisioning GUI-проверкой назначения даты; mutations/UI проверять настоящими controls. Никаких личных данных/stores и смены системных настроек компьютера. Midnight/timezone lifecycle проверить deterministic date/helper cases + source wiring; реальная смена системного времени/часовой зоны не требуется и не заявляется проверенной. Если AX wheel/tools не позволяют action — честный UNVERIFIED, не тратить часы на обходы. Повторять gates только после изменений/ошибки, не дважды по привычке.

## Передача

Обычные scoped commits, diff --check/clean tree. ПОДРОБНЫЙ отчёт В ФАЙЛ reports/NATIVE-006-executor.md (start/latest SHA, файлы/команды/exits, fixture/GUI evidence, ограничения). В чат только4–5коротких строк: статус/full SHA/итог/checks/report. Остановиться до Codex review; NATIVE-007/часовую сетку/3дня/Месяц/macOS-R1 не начинать. Без merge/push/amend/rebase/reset/stash/deploy; main/чужие worktrees/CRM/3000/hooks/xcode-select/Apple ID/signing не трогать.
