import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools

import Custom.Streams

Item {
    id: _root

    property var parentToolInsets
    property var totalToolInsets: _toolInsets
    property var mapControl

    property var  _videoManager:    QGroundControl.videoManager
    property bool _hasMultiple:     RtspStreamSwitcher.streamNames.length > 1
    property bool _videoActive:     _videoManager ? _videoManager.hasVideo : false
    property real _toolsMargin:     ScreenTools.defaultFontPixelWidth * 0.75

    QGCPalette { id: qgcPal }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    // Stream switcher pill button
    Rectangle {
        id:                         streamButton
        visible:                    _hasMultiple && _videoActive && mapControl.pipState.state !== mapControl.pipState.fullState
        anchors.left:               parent.left
        anchors.leftMargin:         parentToolInsets.leftEdgeTopInset + _toolsMargin
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        width:                      streamRow.implicitWidth + ScreenTools.defaultFontPixelWidth * 3.5
        height:                     ScreenTools.defaultFontPixelHeight * 2.5
        radius:                     height / 2
        color:                      qgcPal.window
        opacity:                    0.85

        property bool _decoding: _videoManager && _videoManager.decoding

        Row {
            id:                 streamRow
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelWidth * 0.6

            Rectangle {
                id:                     statusDot
                width:                  ScreenTools.defaultFontPixelHeight * 0.75
                height:                 width
                radius:                 width / 2
                color:                  streamButton._decoding ? qgcPal.colorGreen : "#FFA500"
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running:    streamButton.visible && !streamButton._decoding
                    loops:      Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    onRunningChanged: if (!running) statusDot.opacity = 1.0
                }
            }

            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                color:                  qgcPal.text
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   RtspStreamSwitcher.streamNames[RtspStreamSwitcher.currentIndex] || ""
            }


        }

        MouseArea {
            anchors.fill: parent
            onClicked:    streamPopup.open()
        }
    }

    // Stream selection popup
    Popup {
        id:         streamPopup
        x:          streamButton.x + (streamButton.width - width) / 2
        y:          streamButton.y + streamButton.height + ScreenTools.defaultFontPixelHeight * 0.5
        width:      ScreenTools.defaultFontPixelWidth * 30
        padding:    ScreenTools.defaultFontPixelHeight * 0.5

        background: Rectangle {
            color:  qgcPal.window
            radius: ScreenTools.defaultFontPixelWidth
            border.color: qgcPal.windowShade
            border.width: 1
        }

        ColumnLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelHeight * 0.25

            Repeater {
                model: RtspStreamSwitcher.streamNames

                Rectangle {
                    Layout.fillWidth:   true
                    height:             ScreenTools.defaultFontPixelHeight * 2.5
                    radius:             ScreenTools.defaultFontPixelWidth * 0.5
                    color:              index === RtspStreamSwitcher.currentIndex ? qgcPal.buttonHighlight : "transparent"

                    QGCLabel {
                        anchors.centerIn:   parent
                        text:               modelData
                        color:              index === RtspStreamSwitcher.currentIndex ? qgcPal.buttonHighlightText : qgcPal.text
                        font.pointSize:     ScreenTools.defaultFontPointSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            RtspStreamSwitcher.switchToStream(index)
                            streamPopup.close()
                        }
                    }
                }
            }
        }
    }
}
