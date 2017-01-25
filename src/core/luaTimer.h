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

/*! \file luaTimer.h
\brief This file definitions for the luaTimer objects.
\author Tiago Garcia de Senna Carneiro
*/
#ifndef LUATIMER_H
#define LUATIMER_H

#include "../observer/schedulerSubjectInterf.h"
#include "luaUtils.h"
#include "reference.h"
#include "observerScheduler.h"

/**
* \brief  
*  Implementation for a luaTimer object.
*
*/
class luaTimer: public SchedulerSubjectInterf, public Reference<luaTimer>
{
private:
    lua_State *luaL;

    TypesOfSubjects subjectType;
    QStringList observedAttribs;

    QString getAll(QDataStream& in, int obsId, QStringList& attribs);
    QString getChanges(QDataStream& in, int obsId, QStringList& attribs);

    ObserverScheduler *obs;

public:
    ///< Data structure issued by Luna<T>
    static const char className[];

    ///< Data structure issued by Luna<T>
    static Luna<luaTimer>::RegType methods[];

public:
    /// Constructor
    luaTimer(lua_State *L);

    /// Desctructor
    ~luaTimer(void);

    /// Executes the luaTimer object
    /// parameter: finalTime
    int execute(lua_State *L);

    /// Gets the luaTimer internal clock value
    int getTime(lua_State *L);

    /// Return true if the luaTimer object is empty and has no luaEvents to execute
    int isEmpty(lua_State *L);

    /// Inserts a luaEvent - luaMessage pair in the luaTimer queue
    /// parameters: luaEvent, luaMessage
    int add(lua_State *L);

    /// Resets the luaTimer
    int reset(lua_State* L);

    /// Creates several types of observers to the luaCellularSpace object
    /// parameters: observer type, observeb attributes table, observer type parameters
    int createObserver(lua_State *L);

    /// Notifies the Observer objects about changes in the luaCellularSpace internal state
    int notify(lua_State *L);

    /// Gets the subject's type
    const TypesOfSubjects getType();

    /// Gets the object's internal state (serialization)
    /// \param in the serializated object that contains the data that will be observed in the observer
    /// \param subject a pointer to a observed subject
    /// \param observerId the id of the observer
    /// \param attribs the list of attributes observed
    QDataStream& getState(QDataStream& in, Subject *subject, int observerID, QStringList& attribs);

    /// Gets the attributes of Lua stack
    /// \param attribs the list of attributes observed
    QString pop(lua_State *L, QStringList& attribs);

    /// Destroys the observer object instance
    int kill(lua_State *L);

    int setObserver(lua_State* L);

    int save(lua_State* L);
};

#endif

