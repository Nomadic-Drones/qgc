import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.AppSettings

import Custom.Streams

SettingsPage {
    property var    _settingsManager:            QGroundControl.settingsManager
    property var    _videoManager:              QGroundControl.videoManager
    property var    _videoSettings:             _settingsManager.videoSettings
    property string _videoSource:               _videoSettings.videoSource.rawValue
    property bool   _isGST:                     _videoManager.gstreamerEnabled
    property bool   _isStreamSource:            _videoManager.isStreamSource
    property bool   _isUDP264:                  _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:                  _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                    _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                     _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:                  _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:     _videoManager.autoStreamConfigured
    property bool   _videoSourceDisabled:       _videoSource === _videoSettings.disabledVideoSource
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 40
    property bool   _requiresUDPUrl:            _isUDP264 || _isUDP265 || _isMPEGTS


    QGCPalette { id: qgcPal }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Video Source")
        headingDescription: _videoAutoStreamConfig ? qsTr("Mavlink camera stream is automatically configured") : ""
        enabled:            !_videoAutoStreamConfig

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Source")
            indexModel:         false
            fact:               _videoSettings.videoSource
            visible:            fact.visible
        }
    }

    // RTSP stream management (replaces Connection section when RTSP selected)
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("RTSP Streams")
        visible:            !_videoSourceDisabled && !_videoAutoStreamConfig && _isRTSP

        Repeater {
            model: RtspStreamSwitcher.streamNames

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                Rectangle {
                    width:  ScreenTools.defaultFontPixelWidth * 0.5
                    height: parent.height * 0.6
                    radius: width / 2
                    color:  index === RtspStreamSwitcher.currentIndex ? qgcPal.colorGreen : "transparent"
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    QGCLabel {
                        text:       modelData
                        font.bold:  index === RtspStreamSwitcher.currentIndex
                    }
                    QGCLabel {
                        text:           RtspStreamSwitcher.streamUrls[index] || ""
                        font.pointSize: ScreenTools.smallFontPointSize
                        color:          qgcPal.colorGrey
                    }
                }

                QGCButton {
                    text: qsTr("Use")
                    visible: index !== RtspStreamSwitcher.currentIndex
                    onClicked: RtspStreamSwitcher.switchToStream(index)
                }

                QGCButton {
                    text: qsTr("Edit")
                    onClicked: editDialogComponent.createObject(mainWindow, {
                        editIndex: index,
                        initialName: RtspStreamSwitcher.streamNames[index],
                        initialUrl: RtspStreamSwitcher.streamUrls[index]
                    }).open()
                }

                QGCButton {
                    text: qsTr("Remove")
                    enabled: RtspStreamSwitcher.streamNames.length > 1
                    onClicked: RtspStreamSwitcher.removeStream(index)
                }
            }
        }

        QGCButton {
            text: qsTr("Add Stream")
            onClicked: editDialogComponent.createObject(mainWindow, {
                editIndex: -1, initialName: "", initialUrl: "rtsp://"
            }).open()
        }
    }

    // Non-RTSP connection fields (TCP / UDP)
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Connection")
        visible:            !_videoSourceDisabled && !_videoAutoStreamConfig && (_isTCP || _requiresUDPUrl)

        LabelledFactTextField {
            Layout.fillWidth:           true
            label:                      qsTr("TCP URL")
            textFieldPreferredWidth:    _urlFieldWidth
            fact:                       _videoSettings.tcpUrl
            visible:                    _isTCP && _videoSettings.tcpUrl.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    _urlFieldWidth
            label:                      qsTr("UDP URL")
            fact:                       _videoSettings.udpUrl
            visible:                    _requiresUDPUrl && _videoSettings.udpUrl.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")
        visible:            !_videoSourceDisabled

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Aspect Ratio")
            fact:               _videoSettings.aspectRatio
            visible:            !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Stop recording when disarmed")
            fact:               _videoSettings.disableWhenDisarmed
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Low Latency Mode")
            fact:               _videoSettings.lowLatencyMode
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible && _isGST
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Video decode priority")
            fact:               _videoSettings.forceVideoDecoder
            visible:            fact.visible
            indexModel:         false
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading:            qsTr("Local Video Storage")

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Record File Format")
            fact:               _videoSettings.recordingFormat
            visible:            _videoSettings.recordingFormat.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto-Delete Saved Recordings")
            fact:               _videoSettings.enableStorageLimit
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Max Storage Usage")
            fact:               _videoSettings.maxVideoSize
            visible:            fact.visible
            enabled:            _videoSettings.enableStorageLimit.rawValue
        }
    }

    Component {
        id: editDialogComponent

        QGCPopupDialog {
            title:              editIndex < 0 ? qsTr("Add Stream") : qsTr("Edit Stream")
            buttons:            Dialog.Save | Dialog.Cancel
            acceptButtonEnabled: nameField.text.length > 0 && urlField.text.length > 0

            property int    editIndex
            property string initialName
            property string initialUrl

            onAccepted: {
                if (editIndex < 0)
                    RtspStreamSwitcher.addStream(nameField.text, urlField.text)
                else
                    RtspStreamSwitcher.editStream(editIndex, nameField.text, urlField.text)
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                QGCLabel { text: qsTr("Name") }
                QGCTextField {
                    id:                 nameField
                    Layout.fillWidth:   true
                    text:               initialName
                    placeholderText:    qsTr("Stream name")
                }

                QGCLabel { text: qsTr("RTSP URL") }
                QGCTextField {
                    id:                 urlField
                    Layout.fillWidth:   true
                    text:               initialUrl
                    placeholderText:    qsTr("rtsp://...")
                }
            }
        }
    }
}
