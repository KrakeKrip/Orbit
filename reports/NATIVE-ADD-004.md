# NATIVE-ADD-004 — независимый review

2026-10-15 NEEDS_FIXES: одна date-selection lifecycle correction. HEAD867a0a1025ddb502795230955f194c9b0b3c7a32 от5dbb4a0d3c10ecb791160da2c305fd3e1135592b. Clean/diffcheckPASS; scope2productfiles/report. НезависимыйgenericiOSSimulatorbuild own/private/tmp/orbit-add004-review-dd/DEVELOPER_DIR/CODE_SIGNING_ALLOWED=NO exit0 BUILD SUCCEEDED. Core44/full/webнеповторялись(UIonly).

## R1[P2] Нельзя подтвердить уже показанную дату без изменения колеса

TaskCreatePresentation.swift: init(draftDate=nil,pickerDate=.now) иdateSection: единственныйпутьназначенияdraftDate — onChange(of:pickerDate). DatePickerнеoptional, уже показываетсегодня приInboxnil, нооткрытие/закрытиегруппы ивыборужеselecteddate не изменяютpickerDate. Нетявногоприменения/назначенияshownvalue. ПоэтомуInbox→Дата(сегодняужецентрколеса)→закрыть→Добавить сохраняетundated, timeостаётсяdisabled. Пользовательвынужденизменитьдатунавременночужуюивернуть. После«Убратьдату» pickerDateостаётсястарым, егоshownvalueтакжененазначитьбезпрокрутки. Этоследствиеsource-onlystate-machineпроверки; собственныйGUIрепроданногоSHAне запускался, невымышленныйruntimePASS.

Минимумfix: видимаяявнаякнопка «Выбрать эту дату»/эквивалентныйconfirm вdategroup, назначаетdraftDateизтекущегоpickerDate дажееслиегоvalueнеизменился. Никакихpersistentwrites дообщегоДобавить; открытиегруппысамо не должно назначатьtoday. Нормальныйchange-wheelпуть/clearpair/draftpreservationостаются. Existingdate/timeeditors/coreне менять.

## Остальная проверка

Source reviewed: wholecandidate→model.create→acceptedatomicaddTask, dateclear выключаетpair, timeclear сохраняетdate, start0…59/durationstep5 сmin5/max1440; rangehint/Addgate; endhelper/crossing; ScrollView; readfailureнеwritefailure. Отказысохраняютdrafts, itemidentityfresh/createdguardсохранены. НикакихtemporaryOrbitTask/writesприdraft. Screenshots a02nil/time-disabled,a05block09:08–10:48,a11largefont просмотрены; executorallcontexts/clear/Cancel/retry/boundaries/relaunchreported evidence reviewed. Ночнойпример09:00+20h05 допустимsameendbranch, новый23:30/90GUIповторне нужен. A11несодержитsoftwarekeyboard, поэтомуэтотснимоксампособе недоказываетклавиатурнуюдоступность. SourceScrollViewподдерживаетдоступ; одинактуальныйkeyboardshotдобавитьвtargetedR1smoke.

Runtime diskfailure/realdevice/VoiceOver/dark непроверены. ПолныйGUIповторне требуется: толькоInboxinitialshown-dateconfirm + clear/reselectsame + одинkeyboard/AXLsmoke, одинbuild. Безmerge/EDIT002доR1acceptance. Всеостальныепринятыеcoreинвариантынепеределывать.
