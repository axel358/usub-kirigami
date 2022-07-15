import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.19
import Qt.labs.platform 1.1

ApplicationWindow
{
    id: root
    title: "USub"
    width: 600
    height: 480
    property string languageCode
    property string translateCode

    Page {
        id: page
        icon.source: "usub.svg"
        anchors.fill: parent
        padding: 0

        header: Controls.ToolBar {
            Layout.fillWidth: true
            id: toolbar
            contentItem: RowLayout{
                Controls.Button {
                    flat: true
                    icon.name: "help-about-symbolic"
                    onClicked: translateDialog.open()
                }
                Controls.TextField {
                    id: urlEntry
                    Layout.fillWidth: true
                    placeholderText : "Video url"
                }

                Controls.Button {
                    flat: true
                    icon.name: "search-symbolic"
                    onClicked: backend.parseUrl(urlEntry.text)
                }
            }
        }

        Controls.ScrollView{
            anchors.fill: parent
            Controls.ScrollBar.horizontal.policy: Controls.ScrollBar.AlwaysOff
            ListView{
                id: listView
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 6
                anchors.bottomMargin: 6
                anchors.fill: parent
                model: backend.model
                delegate: RowLayout{
                    width: listView.width
                    Layout.fillWidth: true

                    Controls.Label{
                        text: language
                        Layout.fillWidth: true
                    }

                    Controls.ToolButton{
                        icon.name: "crow-translate-tray"
                        onClicked: {
                            languageCode = language_code
                            translateDialog.open()
                        }
                    }

                    Controls.ToolButton{
                        onClicked: {
                            saveDialog.currentFile = "file:///" + "subtitle" + language_code + ".srt"
                            languageCode = language_code
                            saveDialog.open()
                        }
                        flat: true
                        icon.color: Kirigami.Theme.highlightColor
                        icon.name: "download"
                    }
                }

            }
        }
        FileDialog {
            id: saveDialog
            title: "Save Dialog"
            //folder: myObjHasAPath? myObj.path: "file:///" //Here you can set your default folder
            fileMode: FileDialog.SaveFile
            onAccepted: {
                backend.downloadSub(languageCode, file, translateCode)
            }
        }

        PromptDialog {
            id: aboutDialog
            showCloseButton: false
            title: "About USub"
            subtitle: "Download and translate subs for your favorite videos"
            standardButtons: Dialog.Ok
        }

        PromptDialog {
            id: translateDialog
            title: "Translate sub"
            showCloseButton: false
            standardButtons: Dialog.NoButton
            customFooterActions: [
            Action {
                text: qsTr("Translate")
                //text.color: Kirigami.Theme.highlightColor
                iconName: "dialog-ok"
                onTriggered: {
                    translateDialog.close();
                }
            },
            Action {
                text: qsTr("Cancel")
                iconName: "dialog-cancel"
                onTriggered: {
                    translateDialog.close();
                }
            }
            ]

            Controls.TextField {
                placeholderText: qsTr("Language code ex: en")
            }
        }

        Connections {
            target: backend

            function onShowToast(message){
                showPassiveNotification(message)
            }
        }
    }
}
