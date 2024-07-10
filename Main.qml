import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
// import QtQuick.Dialogs
import Qt.labs.platform
import FileIO 1.0

Window {
    id: root
    visible: true
    title: qsTr("Drop Area")
    visibility: Window.Maximized
    width: 640
    height: 480

    Material.theme: Material.Light

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
                    const sep = rulesFile.toNativeSeparators("/");
                    console.log("got these files: " + drop.urls);

                    for (const u of drop.urls) {
                        if (String(u).slice(0, 8) !== "file:///") {
                            console.log('invalid dropped thingy - was that a file/folder???')
                        }

                        let fp = rulesFile.toNativeSeparators(String(u).slice(8));
                        let children = rulesFile.dirList(fp)
                        let filePaths = [];

                        if (!recursiveCB.checked) {
                            if (rulesFile.isDir(fp)) {
                                filePaths = children.filter(e => e !== '.' && e !== '..').map(e => fp + sep + e);
                            } else {
                                filePaths = [fp];
                            }

                            for (const fpath of filePaths) {
                                let fn = String(fpath).split(sep).slice(-1)[0];

                                let jdata = rules.getData();
                                for (const list of jdata) {
                                    let [regex, targetPath, enabled] = list;
                                    if (!enabled) {
                                        continue;
                                    }
                                    let re = new RegExp(regex);
                                    if (re.test(fn)) {
                                        console.log('attempting to do this file move: ' + fpath + " -> " + targetPath + sep + fn);
                                        rulesFile.move(fp, targetPath + sep + fn);
                                        break;
                                    }
                                }
                            }
                        } else {
                            const handleChild = fullpath => {
                                let fn = fullpath.split(sep).slice(-1)[0];
                                if (rulesFile.isDir(fullpath)) {
                                    console.log(rulesFile.dirList(fullpath));
                                    for (const fpath of rulesFile.dirList(fullpath).filter(e => e !== '.' && e !== '..').map(e => fullpath + sep + e)) {
                                        console.log(fpath);
                                        console.log('currently looking at this file: ' + fpath);
                                        handleChild(fpath);
                                    }
                                } else {
                                   let jdata = rules.getData();
                                   for (const list of jdata) {
                                       let [regex, targetPath, enabled] = list;
                                       if (!enabled) {
                                           continue;
                                       }
                                       let re = new RegExp(regex);
                                       if (re.test(fn)) {
                                           console.log('attempting to do this file move: ' + fullpath + " -> " + targetPath + sep + fn);
                                           rulesFile.move(fullp, targetPath + sep + fn);
                                           break;
                                       }
                                   }
                                }
                            }
                            handleChild(fp);
                        }
                    }

                    dropContainer.color = "white"
                }
                onExited: {
                    dropContainer.color = "white";
                }
            }
        }

        CheckBox {
            Layout.alignment: Qt.AlignHCenter
            id: recursiveCB
            text: qsTr("Process Folders Recursively")
            checked: false
            Component.onCompleted: {
                let recursive = JSON.parse(recursiveFile.read());
                recursiveCB.checked = recursive;
            }
            onClicked: {
                recursiveFile.write(recursiveCB.checked);
                console.debug(recursiveCB.checked);
            }
        }

        FileIO {
            id: recursiveFile
            source: RecursiveLocation
            onError: console.log(msg)
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
                    id: rulePath
                    text: path
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            fDialog.open();
                        }
                    }
                    FolderDialog {
                        id: fDialog
                        title: "Please choose a file/folder"
                        currentFolder: DownloadLocation
                        onAccepted: {
                            let fpath = String(this.currentFolder)
                            fpath = rulesFile.toNativeSeparators(fpath.replace(/^(file:\/{3})/,""));
                            console.log(rulePath.text)
                            console.log('setting path to: ' + fpath + ' - previously ' + rulePath.text);
                            rulePath.text = fpath;
                        }
                    }
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
