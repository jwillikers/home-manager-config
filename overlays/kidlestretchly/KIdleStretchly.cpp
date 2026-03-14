#include "KIdleStretchly.h"
#include <QDebug>
#include <QString>
#include <QStringList>
#include <QProcess>

#include "kidletime.h"

// 20 minutes
static constexpr int idle_timeout{1200000};

KIdleStretchly::KIdleStretchly(const QString stretchly_executable) : m_stretchly_executable(stretchly_executable)
{
    // connect to idle events
    connect(KIdleTime::instance(), &KIdleTime::resumingFromIdle, this, &KIdleStretchly::resumeEvent);
    connect(KIdleTime::instance(),
            qOverload<int, int>(&KIdleTime::timeoutReached), this, &KIdleStretchly::timeoutReached);

    printf("Registering idle timeout.\n");
    KIdleTime::instance()->addIdleTimeout(idle_timeout);
}

KIdleStretchly::~KIdleStretchly()
{
}

void KIdleStretchly::resumeEvent()
{
    KIdleTime::instance()->removeAllIdleTimeouts();

    // Resume and reset Stretchly breaks.
    printf("Interaction detected. Resuming Stretchly.\n");
    QProcess process = QProcess(this);
    process.start(m_stretchly_executable, QStringList("reset"));
    process.waitForFinished();
    printf("Breaks resumed.\n");

    printf("Registering idle timeout.\n");
    KIdleTime::instance()->addIdleTimeout(idle_timeout);
}

void KIdleStretchly::timeoutReached(int id, int timeout)
{
    Q_UNUSED(id)

    // Reset / pause breaks after being idle for 20 minutes.
    if (timeout == idle_timeout) {
        printf("Idled for 20 minutes. Pausing Stretchly.\n");
        QProcess process = QProcess(this);
        // Pause Stretchly breaks.
        process.start(m_stretchly_executable, QStringList("pause"));
        process.waitForFinished();
        // Wait for user activity to resume.
        KIdleTime::instance()->catchNextResumeEvent();
    } else {
        qDebug() << "Spurious timeoutReached call";
    }
}

#include "moc_KIdleStretchly.cpp"
