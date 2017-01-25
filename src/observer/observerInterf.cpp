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

#include "observerInterf.h"
#include "observerImpl.h"

//////////////////////////////////////////////////////////// Observer
ObserverInterf::ObserverInterf()
{
}

ObserverInterf::ObserverInterf(Subject* subj)
{
    ObserverInterf::pImpl_->setSubject(subj);
    ObserverInterf::pImpl_->setObsHandle(this);
}

ObserverInterf::~ObserverInterf()
{
}

void ObserverInterf::setVisible(bool b)
{
    ObserverInterf::pImpl_->setVisible(b);
}

bool ObserverInterf::getVisible()
{
    return ObserverInterf::pImpl_->getVisible();
}

bool ObserverInterf::update(double time)
{
    return Interface<ObserverImpl>::pImpl_->update(time);
}

int ObserverInterf::getId()
{
    return Interface<ObserverImpl>::pImpl_->getId();
}

const TypesOfObservers ObserverInterf::getType()
{
    return Interface<ObserverImpl>::pImpl_->getObserverType();
}

QStringList ObserverInterf::getAttributes()
{
    return Interface<ObserverImpl>::pImpl_->getAttributes();
}

void ObserverInterf::setModelTime(double time)
{
    Interface<ObserverImpl>::pImpl_->setModelTime(time);
}

void ObserverInterf::setDirtyBit()
{
    Interface<ObserverImpl>::pImpl_->setDirtyBit();
}



////////////////////////////////////////////////////////////  Subject

void SubjectInterf::attach(Observer* obs)
{
    SubjectInterf::pImpl_->attachObserver(obs);
}

void SubjectInterf::detach(Observer* obs)
{
    SubjectInterf::pImpl_->detachObserver(obs);
}

Observer * SubjectInterf::getObserverById(int id)
{
    return SubjectInterf::pImpl_->getObserverById(id);
}

void SubjectInterf::notify(double time)
{
    SubjectInterf::pImpl_->notifyObservers(time);
}

int SubjectInterf::getId() const
{
    return SubjectInterf::pImpl_->getId();
}
