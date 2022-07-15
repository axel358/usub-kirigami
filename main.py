import sys
import urllib.parse as urlparse
from PySide2.QtGui import QStandardItem, QStandardItemModel
from PySide2.QtWidgets import QApplication
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtCore import QObject, Signal, Slot, Property, Qt
from youtube_transcript_api import YouTubeTranscriptApi as yt_api
from youtube_transcript_api.formatters import WebVTTFormatter


class MainWindow(QObject):

    LANGUAGE_ROLE = Qt.UserRole
    LANGUAGE_CODE_ROLE = Qt.UserRole + 1

    def __init__(self):
        QObject.__init__(self)
        self._model = QStandardItemModel()
        self._model.setItemRoleNames(
            {self.LANGUAGE_ROLE: b"language", self.LANGUAGE_CODE_ROLE: b"language_code"})

    def get_model(self):
        return self._model

    model = Property(QObject, fget=get_model, constant=True)

    showToast = Signal(str)

    @Slot(str)
    def parseUrl(self, url):
        video_id = self.get_video_id(url)
        if video_id:
            try:
                self._subs = yt_api.list_transcripts(video_id)
                self.updateList()
            except Exception as e:
                self.showToast.emit('Cannot get subs for the current video')
        else:
            self.showToast.emit('Please enter a valid link')

    def updateList(self):
        self._model.clear()
        for sub in self._subs:
            item = QStandardItem()
            item.setData(sub.language, self.LANGUAGE_ROLE)
            item.setData(sub.language_code, self.LANGUAGE_CODE_ROLE)
            self._model.appendRow(item)

    @Slot(str, str, str)
    def downloadSub(self, language_code, file, translate_code):
        sub = self.getSub(language_code)
        print('code'+translate_code)
        if translate_code:
            sub = sub.translate(translate_code).fetch()
        else:
            sub = sub.fetch()
        self.saveSub(file.replace('file://', ''), sub)
        self.showToast.emit('Subtitle saved')

    def saveSub(self, path, subContent):
        formatter = WebVTTFormatter()
        sub = formatter.format_transcript(subContent)
        with open(path, 'w') as file:
            file.write(sub)

    def getSub(self, language_code):
        return self._subs.find_transcript([language_code])

    def get_video_id(self, url):
        url_data = urlparse.urlparse(url)
        if url_data.hostname == 'youtu.be':
            return url_data.path[1:]
        if url_data.hostname in ('www.youtube.com', 'youtube.com', 'm.youtube.com'):
            if url_data.path == '/watch':
                query = urlparse.parse_qs(url_data.query)
                return query['v'][0]
            if url_data.path[:7] == '/embed/':
                return url_data.path.split('/')[2]
            if url_data.path[:3] == '/v/':
                return url_data.path.split('/')[2]
        return None


if __name__ == '__main__':
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()
    main = MainWindow()

    engine.rootContext().setContextProperty('backend', main)
    engine.load('main.qml')

    sys.exit(app.exec_())
