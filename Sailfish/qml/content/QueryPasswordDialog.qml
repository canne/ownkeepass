/***************************************************************************
**
** Copyright (C) 2013 Marko Koschak (marko.koschak@tisno.de)
** All rights reserved.
**
** This file is part of ownKeepass.
**
** ownKeepass is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 2 of the License, or
** (at your option) any later version.
**
** ownKeepass is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with ownKeepass. If not, see <http://www.gnu.org/licenses/>.
**
***************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"
import "../scripts/Global.js" as Global

Dialog {
    id: queryPasswordDialog

    // set default state
    state: "CreateNewDatabase"

    // These data is coming-in in case for opening a recent database and passed further
    // in all cases/states after accepting this dialog
    property alias dbFileLocation: dbFileLocationComboBox.currentIndex
    property alias dbFilePath: dbFilePathField.text
    property alias useKeyFile: useKeyFileSwitch.checked
    property alias keyFileLocation: keyFileLocationComboBox.currentIndex
    property alias keyFilePath: keyFilePathField.text
    property alias loadLastDb: openAutomaticallySwitch.checked
    // Password is only going out and will be passed to kdbDatabase object open the database
    property alias password: passwordField.text

    acceptDestination: Qt.resolvedUrl("GroupsAndEntriesPage.qml").toString()
    acceptDestinationProperties: { "initOnPageConstruction": false, "groupId": 0 }
    acceptDestinationAction: PageStackAction.Replace

    function showWarning() {
        applicationWindow.infoPopupRef.show(Global.info, "Warning", "Please make sure to use a key file for \
additional security for your Keepass database when storing it online!")
    }

    SilicaFlickable {
        anchors.fill: parent
        width: parent.width
        contentHeight: col.height

        PullDownMenu {
            id: queryPasswordMenu
            MenuLabel {
                text: applicationWindow.databaseUiName
            }
        }

        ApplicationMenu {
            id: queryPasswordDialogAppMenu
        }

        VerticalScrollDecorator {}

        Column {
            id: col
            width: parent.width
            height: children.height
            spacing: Theme.paddingLarge

            DialogHeader {
                id: queryPasswordDialogHeader
            }

            Column {
                id: dbFileColumn
                visible: enabled
                width: parent.width
                spacing: 0

                SilicaLabel {
                    text: qsTr("Specify location, path and file name of your new Keepass database:")
                }

                ComboBox {
                    id: dbFileLocationComboBox
                    width: parent.width
                    label: qsTr("Database location:")
                    currentIndex: 0
                    menu: ContextMenu {
                        MenuItem { text: qsTr("Documents on phone") }
                        MenuItem { id: dbLocSdCard; text: qsTr("SD card") }
                        MenuItem { text: qsTr("Android storage") }
                        MenuItem { text: qsTr("Sailbox local storage") }
                    }
                    onCurrentIndexChanged: {
                        // Warn about usage of Android storage
                        if (currentIndex === 2) {
                            applicationWindow.infoPopupRef.show(Global.info, qsTr("Warning"), qsTr("Please be aware that using the \
Android storage might cause problems due to different file ownership and permissions. If modifications to your \
Keepass database are not saved make sure the file is writable for user \"nemo\". So if you don't know how to handle \
file permissions in the terminal on your Jolla phone it would be wise not to use Android storage. Sorry for that."))
                        }
                        // When opening database from dropbox storage show warning if no key file is used
                        else if ((queryPasswordDialog.state === "OpenNewDatabase") &&
                                 (!useKeyFileSwitch.checked) && (currentIndex === 3)) {
                            showWarning()
                        }
                        // When creating database on dropbox storage force usage of key file
                        else if ((queryPasswordDialog.state === "CreateNewDatabase") &&
                                 (currentIndex === 3)) {
                            useKeyFileSwitch.enabled = false
                            useKeyFileSwitch.checked = true
                            applicationWindow.infoPopupRef.show(Global.info, qsTr("Advice"), qsTr("You choosed to place your new \
Keepass database in the Dropbox cloud. Please make sure to use a unique password for Dropbox \
and enable two-step verification to increase security of your online storage! \
ownKeepass does enforce to use a locally stored key \
file when storing your Keepass database online."))
                        } else {
                            useKeyFileSwitch.enabled = true
                        }
                    }
                }

                TextField {
                    id: dbFilePathField
                    width: parent.width
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    label: qsTr("Path and name of database file")
                    placeholderText: qsTr("Set path and name of database file")
                    errorHighlight: text === ""
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        if (useKeyFileSwitch.checked) {
                            keyFilePathField.focus = true
                        } else {
                            passwordField.focus = true
                        }
                    }
                }
            }

            Column {
                id: keyFileColumn
                visible: enabled
                width: parent.width
                spacing: 0

                TextSwitch {
                    id: useKeyFileSwitch
                    checked: false
                    text: qsTr("Use key file")
                    description: qsTr("Switch this on to use a key file together with a master password for your new Keepass database")
                    onCheckedChanged: {
                        // When opening database from dropbox storage show warning if no key file is used
                        if ((queryPasswordDialog.state === "OpenNewDatabase") &&
                                (!checked) && (dbFileLocationComboBox.currentIndex === 3)) {
                            showWarning()
                        }
                    }
                }

                Column {
                    enabled: useKeyFile
                    opacity: enabled ? 1.0 : 0.0
                    height: enabled ? children.height : 0
                    width: parent.width
                    spacing: 0
                    Behavior on opacity { NumberAnimation { duration: 500 } }
                    Behavior on height { NumberAnimation { duration: 500 } }

                    ComboBox {
                        id: keyFileLocationComboBox
                        width: parent.width
                        label: qsTr("Key file location:")
                        currentIndex: 0
                        menu: ContextMenu {
                            MenuItem { text: qsTr("Documents on phone") }
                            MenuItem { id: keyFileLocSdCard; text: qsTr("SD card") }
                            MenuItem { text: qsTr("Android storage") }
                        }
                    }

                    TextField {
                        id: keyFilePathField
                        width: parent.width
                        inputMethodHints: Qt.ImhUrlCharactersOnly
                        label: qsTr("Path and name of key file")
                        placeholderText: qsTr("Set path and name of key file")
                        errorHighlight: text === ""
                        EnterKey.enabled: text.length > 0
                        EnterKey.iconSource: "image://theme/icon-m-enter-next"
                        EnterKey.onClicked: passwordField.focus = true
                    }
                }
            }

            SilicaLabel {
                id: passwordTitle
            }

            Item {
                width: parent.width
                height: passwordField.height

                TextField {
                    id: passwordField
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: showPasswordButton.left
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                    echoMode: TextInput.Password
                    errorHighlight: text.length === 0
                    label: qsTr("Password")
                    placeholderText: qsTr("Enter password")
                    text: ""
                    EnterKey.enabled: !errorHighlight
                    EnterKey.highlighted: queryPasswordDialog.state !== "CreateNewDatabase" && text !== ""
                    EnterKey.iconSource: queryPasswordDialog.state === "CreateNewDatabase" ?
                                             "image://theme/icon-m-enter-next" :
                                             "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: {
                        if (queryPasswordDialog.state === "CreateNewDatabase") {
                            confirmPasswordField.focus = true
                        } else {
                            // set database name for pulley menu on opening database
                            applicationWindow.databaseUiName = Global.getLocationName(dbFileLocation) + " " + dbFilePath
                            parent.focus = true
                            accept()
                            close()
                        }
                    }
                    focusOutBehavior: -1
                }

                IconButton {
                    id: showPasswordButton
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: passwordField.echoMode === TextInput.Normal ? "../../wallicons/icon-l-openeye.png" : "../../wallicons/icon-l-closeeye.png"
                    onClicked: {
                        if (passwordField.echoMode === TextInput.Normal) {
                            passwordField.echoMode =
                                    confirmPasswordField.echoMode = TextInput.Password
                        } else {
                            passwordField.echoMode =
                                    confirmPasswordField.echoMode = TextInput.Normal
                        }
                    }
                }
            }

            TextField {
                id: confirmPasswordField
                width: parent.width
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                echoMode: TextInput.Password
                visible: enabled
                errorHighlight: passwordField.text !== text
                label: qsTr("Confirm password")
                placeholderText: label
                text: ""
                EnterKey.enabled: !passwordField.errorHighlight && !errorHighlight
                EnterKey.highlighted: !errorHighlight
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    // set database name for pulley menu on creating database
                    applicationWindow.databaseUiName = Global.getLocationName(dbFileLocation) + " " + dbFilePath
                    parent.focus = true
                    accept()
                    close()
                }
                focusOutBehavior: -1
            }

            TextSwitch {
                id: openAutomaticallySwitch
                text: qsTr("Open automatically")
            }
        }
    }

    Component.onCompleted: {
        // check if SD card is present and enable
        var sdEnabled = ownKeepassHelper.sdCardExists()
        dbLocSdCard.enabled = sdEnabled
        keyFileLocSdCard.enabled = sdEnabled
    }

    states: [
        State {
            name: "CreateNewDatabase"
            PropertyChanges { target: queryPasswordDialogHeader; acceptText: qsTr("Create") }
            PropertyChanges { target: queryPasswordDialogHeader; title: qsTr("New Password Safe") }
            PropertyChanges { target: dialogTitle; text: qsTr("New Password Safe") }
            PropertyChanges { target: dbFileColumn; enabled: true }
            PropertyChanges { target: keyFileColumn; enabled: true }
            PropertyChanges { target: passwordTitle; text: qsTr("Type in a master password for locking your new Keepass Password Safe:") }
            PropertyChanges { target: confirmPasswordField; enabled: true }
            PropertyChanges { target: queryPasswordDialog
                canNavigateForward: !passwordField.errorHighlight &&
                                    !confirmPasswordField.errorHighlight &&
                                    !dbFilePathField.errorHighlight && (useKeyFile ? !keyFilePathField.errorHighlight : true )
            }
            PropertyChanges { target: passwordField; focus: false }
            PropertyChanges { target: queryPasswordMenu; enabled: false; visible: false }
            PropertyChanges { target: queryPasswordDialogAppMenu; helpContent: "CreateNewDatabase" }
            PropertyChanges { target: applicationWindow.cover; state: "CREATE_NEW_DATABASE" }
        },
        State {
            name: "OpenNewDatabase"
            PropertyChanges { target: queryPasswordDialogHeader; acceptText: qsTr("Open") }
            PropertyChanges { target: queryPasswordDialogHeader; title: qsTr("Password Safe") }
            PropertyChanges { target: dbFileColumn; enabled: true }
            PropertyChanges { target: keyFileColumn; enabled: true }
            PropertyChanges { target: passwordTitle; text: qsTr("Type in master password for unlocking your Keepass Password Safe:") }
            PropertyChanges { target: confirmPasswordField; enabled: false }
            PropertyChanges { target: queryPasswordDialog
                canNavigateForward: !passwordField.errorHighlight &&
                                    !dbFilePathField.errorHighlight && (useKeyFile ? !keyFilePathField.errorHighlight : true )
            }
            PropertyChanges { target: passwordField; focus: false }
            PropertyChanges { target: queryPasswordMenu; enabled: false; visible: false }
            PropertyChanges { target: queryPasswordDialogAppMenu; helpContent: "OpenNewDatabase" }
            PropertyChanges { target: applicationWindow.cover; state: "OPEN_DATABASE" }
        },
        State {
            name: "OpenRecentDatabase"
            PropertyChanges { target: queryPasswordDialogHeader; acceptText: qsTr("Open") }
            PropertyChanges { target: queryPasswordDialogHeader; title: qsTr("Password Safe") }
            PropertyChanges { target: dbFileColumn; enabled: false }
            PropertyChanges { target: keyFileColumn; enabled: false }
            PropertyChanges { target: passwordTitle; text: qsTr("Type in master password for unlocking your Keepass Password Safe:") }
            PropertyChanges { target: confirmPasswordField; enabled: false }
            PropertyChanges { target: queryPasswordDialog; canNavigateForward: passwordField.text !== "" }
            PropertyChanges { target: passwordField; focus: true }
            PropertyChanges { target: queryPasswordMenu; enabled: true; visible: true }
            PropertyChanges { target: queryPasswordDialogAppMenu; helpContent: "OpenRecentDatabase" }
            PropertyChanges { target: applicationWindow.cover; state: "DATABASE_LOCKED"
                title: queryPasswordDialog.dbFilePath.substring(
                                  queryPasswordDialog.dbFilePath.lastIndexOf("/") + 1, queryPasswordDialog.dbFilePath.length)
            }
        }
    ]
}
