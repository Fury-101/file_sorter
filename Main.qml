import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// import QtQuick.Dialogs
import FileIO 1.0

Window {
    id: root
    visible: true
    width: 640
    height: 480
    title: qsTr("Drop Area")


    ColumnLayout {
        anchors.fill: parent;

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("File Sorter")
            font.pointSize: 24
            horizontalAlignment: Text.AlignHCenter

        }

        Rectangle {
            id: dropContainer
            Layout.fillWidth: true
            height: 200

            Image {
                height: 200
                width: 200
                anchors.centerIn: parent

                source: "pics/file_upload.svg"
            }

            DropArea {
                Layout.alignment: Qt.AlignHCenter
                id: dropArea
                anchors.fill: parent
                onEntered: (drag) => {
                    dropContainer.color = "gray";
                    drag.accept(Qt.LinkAction);
                }
                onDropped: (drop) => {           
                    console.log("got these files: " + drop.urls);

                    for (const u of drop.urls) {
                        if (String(u).slice(0, 8) !== "file:///") {
                            console.log('invalid dropped thingy - was that a file/folder???')
                        }

                        let fp = String(u).slice(8).replace(/\//g, '\\');
                        let children = rulesFile.dirList(fp)
                        let filePaths = [];
                        if (rulesFile.isDir(fp)) {
                            filePaths = children.slice(2).map(e => fp + '\\' + e);
                        } else {
                            filePaths = [fp];
                        }

                        for (const fpath of filePaths) {
                            let tmp = String(fpath).split("\\");
                            let fn = tmp[tmp.length - 1];

                            let jdata = rules.getData();
                            for (const list of jdata) {
                                let [regex, targetPath, enabled] = list;
                                if (!enabled) {
                                    continue;
                                }
                                let re = new RegExp(regex);
                                if (re.test(fn)) {
                                    console.log('attempting to do this file move: ' + fpath + " -> " + targetPath + "\\" + fn);
                                    // rulesFile.move(fp, targetPath + "\\" + fn);
                                    break;
                                }
                            }
                        }
                    }

                    dropContainer.color = "white"
                }
                onExited: {
                    dropContainer.color = "white";
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Sorting Rules")
            onClicked: {
                rulesContainer.visible = !rulesContainer.visible;
            }
        }

        FileIO {
            id: rulesFile
            source: DataLocation
            onError: console.log(msg)
        }

        ListModel {
            id: rulesList
            // ListElement {
            //     name: "Desktop"
            //     path: DesktopLocation
            //     enabled: true
            // }
            // ListElement {
            //     name: "Downloads"
            //     path: DownloadLocation
            //     enabled: true
            // }
            Component.onCompleted: {
                let data = JSON.parse(rulesFile.read());

                for (const list of data) {
                    let regex = list[0];
                    let path = list[1];
                    let enabled = list[2];
                    rulesList.append({"regex": regex, "path": path, "boxEnabled": enabled});
                }
            }
        }

        Component {
            id: ruleItem
            RowLayout {
                width: parent.width
                CheckBox {
                    checked: boxEnabled
                }
                TextField {
                    Layout.fillWidth: true
                    text: regex
                }
                Text {
                    text:  "->"
                }
                TextField {
                    Layout.fillWidth: true
                    text: path
                }
            }
        }
        FileDialog {
            id: fileDialog
            title: "Please choose a file"
            folder: shortcuts.home
            onAccepted: {
                console.log("You chose: " + fileDialog.fileUrls)
                Qt.quit()
            }
            onRejected: {
                console.log("Canceled")
                Qt.quit()
            }
            Component.onCompleted: visible = true
        }

        ColumnLayout {
            id: rulesContainer
            Layout.fillWidth: true;
            height: 150
            visible: false

            ListView {
                id: rules
                height: 100 //TODO: not hardcode
                Layout.fillWidth: true;

                model: rulesList
                delegate: ruleItem

                ScrollBar.vertical: ScrollBar {
                    active: true
                }

                function getData() {
                    let jdata = [];
                    for (const el of rules.contentItem.children) {
                        if (el.children.length !== 4) continue;
                        let regex = el.children[1].text;
                        let path = el.children[3].text;
                        let checked = el.children[0].checked;
                        jdata.push([regex, path, checked]);
                    }
                    return jdata;
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Add Rule")
                onClicked: {
                    rulesList.append({});
                }
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Save Rules")
                onClicked: {
                    let jdata = rules.getData();

                    console.log("saving following data:")
                    console.log(JSON.stringify(jdata));
                    rulesFile.write(JSON.stringify(jdata));
                }
            }
        }

    }
}
