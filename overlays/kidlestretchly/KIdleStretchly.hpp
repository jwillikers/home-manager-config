#pragma once

#include <QString>
#include <QObject>


class KIdleStretchly : public QObject
{
    Q_OBJECT

public:
    KIdleStretchly(const QString stretchly_executable);
    ~KIdleStretchly() override;

public Q_SLOTS:
    void timeoutReached(int id, int timeout);
    void resumeEvent();

private:
  QString m_stretchly_executable;
};
