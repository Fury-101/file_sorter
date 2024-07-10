#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>

class FileIO : public QObject
{
    Q_OBJECT

public:
    Q_PROPERTY(QString source
                   READ source
                       WRITE setSource
                           NOTIFY sourceChanged)
    explicit FileIO(QObject *parent = 0);

    Q_INVOKABLE QString read();
    Q_INVOKABLE bool write(const QString& data);
    Q_INVOKABLE bool move(const QString& oldpath, const QString& newpath);
    static Q_INVOKABLE bool isDir(const QString& path);
    Q_INVOKABLE QList<QString> dirList(const QString& path);
    static Q_INVOKABLE QString toNativeSeparators(const QString& path);
    static Q_INVOKABLE QString fromNativeSeparators(const QString& path);

    QString source() { return mSource; };

public slots:
    void setSource(const QString& source) { mSource = source; };

signals:
    void sourceChanged(const QString& source);
    void error(const QString& msg);

private:
    QString mSource;
};

#endif // FILEIO_H
