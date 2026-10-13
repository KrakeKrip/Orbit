# NATIVE-002 — решение по compile blocker

2026-10-13. Executor bc275999edd09663f2fe7ea3681d95396d206868, tree clean. Полный review продукта/GUI ещё не проведён.

Независимая проверка: DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator apple/Orbit/Sources/OrbitCore/OrbitStoreLocation.swift → exit1, homeDirectoryForCurrentUser unavailable in iOS. SDK NSFileManager.h подтверждает API_UNAVAILABLE(ios,...).

В отдельной временной копии того же файла заменён только homeDirectoryForCurrentUser на URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true). Та же typecheck-команда exit0. Product source координатором не изменён. Это проверка совместимости одного файла, не full build/GUI PASS.

Решение: разрешить GLM вариант №1 в том же TASK/ветке (точный scope в tasks/NATIVE-002.md), затем продолжить iOS build и Simulator visual/persistence evidence. macOS CLI R1 остаётся открытым/отложенным; defaultStoreURL helper не вызывается iOS app, но обязан компилироваться как часть package. Нет новых функций/большого refactor. Main/merge/push не затронуты.
