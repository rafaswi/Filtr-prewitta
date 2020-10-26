#include "JAproj.h"
#include <qfiledialog.h>
#include <qmessagebox.h>
#include <qprogressbar.h>
#include <qbuttongroup.h>
#include <vector>



JAproj::JAproj(QWidget *parent)
    : QMainWindow(parent)
{
    ui.setupUi(this);
    ui.lcdNumber->display(1); 
    ui.radioButton_cpp->setChecked(true);
    
}

void JAproj::on_quitButton_clicked()
{
    close();
}

QtCharts::QChartView* JAproj::createLineChart(int rDistribution[],int gDistribution[], int bDistribution[], std::string histogramFilePath, bool beforeOrAfterAlgorithm)
{
    

    QtCharts::QLineSeries* rseries = new QtCharts::QLineSeries();
    QtCharts::QLineSeries* gseries = new QtCharts::QLineSeries();
    QtCharts::QLineSeries* bseries = new QtCharts::QLineSeries();

    for (int i = 0; i < 256; i++)
    {
        *rseries << QPointF(i, rDistribution[i]);
        *gseries << QPointF(i, gDistribution[i]);
        *bseries << QPointF(i, bDistribution[i]);
    }
    rseries->setColor(QColorConstants::Red);
    gseries->setColor(QColorConstants::Green);
    bseries->setColor(QColorConstants::Blue);

    QtCharts::QChart* chart = new QtCharts::QChart();
    chart->legend()->hide();
    chart->addSeries(rseries);
    chart->addSeries(gseries);
    chart->addSeries(bseries);
    chart->createDefaultAxes();
    chart->setAnimationOptions(QtCharts::QChart::SeriesAnimations);

    if (beforeOrAfterAlgorithm)
    {
        chart->setTitle("Before algorithm histogram");
    }
    else
    {
        chart->setTitle("After algorithm histogram");
    }
   

    QtCharts::QChartView* chartView = new QtCharts::QChartView(chart);
    chartView->setRenderHint(QPainter::Antialiasing);
 
    return chartView;
 

}

void JAproj::displayHistograms(QtCharts::QChartView* beforeAlgorithmHistogram, QtCharts::QChartView* afterAlgorithmHistogram)
{
    QVBoxLayout* lay = new QVBoxLayout;
    lay->addWidget(beforeAlgorithmHistogram);
    lay->addWidget(afterAlgorithmHistogram);

    QWidget* w = new QWidget();
    w->setLayout(lay);
    w->resize(600, 500);
    w->show();
}

void JAproj::on_openButton_clicked()
{
    QString filePath = QFileDialog::getOpenFileName(this,tr("Image chooser")," " ,tr("BMP Files (*.bmp)"));   
    imageFilePath = filePath.toLocal8Bit().constData();
    QMessageBox::information(this, tr("file name"), "Selected file path: "+filePath);
}

void JAproj::on_startAlgorithmButton_clicked()
{

    if (ui.radioButton_cpp->isChecked() || ui.radioButton_asm->isChecked())
    {
        QtCharts::QChartView* beforeHistogram = nullptr;
        QtCharts::QChartView* afterHistogram = nullptr;
        try 
        {
            Bitmap b(imageFilePath);
            numberOfThreads = ui.lcdNumber->intValue();
           
           

            QMessageBox::StandardButton reply;
            reply = QMessageBox::question(this, "JAproj", "Is loaded bitmap in color?", QMessageBox::Yes | QMessageBox::No);
            if (reply == QMessageBox::Yes)
            {
                b.calculateHistogram();
                b.grayscale();
            }
            else
            {
                b.calculateHistogram();
            }
            if (ui.radioButton_cpp->isChecked())
            {
                b.castPixelCharArrayToUnsignedCharArray();
                beforeHistogram=createLineChart(b.rDistribution, b.gDistribution, b.bDistribution, imageFilePath, true);
                b.makeMagic();
                b.calculateHistogram();
                afterHistogram=createLineChart(b.rDistribution, b.gDistribution, b.bDistribution, imageFilePath, false);
               b.saveToFile(imageFilePath);
            }
            else if (ui.radioButton_asm->isChecked())
            {
            }
            displayHistograms(beforeHistogram, afterHistogram);
        }
        catch (...)
        {
            QMessageBox::information(this, tr("ERROR"), "Please select file to be opened.");
        }
        
    }
    else
    {
        QMessageBox::information(this, tr("ERROR"), "Please choose dll.");
    }
   
    
    
}
