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
import "../scripts/Global.js" as Global
import "../common"

Dialog {
    id: editEntryDetailsDialog

    property bool createNewEntry: false
    // ID of the keepass entry to be edited
    property int entryId: 0
    // creation of new entry needs parent group ID
    property int parentGroupId: 0

    // The following properties are used to check if text of any entry detail was changed. If so,
    // set cover page accordingly to signal the user unsaved changes
    property string origTitle: ""
    property string origUrl: ""
    property string origUsername: ""
    property string origPassword: ""
    property string origComment: ""
    property bool titleChanged: false
    property bool urlChanged: false
    property bool usernameChanged: false
    property bool passwordChanged: false
    property bool commentChanged: false

    function setTextFields(title, url, username, password, comment) {
        entryTitleTextField.text = origTitle = title
        entryUrlTextField.text = origUrl = url
        entryUsernameTextField.text = origUsername = username
        entryPasswordTextField.text = entryVerifyPasswordTextField.text = origPassword = password
        entryCommentTextField.text = origComment = comment
    }

    // This function should be called when any text is changed to check if the
    // cover page state needs to be updated
    function updateCoverState() {
        if (titleChanged || urlChanged || usernameChanged || passwordChanged || commentChanged) {
            applicationWindow.cover.state = "UNSAVED_CHANGES"
        } else {
            applicationWindow.cover.state = "ENTRY_VIEW"
        }
    }

    // forbit page navigation if title is not set and password is not verified
    canNavigateForward: !entryTitleTextField.errorHighlight && !entryVerifyPasswordTextField.errorHighlight

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: col.height

        PullDownMenu {
            MenuLabel {
                enabled: text !== ""
                text: applicationWindow.databaseUiName
            }
        }

        ApplicationMenu {
            disableSettingsItem: true
        }

        // Show a scollbar when the view is flicked, place this over all other content
        VerticalScrollDecorator {}

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                acceptText: qsTr("Save")
            }

            SilicaLabel {
                text: editEntryDetailsDialog.createNewEntry ? qsTr("Create new password entry:") :
                                                              qsTr("Edit password entry:")
            }

            TextField {
                id: entryTitleTextField
                width: parent.width
                inputMethodHints: Qt.ImhSensitiveData
                label: qsTr("Title")
                text: ""
                placeholderText: qsTr("Set title (mandatory)")
                errorHighlight: text.length === 0
                EnterKey.enabled: !errorHighlight
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: entryUrlTextField.focus = true
                onTextChanged: {
                    editEntryDetailsDialog.titleChanged =
                            (editEntryDetailsDialog.origTitle !== text ? true : false)
                    editEntryDetailsDialog.updateCoverState()
                }
                focusOutBehavior: -1 // This doesn't let the eye button steal focus
            }

            TextField {
                id: entryUrlTextField
                width: parent.width
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhSensitiveData
                label: qsTr("URL")
                text: ""
                placeholderText: qsTr("Set URL")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: entryUsernameTextField.focus = true
                onTextChanged: {
                    editEntryDetailsDialog.urlChanged =
                            (editEntryDetailsDialog.origUrl !== text ? true : false)
                    editEntryDetailsDialog.updateCoverState()
                }
                focusOutBehavior: -1
            }

            TextField {
                id: entryUsernameTextField
                width: parent.width
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData
                label: qsTr("Username")
                text: ""
                placeholderText: qsTr("Set username")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: entryPasswordTextField.focus = true
                onTextChanged: {
                    editEntryDetailsDialog.usernameChanged =
                            (editEntryDetailsDialog.origUsername !== text ? true : false)
                    editEntryDetailsDialog.updateCoverState()
                }
                focusOutBehavior: -1
            }

            Item {
                width: parent.width
                height: entryPasswordTextField.height

                TextField {
                    id: entryPasswordTextField
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: showPasswordButton.left
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                    echoMode: TextInput.Password
                    label: qsTr("Password")
                    text: ""
                    placeholderText: qsTr("Set password")
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: entryVerifyPasswordTextField.focus = true
                    onTextChanged: {
                        editEntryDetailsDialog.passwordChanged =
                                (editEntryDetailsDialog.origPassword !== text ? true : false)
                        editEntryDetailsDialog.updateCoverState()
                    }
                    focusOutBehavior: -1
                }

                IconButton {
                    id: showPasswordButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    icon.source: entryPasswordTextField.echoMode === TextInput.Normal ? "../../wallicons/icon-l-openeye.png" : "../../wallicons/icon-l-closeeye.png"
                    onClicked: {
                        if (entryPasswordTextField.echoMode === TextInput.Normal) {
                            entryPasswordTextField.echoMode =
                                    entryVerifyPasswordTextField.echoMode = TextInput.Password
                        } else {
                            entryPasswordTextField.echoMode =
                                    entryVerifyPasswordTextField.echoMode = TextInput.Normal
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: entryVerifyPasswordTextField.height

                TextField {
                    id: entryVerifyPasswordTextField
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: generatePasswordButton.left
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                    echoMode: TextInput.Password
                    label: qsTr("Verify password")
                    text: ""
                    placeholderText: qsTr("Verify password")
                    errorHighlight: entryPasswordTextField.text !== text
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        // if password not yet verified go back to password field
                        if (entryPasswordTextField.text !== text) {
                            entryPasswordTextField.focus = true
                        } else {
                            entryCommentTextField.focus = true
                        }
                    }
                    focusOutBehavior: -1
                }

                IconButton {
                    id: generatePasswordButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    icon.source: "../../wallicons/icon-l-generator.png"
                    onClicked: {
                        var pwGenDialog = pageStack.push("PasswordGeneratorDialog.qml")
                        pwGenDialog.accepted.connect(function() {
                            entryPasswordTextField.text =
                                    entryVerifyPasswordTextField.text = pwGenDialog.generatedPassword
                        })
                    }
                }
            }

            TextArea {
                id: entryCommentTextField
                width: parent.width
                label: qsTr("Comment")
                text: ""
                placeholderText: qsTr("Set comment")
                onTextChanged: {
                    editEntryDetailsDialog.commentChanged =
                            (editEntryDetailsDialog.origComment !== text ? true : false)
                    editEntryDetailsDialog.updateCoverState()
                }
                focusOutBehavior: -1
            }
        }
    }

    Component.onCompleted: {
        // set reference in kdbListItemInternal object
        kdbListItemInternal.editEntryDetailsDialogRef = editEntryDetailsDialog

        kdbEntry.entryId = editEntryDetailsDialog.entryId
        if (!createNewEntry) {
            kdbEntry.loadEntryData()
        }
        entryTitleTextField.focus = true
    }
    Component.onDestruction: {
        // unset again
        kdbListItemInternal.editEntryDetailsDialogRef = null
    }

    // user wants to save new entry data
    onAccepted: {
        // first save locally Kdb entry details then trigger save to backend
        kdbListItemInternal.setKdbEntryDetails(createNewEntry,
                                    entryId,
                                    parentGroupId,
                                    entryTitleTextField.text,
                                    entryUrlTextField.text,
                                    entryUsernameTextField.text,
                                    entryPasswordTextField.text,
                                    entryCommentTextField.text)
        kdbListItemInternal.saveKdbEntryDetails()
    }
    // user has rejected editing entry data, check if there are unsaved details
    onRejected: {
        // no need for saving if input fields are invalid
        if (canNavigateForward) {
            // first save locally Kdb entry details then trigger check for unsaved changes
            kdbListItemInternal.setKdbEntryDetails(createNewEntry,
                                        entryId,
                                        parentGroupId,
                                        entryTitleTextField.text,
                                        entryUrlTextField.text,
                                        entryUsernameTextField.text,
                                        entryPasswordTextField.text,
                                        entryCommentTextField.text)
            kdbListItemInternal.checkForUnsavedKdbEntryChanges()
        }
    }
}
