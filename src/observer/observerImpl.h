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

/**
 * \file observerImpl.h
 * \brief Design Pattern Subject and Observer implementations
 * \author Antonio Jos? da Cunha Rodrigues
 * \author Tiago Garcia de Senna Carneiro
 */

#ifndef OBSERVER_IMPL
#define OBSERVER_IMPL

#include "../core/bridge.h"
#include "observer.h"

#include <stdarg.h>
#include <string.h>
#include <list>
#include <iterator>
//#include <iostream>
#include <QtCore/QDataStream>
#include <QtCore/QDateTime>

using namespace TerraMEObserver;

class SubjectImpl;


/**
 * \brief
 *  Implementation for a Observer object.
 *
 */
class ObserverImpl : public Implementation
{
public:
    /**
     * Constructor
     */
    ObserverImpl();

    /**
     * Destructor
     */
    virtual ~ObserverImpl();

    /**
     * \copydoc TerraMEObserver::Observer::update
     */
    bool update(double time);

    /**
     * \copydoc TerraMEObserver::Observer::getVisible
     */
    bool getVisible();

    /**
     * \copydoc TerraMEObserver::Observer::setVisible
     */
    void setVisible(bool visible);

    /**
     * Sets the Subject \a subj that it is attached
     * \param subj a pointer to a Subject
     * \see Subject
     */
    void setSubject(TerraMEObserver::Subject *subj);

    /**
     * Sets the Observer handle
     * \param obs a pointer to an Observer
     * \see Observer
     */
    void setObsHandle(Observer* obs);

    /**
     * \copydoc TerraMEObserver::Observer::getType
     */
    virtual const TypesOfObservers getObserverType();

    /**
     * \copydoc TerraMEObserver::Observer::setModelTime
     */
    virtual void setModelTime(double time);

    /**
     * \copydoc TerraMEObserver::Observer::getId
     */
    int getId();

    /**
     * \copydoc TerraMEObserver::Observer::getAttributes
     */
    virtual QStringList getAttributes();

    /**
     * \copydoc TerraMEObserver::Observer::setDirtyBit
     */
    void setDirtyBit();

private:
    /**
     * Copy constructor
     */
    ObserverImpl(const ObserverImpl &);

    /**
     * Assign operator
     */
    ObserverImpl & operator=(ObserverImpl &);

    bool visible;
    int observerID;
    TerraMEObserver::Subject* subject_;
    Observer* obsHandle_;
};



////////////////////////////////////////////////////////////  Subject


/**
 * \brief
 *  Observer List Type.
 *
 */
typedef std::list<Observer*> ObsList;

/**
 * \brief
 *  Observer List Iterator Type.
 *
 */
typedef ObsList::iterator ObsListIterator;

/**
 * \brief
 *  Implementation for a Subject object.
 *
 */
class SubjectImpl : public Implementation
{
public:
    /**
     * Constructor
     */
    SubjectImpl();

    /**
     * Destructor
     */
    virtual ~SubjectImpl();

    /**
     * \copydoc TerraMEObserver::Subject::attach
     */
    void attachObserver(Observer *obs);

    /**
     * \copydoc TerraMEObserver::Subject::detach
     */
    void detachObserver(Observer *obs);

    /**
     * \copydoc TerraMEObserver::Subject::getObserverById
     */
    Observer * getObserverById(int id);

    /**
     * \copydoc TerraMEObserver::Subject::notify
     */
    void notifyObservers(double time);

    /**
     * \copydoc TerraMEObserver::Subject::getType
     */
    virtual const TypesOfSubjects getSubjectType();

    /**
     * \copydoc TerraMEObserver::Subject::getId
     */
    int getId() const;

private:
    /**
     * Copy constructor
     */
    SubjectImpl(const SubjectImpl &);

    /**
     * Assign operator
     */
    SubjectImpl & operator=(SubjectImpl &);


    ObsList observers;
    int subjectID;
};

void restartObserverCounter();

#endif
