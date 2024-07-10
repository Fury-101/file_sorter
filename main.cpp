#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QString>
#include <QQmlContext>
#include <json.hpp>
#include <sys/stat.h>
#include <fstream>
#include <algorithm>
#include <filesystem>
#include "fileio.h"
// #include <QLibraryInfo>

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

    std::string sep = FileIO::toNativeSeparators("/").toStdString();

    std::string DesktopLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation)).toStdString();
    std::string DownloadLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)).toStdString();
    engine.rootContext()->setContextProperty("DownloadLocation", QString::fromStdString(DownloadLocation));
    std::string DocumentsLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)).toStdString();
    std::string MusicLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::MusicLocation)).toStdString();
    std::string MoviesLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::MoviesLocation)).toStdString();
    std::string PicturesLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::PicturesLocation)).toStdString();

    std::string AppdataLocation = FileIO::toNativeSeparators(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)).toStdString();
    engine.rootContext()->setContextProperty("AppdataLocation", QString::fromStdString(AppdataLocation));

    std::string DataLocation = AppdataLocation + sep + "data.json";
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
    std::string RecursiveLocation = AppdataLocation + sep + "rec.json";
    engine.rootContext()->setContextProperty("RecursiveLocation", QString::fromStdString(RecursiveLocation));

    if (!check_exists(RecursiveLocation)) {
        std::ofstream file(RecursiveLocation);
        json rec = false;
        file << rec;
    }

    qDebug() << "data is at: " << DataLocation;
    qDebug() << "recursive at: " << RecursiveLocation;

    qmlRegisterType<FileIO, 1>("FileIO", 1, 0, "FileIO");
    // qDebug() << QLibraryInfo::path(QLibraryInfo::QmlImportsPath);
    engine.load(url);

    return app.exec();
}
