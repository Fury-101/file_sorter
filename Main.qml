import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FileIO 1.0
// import QStandardPaths

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
                        let fp = String(u).slice(8).replace(/\//g, '\\');
                        let jdata = rules.getData();
                        for (const regex in jdata) {
                            let targetPath = jdata[regex][0];
                            let enabled = jdata[regex][1];
                            if (!enabled) {
                                continue;
                            }
                            let re = new RegExp(regex);
                            let tmp = String(fp).split("\\");
                            let fn = tmp[tmp.length - 1];
                            console.log(fn);
                            if (re.test(fn)) {
                                console.log('attempting to do this file move: ' + fp + " -> " + targetPath + "\\" + fn);
                                rulesFile.move(fp, targetPath + "\\" + fn);
                                break;
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

                for (const regex in data) {
                    rulesList.append({"regex": regex, "path": data[regex][0], "boxEnabled": data[regex][1]});
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
                    let jdata = {};
                    for (const el of rules.contentItem.children) {
                        if (el.children.length !== 4) continue;
                        jdata[el.children[1].text] = [el.children[3].text, el.children[0].checked];
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

                    console.log(JSON.stringify(jdata));
                    console.log("saving following data:")
                    rulesFile.write(JSON.stringify(jdata));
                }
            }
        }

    }
}
