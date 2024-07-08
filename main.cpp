#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QQmlContext>
#include <json.hpp>
#include <sys/stat.h>
#include <fstream>
#include <algorithm>
#include <filesystem>
#include "fileio.h"

using json = nlohmann::json;

inline bool check_exists (const std::string& name) {
    struct stat buffer;
    return (stat (name.c_str(), &buffer) == 0);
}

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/file_sorter/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    std::string DesktopLocation = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation).toStdString();
    std::replace (DesktopLocation.begin(), DesktopLocation.end(), '/', '\\');
    std::string DownloadLocation = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation).toStdString();
    std::replace (DownloadLocation.begin(), DownloadLocation.end(), '/', '\\');
    engine.rootContext()->setContextProperty("DownloadLocation", QString::fromStdString(DownloadLocation));
    std::string DocumentsLocation = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation).toStdString();
    std::replace (DocumentsLocation.begin(), DocumentsLocation.end(), '/', '\\');
    std::string MusicLocation = QStandardPaths::writableLocation(QStandardPaths::MusicLocation).toStdString();
    std::replace (MusicLocation.begin(), MusicLocation.end(), '/', '\\');
    std::string MoviesLocation = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation).toStdString();
    std::replace (MoviesLocation.begin(), MoviesLocation.end(), '/', '\\');
    std::string PicturesLocation = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation).toStdString();
    std::replace (PicturesLocation.begin(), PicturesLocation.end(), '/', '\\');

    std::string AppdataLocation = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation).toStdString();
    std::replace (AppdataLocation.begin(), AppdataLocation.end(), '/', '\\');
    engine.rootContext()->setContextProperty("AppdataLocation", QString::fromStdString(AppdataLocation));

    std::string DataLocation = AppdataLocation + "\\data.json";
    engine.rootContext()->setContextProperty("DataLocation", QString::fromStdString(DataLocation));

    if (!std::filesystem::exists(AppdataLocation)) {
        std::filesystem::create_directory(AppdataLocation);
    }

    if (!check_exists(DataLocation)) {
        std::ofstream file(DataLocation);
        json jsonData = {
            {"\\S+?(?:pdf|epub|doc|docx)", DocumentsLocation, true},
            {"\\S+?(?:wav|mp3|flac)", MusicLocation, true},
            {"\\S+?(?:mp4|mov|mpeg|m4v|mkv)", MoviesLocation, true},
            {"\\S+?(?:jpe?g|png|gif|svg|bmp|tiff|heic|webp|heif|avif)", PicturesLocation, true},
            {".+", DownloadLocation, true}
        };
        file << jsonData;
    }
    qDebug() << "data is at: " << DataLocation;
    qDebug() << "program knows data exists? - " << check_exists(DataLocation);

    qmlRegisterType<FileIO, 1>("FileIO", 1, 0, "FileIO");

    engine.load(url);

    return app.exec();
}
