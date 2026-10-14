# NATIVE-EDIT-001-R1 — видимость model setter

Одна tiny correction в той же task/NATIVE-EDIT-001/worktree /Users/atlhnv/Codex/orbit-worktrees/NATIVE-EDIT-001. Исходный executorHEAD84f60482ce49ec25f831956013964cad562f6ae5; startingcoordinatorSHAвprompt. Прочитать reports/NATIVE-EDIT-001.md и этотTASK, проверитьroot/branch/HEAD/clean.

Scope OrbitTask.swift и reports/NATIVE-EDIT-001-executor.md. У setTitle(_:) убрать public: оставить internal(обычный func внутри public class) для доступаOrbitTaskStore в том жеOrbitCore модуле. rg confirms единственныйcaller store. Не добавлятьvalidation вsetter и не менятьpublicrename/delete/store/schema/tests/UI/старыеpublicmodelmethods. Комментарий/отчёт должен честно описывать internalsetter, а не public raw bypass.

Один generic iOSSimulatorbuild ownDerivedData/CODE_SIGNING_ALLOWED=NO/DEVELOPER_DIR подтверждает moduleboundary/callers. Повтор36storetests/новыеtests/fullcore/GUI/web не нужны: тела методов/поведение не меняются, Codex уже запускает36targeted дляисходногоHEAD. Обычный новыйscopedcommit, diffcheck/clean, reportВФАЙЛ, чаткратко. Stopreview. Merge/push/amend/rebase/reset/stash/clean/nextTASK/планирование/EDIT002 не делать.
