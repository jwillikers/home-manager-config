#include "KIdleStretchly.hpp"
#include <QGuiApplication>
#include <QCommandLineParser>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setApplicationName("kstretchlyidle");
    QCoreApplication::setApplicationVersion("0.0.1");

    QCommandLineParser parser;
    parser.addHelpOption();
    parser.addVersionOption();
    parser.addPositionalArgument("executable", "Path of the Stretchly executable.");
    parser.process(app)
    const QString stretchly = parser.positionalArguments().at(0);

    KIdleStretchly s(stretchly);

    return app.exec();
}
