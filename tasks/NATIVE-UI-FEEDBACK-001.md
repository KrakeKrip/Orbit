# NATIVE-UI-FEEDBACK-001

Прямое поручение пользователя Codex: реализовать правки из ZIP самостоятельно. База b589a02294b6f9c7f3c3495999e76cfa0189d96b, отдельная ветка task/NATIVE-UI-FEEDBACK-001.

Уточнение пользователя: сначала интерфейс и баги. Результат: native glass FAB, view menu с меняющейся иконкой справа, настройки/темы, согласованные формы/действия задач, исправление календарного menu anchor и lane gutter, haptics и горизонтальные свайпы дней Upcoming. Сохранить текущие owner-day/mode, civil date/time, minute-wheel и store-контракты. Core/schema не менять. Не импортировать реальные задачи в QA.

Проверки: iOS Simulator build, signed build существующей подписью, живой smoke на собственном временном Simulator, сохранение settings/task после relaunch, diff check. Не выдавать Simulator за physical smoke. Обновление уже установленного Orbit допускается без uninstall/erase; учётные данные и project signing не менять.

Крупные функции отложены в docs/NATIVE-FEEDBACK-BACKLOG.md. Отчёт в reports/NATIVE-UI-FEEDBACK-001-executor.md, чат коротко. Независимый review собственной реализации не заявлять.
