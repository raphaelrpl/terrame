/************************************************************************************
TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

This code is part of the TerraME framework.
This framework is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

You should have received a copy of the GNU Lesser General Public
License along with this library.

The authors reassure the license terms regarding the warranties.
They specifically disclaim any warranties, including, but not limited to,
the implied warranties of merchantability and fitness for a particular purpose.
The framework provided hereunder is on an "as is" basis, and the authors have no
obligation to provide maintenance, support, updates, enhancements, or modifications.
In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of the use
of this software and its documentation.
*************************************************************************************/

#ifndef CHART_PLOT_H
#define CHART_PLOT_H

#include <qwt_plot.h>

class QContextMenuEvent;
class QMouseEvent;
class QAction;
class QwtPlotPicker;

class PlotPropertiesGUI;

namespace TerraMEObserver {

class InternalCurve;

class ChartPlot : public QwtPlot
{
    Q_OBJECT
public:
    ChartPlot(QWidget *parent);
    virtual ~ChartPlot();

    void setInternalCurves(const QList<TerraMEObserver::InternalCurve *> &internalCurves);
    void exportChart(std::string, std::string);

    void setId(int id);
    const int getId() const;

protected:
    // issue #642
    //void contextMenuEvent(QContextMenuEvent *ev);
    //void mouseDoubleClickEvent(QMouseEvent *ev);

private:
    /**
     * Draws a picker to the mouse cursor in the plot window
     * \return boolean, \a true if the curve could be draw
     */
    void createPicker();

    void resizeEvent(QResizeEvent *event);
    void moveEvent(QMoveEvent *event);
    void closeEvent(QCloseEvent *event);

    QAction *exportAct, *propertiesAct;
    QList<TerraMEObserver::InternalCurve *> internalCurves;

    QwtPlotPicker *picker;

    int id;
};

} // namespace TerraMEObserver

#endif // CHART_PLOT_H

