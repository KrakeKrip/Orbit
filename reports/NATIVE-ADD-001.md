# NATIVE-ADD-001 — независимая приёмка

2026-10-14 ACCEPTED. Product f72890f50be3326e8b30a1090f9cf32cf021b10e от assignment661d3a1c14a9fa23d4f2bab695bf1170fa65e5c5. Дерево чистое, diff --check PASS; scope store/test/report.

Source: backwards-compatible optional plannedDate последний default параметр; TaskTitle.validated и принятый date validator до insert; OrbitTask инициализирован с датой сразу, time/duration/completion nil; один context.save с existing rollback/rethrow. Нет отдельного setPlannedDate/save, schema и callers неизменны. Test diff полностью проверен:5новых покрывают date/default nil/disk reopen/invalid date/title+retry. Disk reopen тест удерживает reference созданной модели, поэтому не доказывает освобождение всего runtime; повторный fetch другим store и сохранениеUUID/date реально проверены, process relaunch будет в ADD002.

Независимые checks: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --scratch-path /private/tmp/orbit-add001-review-spm --filter OrbitTaskStore — exit0,30/30PASS; own DerivedData generic iOS Simulator build CODE_SIGNING_ALLOWED=NO — exit0, BUILD SUCCEEDED. Старый expected negative open-test CoreData log не failure. Fullcore/web/GUI не запускались по scope. Runtime save-failure/realdevice не подтверждены, fault injection не вводился.

Уточнение executor report: TempDir.make создаёт test store directories, это не SPM scratch-path. Независимый запуск использовал явный отдельный scratch-path. Неблокирующая неточность отчёта, product defect отсутствует.

Локальная интеграция разрешена; после неё apple source сверяется с tested branch. Следующий ADD002 shared FAB/create UI+Inbox composer removal+emptyToday; без Projects/gestures/push/deploy.
