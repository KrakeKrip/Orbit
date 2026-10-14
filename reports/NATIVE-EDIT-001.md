# NATIVE-EDIT-001 — независимый review

2026-10-14 NEEDS_FIXES(одна tiny visibility correction). HEAD84f60482ce49ec25f831956013964cad562f6ae5, assignment411f5fc77ba0a9e60ed4b42c8cc8867de75f0058. Clean/diffcheckPASS, source/testdiff reviewed.

R1[P2] OrbitTask.swift:56: новый public func setTitle принимает любуюстроку безTaskTitlevalidation. У iOS/model consumers появился public raw bypass, тогда какTASK п1 прямо запрещает новыйpublicrawобход и сохраняет validatedstoreentrypoint. Комментарий и executorreport ошибочно утверждают, чтоpublicобхода нет. Минимальныйfix — internalfunc(убратьpublic). Единственныйcaller rg — OrbitTaskStore в томжеOrbitCore; public renameTask остаётсяпровереннымUI API. Не менять validation/schema/storelogic/старыеmodelmethods и не переписыватьtests.

Остальное source соответствует: rename validatesдоmutation, fetchUUID/unknownrefusal, titleonly, normalizedidentical веткаno-save;deletefetchUUID/context.delete толькообъекта/одинsave rollback. Sixnewtestschecked preservation/invalid/noop/unknown/delete/reopen. Diskreopen сохраняетmodelreferences, это неprocessrelaunchproof, ноnewstorefetchpersistenceподтверждён; runtime savefailureUNVERIFIED.

Независимыеchecks ownscratch/DEVELOPER_DIR: swift test --scratch-path /private/tmp/orbit-edit001-review-spm --filter OrbitTaskStore — exit0 36/36PASS; genericiOSSimulatorbuild CODE_SIGNING_ALLOWED=NO ownDD — exit0 BUILD SUCCEEDED. UI/schema не менялись, GUI/fullcore/web не запускались. Толькоsynthetictempstores.

Назначенtasks/NATIVE-EDIT-001-R1.md: однастрокаvisibility+report, одинiOSbuild послеfix; новыхtests/повтора36suite не требовать. Merge иследующийcreateintervalTASK пока не выдаются. Приоритетпослеacceptance: atomiccreateintervalcore→createUIdate/time/duration→EDIT002→firstiPhoneQA; deadlines/remindersпосле.
