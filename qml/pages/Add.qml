/*
Copyright (C) 2017 Olavi Haapala.
<harbourwht@gmail.com>
Twitter: @0lpeh
IRC: olpe
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of wht nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: page
    allowedOrientations: Orientation.Portrait | Orientation.Landscape | Orientation.LandscapeInverted
    canAccept: validateHours()
    property QtObject dataContainer: null
    property QtObject previousPage: null
    property bool editMode: false
    property string description: qsTr("No description")
    property string project: "" //default
    property string taskId: "0"
    property double duration: 8
    property double breakDuration: 0
    property double netDuration: 8
    property string uid: "0"
    property string dateText: qsTr("Today")
    property date selectedDate : new Date()
    property date timeNow : new Date()
    property int startSelectedHour : timeNow.getHours() - 8
    property int startSelectedMinute : timeNow.getMinutes()
    property int endSelectedHour : timeNow.getHours()
    property int endSelectedMinute : timeNow.getMinutes()
    property bool fromCover: false
    property bool fromTimer: false
    property bool endTimeStaysFixed: true
    property variant tasks: []
    property bool projectComboInitialized: false

    //Simple validator to avoid adding negative or erroneous hours
    function validateHours() {
        // Lazyfix... sry
        if (breakDuration < 0) {
            breakDuration = 0
            breakDurationButton.value = "00:00"
        }

        return (duration >=0
                && netDuration >=0
                && breakDuration >=0
                && startSelectedHour < 24
                && startSelectedMinute < 60
                && endSelectedHour < 24
                && endSelectedMinute < 60)
    }

    function updateDateText(){
        var date = new Date(dateText)
        var now = new Date()

        if(now.toDateString() === date.toDateString()) {
            datePicked.value = qsTr("Today")
        }

        else {
            var splitted = date.toDateString().split(" ")
            datePicked.value = splitted[1] + " " +splitted[2] + " "+ splitted[3]
        }
    }

    function saveHours() {
        if (descriptionTextArea.text) {
            description = descriptionTextArea.text
        }

        if (uid == "0") {
            uid = db.getUniqueId()
        }



        var dateString = helpers.dateToDbDateString(selectedDate)
        var startTime = helpers.pad(startSelectedHour) + ":" + helpers.pad(startSelectedMinute)
        var endTime = helpers.pad(endSelectedHour) + ":" + helpers.pad(endSelectedMinute)
        project = modelSource.get(projectCombo.currentIndex).id
        taskId = taskModelSource.get(taskCombo.currentIndex).id

        if (!taskId) {
            taskId = "0"
        }

        Log.info("Saving: " + uid + "," + dateString + "," + startTime + "," + endTime + "," + duration + "," + project + "," + description + "," + breakDuration + "," + taskId)

        var values = {
            "uid": uid,
            "date": dateString,
            "startTime": startTime,
            "endTime": endTime,
            "duration": duration,
            "project": project,
            "description": description,
            "breakDuration": breakDuration,
            "taskId": taskId
        };
        if(db.saveHourRow(values)) {
            if (dataContainer != null) {
                page.dataContainer.getHours()
            }

            if (previousPage != null) {
                page.previousPage.updateView()
            }
        }
        else {
            banner.notify("Error when saving!")
        }
    }

    function ensureValidStartTimeValues(hour, minute) {
        if (hour < 0) {
            hour += 24
        }

        if (minute < 0) {
            minute += 60
            hour -=1
        }

        if (hour < 0) {
            hour += 24
        }
    }

    function updateStartTime() {
        startSelectedHour = endSelectedHour - helpers.countHours(duration)
        startSelectedMinute = endSelectedMinute - helpers.countMinutes(duration)
        ensureValidStartTimeValues(startSelectedHour, startSelectedMinute)
        startTime.value = helpers.pad(startSelectedHour) + ":" + helpers.pad(startSelectedMinute)
    }

    function ensureValidEndTimeValues(hour, minute) {
        if (hour >= 24) {
            hour -= 24
        }

        if (minute >= 60) {
            minute -= 60
            hour += 1
        }

        if (hour >= 24) {
            hour -= 24
        }
    }

    function updateEndTime() {
        endSelectedHour = startSelectedHour + helpers.countHours(duration)
        endSelectedMinute = startSelectedMinute + helpers.countMinutes(duration)
        ensureValidEndTimeValues(endSelectedHour, endSelectedMinute)
        endTime.value = helpers.pad(endSelectedHour) + ":" + helpers.pad(endSelectedMinute)
    }

    function updateBreakDuration() {
        breakDurationButton.value = breakDuration.toString().toHHMM()
    }

    function updateNetDuration() {
        netDuration = duration - breakDuration
        netDurationButton.value = netDuration.toString().toHHMM()
    }

    function updateDuration() {
        durationButton.value = duration.toString().toHHMM()
    }

    function setEndNow() {
        var now = new Date()
        endSelectedHour = now.getHours()
        endSelectedMinute= now.getMinutes()
        endTime.value = helpers.pad(endSelectedHour) + ":" + helpers.pad(endSelectedMinute)
        updateStartTime()
    }

    function setStartNow() {
        var now = new Date()
        startSelectedHour = now.getHours()
        startSelectedMinute= now.getMinutes()
        startTime.value = helpers.pad(startSelectedHour) + ":" + helpers.pad(startSelectedMinute)
        updateEndTime()
    }

    function doRoundToNearest() {
        if (settings.getRoundToNearest()) {
            var startValues = helpers.hourMinuteRoundToNearest(startSelectedHour, startSelectedMinute)
            startSelectedHour = startValues.hour
            startSelectedMinute = startValues.minute
            var endValues = helpers.hourMinuteRoundToNearest(endSelectedHour, endSelectedMinute)
            endSelectedHour = endValues.hour
            endSelectedMinute = endValues.minute
            duration = helpers.calcRoundToNearest(duration)
            breakDuration = helpers.calcRoundToNearest(breakDuration)
        }
    }

    function showNetDurationTimepicker () {
        var netHour = helpers.countHours(netDuration)
        var netMinute = helpers.countMinutes(netDuration)
        openTimeDialog(netHour, netMinute, durationSelected, "netDuration")
    }

    function showBreakDurationTimepicker () {
        var breakHour = helpers.countHours(breakDuration)
        var breakMinute = helpers.countMinutes(breakDuration)
        openTimeDialog(breakHour, breakMinute, durationSelected, "breakDuration")
    }

    function showDurationTimepicker () {
        var durationHour = helpers.countHours(duration)
        var durationMinute = helpers.countMinutes(duration)
        openTimeDialog(durationHour, durationMinute, durationSelected, "duration")
    }

    function durationSelected (dialog, durationType) {
        var durationHour = dialog.hour
        var durationMinute = dialog.minute

        if (durationType === "duration") {
            duration = (((durationHour)*60 + durationMinute) / 60).toFixed(2)
            durationButton.value = helpers.pad(durationHour) + ":" + helpers.pad(durationMinute)

            if (endTimeStaysFixed) {
                updateStartTime()
            }

            else {
                updateEndTime()
            }

            updateNetDuration()
        }

        else if (durationType === "breakDuration") {
            breakDuration = (((durationHour)*60 + durationMinute) / 60).toFixed(2)
            breakDurationButton.value = helpers.pad(durationHour) + ":" + helpers.pad(durationMinute)
            updateNetDuration()
        }

        else if (durationType === "netDuration") {
            netDuration = (((durationHour)*60 + durationMinute) / 60).toFixed(2)
            netDurationButton.value = helpers.pad(durationHour) + ":" + helpers.pad(durationMinute)
            duration = netDuration + breakDuration
            updateDuration()

            if (endTimeStaysFixed) {
                updateStartTime()
            }

            else {
                updateEndTime()
            }
        }

    }

    function startTimeSelected(dialog) {
        startTime.value = dialog.timeText
        startSelectedHour = dialog.hour
        startSelectedMinute = dialog.minute
        var endHour = endSelectedHour
        var endMinute = endSelectedMinute

        if (endMinute - startSelectedMinute < 0) {
            endMinute +=60
            endHour -=1
        }

        if (endHour - startSelectedHour < 0)
            endHour +=24

        duration = ((((endHour - startSelectedHour) * 60) + (endMinute - startSelectedMinute)) / 60).toFixed(2)
        updateDuration()
        updateNetDuration()
    }

    function endTimeSelected(dialog) {
        endTime.value = dialog.timeText
        endSelectedHour = dialog.hour
        endSelectedMinute = dialog.minute
        var endHour = endSelectedHour
        var endMinute = endSelectedMinute

        if (endMinute - startSelectedMinute < 0) {
            endMinute += 60
            endHour -= 1
        }

        if (endHour - startSelectedHour < 0) {
            endHour += 24
        }

        duration = ((((endHour - startSelectedHour)*60) + (endMinute - startSelectedMinute)) / 60).toFixed(2)
        updateDuration()
        updateNetDuration()
    }

    function openTimeDialog(h, m, callBack, durationType) {
        var dur = -1
        if (durationType === 'breakDuration') {
            dur = duration
        }

        var dialog = pageStack.push("MyTimePicker.qml", {
                                    hourMode: (DateTime.TwentyFourHours),
                                    hour: h,
                                    minute: m,
                                    duration: dur,
                                    roundToNearest: settings.getRoundToNearest()
                                 })

        dialog.accepted.connect(function() {
            callBack(dialog, durationType)
        })
    }

    SilicaFlickable {
        contentHeight: column.y + column.height
        width: parent.width
        height: parent.height

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Theme.PaddingLarge

            DialogHeader {
                acceptText: qsTr("Save")
                cancelText: qsTr("Cancel")
            }

            TextSwitch {
                id: timeSwitch
                checked: true
                text: qsTr("Ends now")
                width: parent.width * 0.7
                description: qsTr("Endtime will be set to now.")
                anchors.horizontalCenter: parent.horizontalCenter
                onCheckedChanged: {
                    timeSwitch.text = checked ? qsTr("Ends now") : qsTr("Starts now")
                    timeSwitch.description = checked ? qsTr("Endtime will be set to now.") : qsTr("Starttime will be set to now.")

                    if (checked) {
                        setEndNow()
                    }

                    else {
                        setStartNow()
                    }
                }
            }

            BackgroundItem {
                onClicked: datePicked.openDateDialog()

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.secondaryHighlightColor
                    radius: Theme.paddingMedium
                    width: parent.width * 0.7
                    height: datePicked.height

                    ValueButton {
                        id: datePicked
                        anchors.centerIn: parent
                        label: qsTr("Date:")
                        value: dateText
                        onClicked: openDateDialog()

                        function openDateDialog() {
                            var dialog = pageStack.push("Sailfish.Silica.DatePickerDialog", { date: new Date() })

                            dialog.accepted.connect(function() {
                                value = dialog.dateText
                                selectedDate = dialog.date
                            })
                        }
                    }
                }
            }

            BackgroundItem {
                onClicked: startTime.doOnClicked()

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: startSelectedHour <24 && startSelectedMinute < 60 ? Theme.secondaryHighlightColor : "red"
                    radius: Theme.paddingMedium
                    width: parent.width * 0.7
                    height: startTime.height

                    ValueButton {
                        id: startTime
                        anchors.centerIn: parent
                        label: qsTr("Start time:")
                        value: helpers.pad(startSelectedHour) + ":" + helpers.pad(startSelectedMinute)
                        width: parent.width
                        onClicked: doOnClicked()

                        function doOnClicked() {
                            openTimeDialog(startSelectedHour, startSelectedMinute, startTimeSelected)
                        }
                    }
                }
            }

            BackgroundItem {
                onClicked: endTime.doOnClicked()

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: endSelectedHour <24 && endSelectedMinute < 60 ? Theme.secondaryHighlightColor : "red"
                    radius: Theme.paddingMedium
                    width: parent.width * 0.7
                    height: endTime.height

                    ValueButton {
                        id: endTime
                        anchors.centerIn: parent
                        label: qsTr("End time:")
                        value: helpers.pad(endSelectedHour) + ":" + helpers.pad(endSelectedMinute)
                        width: parent.width
                        onClicked: doOnClicked()

                        function doOnClicked() {
                            openTimeDialog(endSelectedHour, endSelectedMinute, endTimeSelected)
                        }
                    }
                }
            }

            TextSwitch {
                id: fixedSwitch
                checked: true
                width: parent.width * 0.7
                text: qsTr("Endtime stays fixed")
                description: qsTr("Starttime will flex if duration is changed.")
                anchors.horizontalCenter: parent.horizontalCenter

                onCheckedChanged: {
                    fixedSwitch.text = checked ? qsTr("Endtime stays fixed") : qsTr("Starttime stays fixed")
                    fixedSwitch.description = checked ? qsTr("Starttime will flex if duration is changed.") : qsTr("Endtime will flex if duration is changed.")

                    if (checked) {
                        endTimeStaysFixed = true
                    }

                    else {
                        endTimeStaysFixed = false
                    }
                }
            }

            BackgroundItem {
                onClicked: showDurationTimepicker()

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: duration>=0 ? Theme.secondaryHighlightColor : "red"
                    radius: Theme.paddingMedium
                    width: parent.width * 0.7
                    height: durationButton.height

                    ValueButton {
                        id: durationButton
                        anchors.centerIn: parent
                        label: qsTr("Duration")+": "
                        value: duration.toString().toHHMM()
                        width: parent.width
                        onClicked: showDurationTimepicker()
                    }
                }
            }

            BackgroundItem {
                onClicked: showBreakDurationTimepicker()

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: breakDuration>=0 ? Theme.secondaryHighlightColor : "red"
                    radius: Theme.paddingMedium
                    width: parent.width * 0.7
                    height: breakDurationButton.height

                    ValueButton {
                        id: breakDurationButton
                        anchors.centerIn: parent
                        label: qsTr("Break")+": "
                        value: "00:00"
                        width: parent.width
                        onClicked: showBreakDurationTimepicker()
                    }
                }
            }
            BackgroundItem {
                visible: breakDuration
                onClicked: showNetDurationTimepicker()

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: netDuration>=0 ? Theme.secondaryHighlightColor : "red"
                    radius: Theme.paddingMedium
                    width: parent.width * 0.7
                    height: netDurationButton.height

                    ValueButton {
                        id: netDurationButton
                        anchors.centerIn: parent
                        label: qsTr("Net duration")+": "
                        value: netDuration.toString().toHHMM()
                        width: parent.width
                        onClicked: showNetDurationTimepicker()
                    }
                }
            }

            ComboBox {
                id: projectCombo
                width: parent.width * 0.7
                anchors.horizontalCenter: parent.horizontalCenter
                label: qsTr("Project")
                description: qsTr("Add or edit projects in settings")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: modelSource
                        delegate: MenuItem {
                            text: model.name
                            color: model.labelColor
                            font.bold: true
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (projectComboInitialized) {
                        var selectedValue = modelSource.get(currentIndex).value
                        project = modelSource.get(currentIndex).id
                        var lastUsed = db.getLastUsedInput(project)

                        if (lastUsed['taskId'] && lastUsed['taskId'] !== '') {
                            taskId = lastUsed['taskId']
                        }

                        if (lastUsed['description'] && lastUsed['description'] !== '') {
                            descriptionTextArea.text = lastUsed['description']
                        }
                    }
                    projectComboInitialized = true
                    taskCombo.init()
                }

                function init() {
                    appState.data.projects = db.getProjects()
                    var projects = appState.data.projects
                    if (projects.length === 0) {
                        var id = db.insertInitialProject(Theme.secondaryHighlightColor);
                        if (id) {
                            //TODO: Try to get rid of this kind of code
                            settings.setDefaultProjectId(id)
                            appState.data.projects = db.getProjects()
                            projects = appState.data.projects
                        }
                    }

                    for (var i = 0; i < projects.length; i++) {
                        modelSource.set(i, {
                                       'id': projects[i].id,
                                       'name': projects[i].name,
                                       'labelColor': projects[i].labelColor
                                        })
                    }
                    _updating = false

                    if(project === "") {
                        project = settings.getDefaultProjectId()
                    }

                    for (var i = 0; i < modelSource.count; i++) {
                        if (modelSource.get(i).id == project) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            ListModel {
                id: modelSource
            }

            // Task ComboBox
            ComboBox {
                id: taskCombo
                width: parent.width * 0.7
                anchors.horizontalCenter: parent.horizontalCenter
                label: qsTr("Task")
                description: qsTr("Add or edit tasks in project settings")
                menu: ContextMenu {
                    Repeater {
                        id: repeat
                        width: parent.width
                        model: taskModelSource
                        delegate: MenuItem {
                            text: model.name
                            font.bold: true
                        }
                    }
                }

                onCurrentItemChanged: {
                    if (currentIndex !== -1) {
                        var selectedValue = taskModelSource.get(currentIndex).value
                        taskId = taskModelSource.get(currentIndex).id

                        if (taskId > 0) {
                            var lastUsed = db.getLastUsedInput(project)

                            if (lastUsed['taskId'] && lastUsed['taskId'] !== '') {
                                taskId = lastUsed['taskId']
                            }

                            if (lastUsed['description'] && lastUsed['description'] !== '') {
                                descriptionTextArea.text = lastUsed['description']
                            }
                        }
                    }
                }

                function deleteAll() {
                    // @TODO: Does not work
                    for (var i = 0; i < taskModelSource.length; i++) {
                        taskModelSource.delete(i)
                    }
                }

                function init(deselect) {
                    tasks = db.getTasks(project)
                    for (var i = 0; i < tasks.length; i++) {
                        taskModelSource.set(i, {
                            'id': tasks[i].id,
                            'name': tasks[i].name
                        })
                    }

                    taskModelSource.set(tasks.length, {
                        'id': '0',
                        'name': qsTr("No task defined"),
                        'enabled': false
                    })

                    _updating = false

                    currentIndex = -1
                    currentItem = null

                    if (taskId !== "0" || taskId !== "") {
                        for (var i = 0; i < taskModelSource.count; i++) {
                            if (taskModelSource.get(i).id === taskId) {
                                currentIndex = i
                                break
                            }
                        }
                    }
                }
            }

            ListModel {
                id: taskModelSource
            }

            TextField {
                id: descriptionTextArea
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                placeholderText: qsTr("Enter an optional description")
                onClicked: {
                    selectAll()
                }
            }

            Item {
                width: parent.width
                height: 10
            }

            Component.onCompleted: {
                if(!editMode && !fromTimer) {
                    var dur = settings.getDefaultDuration()
                    if (dur >=0) {
                        duration = dur
                    }

                    var brk = settings.getDefaultBreakDuration()
                    if (brk >= 0) {
                        breakDuration = brk
                    }
                }

                var endFixed = settings.getEndTimeStaysFixed()
                if (endFixed === "yes") {
                    fixedSwitch.checked = true
                }
                else if (endFixed === "no") {
                    fixedSwitch.checked = false
                }

                var nowByDefault = settings.getEndsNowByDefault()
                if (nowByDefault === "yes") {
                    timeSwitch.checked = true
                }
                else if(nowByDefault === "no") {
                    timeSwitch.checked = false
                }

                if (description !== qsTr("No description")) {
                    descriptionTextArea.text = description
                }

                if(dateText !== qsTr("Today")) {
                    updateDateText()
                }

                // Rounding should happen before updating the values visible
                if (!editMode) {
                    doRoundToNearest()
                }

                if (breakDuration > 0) {
                    updateBreakDuration()
                    updateNetDuration()
                }

                updateDuration()
                updateStartTime()
                projectCombo.init()
            }
        }
    }

    onDone: {
        if (result == DialogResult.Accepted) {
            saveHours()

            if (dataContainer != null) {
                page.dataContainer.getHours()

            }
        }

        if(fromCover) {
            appWindow.deactivate()

        }
    }

    Banner {
        id: banner
    }
}
