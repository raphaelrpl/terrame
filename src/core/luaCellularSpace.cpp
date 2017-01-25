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

/*! \file luaCellularSpace.cpp
\brief This file contains implementations for the luaCellularSpace objects.
\author Tiago Garcia de Senna Carneiro
\author Ant?nio Rodrigues
\author Rodrigo Reis Pereira
*/

#include "luaCellIndex.h"
#include "luaCellularSpace.h"
#include "luaNeighborhood.h"
#include "terrameGlobals.h"

// Observadores
#include "../observer/types/observerUDPSender.h"
#include "../observer/types/agentObserverMap.h"
#include "../observer/types/observerTextScreen.h"
#include "../observer/types/observerGraphic.h"
#include "../observer/types/observerLogFile.h"
#include "../observer/types/observerTable.h"
#include "../observer/types/observerUDPSender.h"

#include "luaUtils.h"

#include <fstream>
#include <algorithm>

#ifndef WIN32
#define stricmp strcasecmp
#define strnicmp strncasecmp
#endif

#ifndef luaL_checkbool
#if LUA_VERSION_NUM < 503
#define luaL_checkbool(L, i)(lua_isboolean(L, i) ? lua_toboolean(L, i) : luaL_checkint(L, i))
#else
#define luaL_checkbool(L, i)(lua_isboolean(L, i) ? lua_toboolean(L, i) : luaL_checkinteger(L, i))
#endif
#endif

///< Gobal variabel: Lua stack used for comunication with C++ modules.
extern lua_State * L;

///< true - TerrME runs in verbose mode and warning messages to the user;
// false - it runs in quite node and no messages are shown to the user.
extern ExecutionModes execModes;

using namespace TerraMEObserver;

/// constructor
luaCellularSpace::luaCellularSpace(lua_State *L)
{
    dbType = "mysql";
    host = "localhost";
    dbName = "";
    user = "";
    pass = "";
    inputLayerName = "";
    inputThemeName = "";
    // Antonio
    luaL = L;
    subjectType = TObsCellularSpace;
    observedAttribs.clear();
    port = -1;
}

int luaCellularSpace::setPort(lua_State *L){
    int p =   lua_tointeger(L, -1);
    port = p;
    return 0;
}

/// Sets the database type: MySQL, etc.
int luaCellularSpace::setDBType(lua_State *L)
{
    dbType =  string(lua_tostring(L, -1));
    return 0;
}

/// Sets the host name.
int luaCellularSpace::setHostName(lua_State *L)
{
    host =  string(lua_tostring(L, -1));
    return 0;
}

/// Sets the database name.
int luaCellularSpace::setDBName(lua_State *L)
{
    dbName =  string(lua_tostring(L, -1));
    return 0;
}

/// Get the database name.
int luaCellularSpace::getDBName(lua_State *L)
{
    lua_pushstring(L, this->dbName.c_str());
    return 1;
}

/// Sets the user name.
int luaCellularSpace::setUser(lua_State *L)
{
    user = string(lua_tostring(L, -1));
    return 0;
}

/// Sets the password name.
int luaCellularSpace::setPassword(lua_State *L)
{
    pass =  string(lua_tostring(L, -1));
    return 0;
}

/// Sets the geographical database layer name
int luaCellularSpace::setLayer(lua_State *L)
{
    inputLayerName = string(lua_tostring(L, -1));
    return 0;
}

/// Sets the geographical database theme name
int luaCellularSpace::setTheme(lua_State *L)
{
    inputThemeName = string(lua_tostring(L, -1));
    return 0;
}

/// Clears the cellular space attributes names
int luaCellularSpace::clearAttrName(lua_State *)
{
    attrNames.clear();
    return 0;
}

/// Adds a new attribute name to the CellularSpace attributes table used in the load function
int luaCellularSpace::addAttrName(lua_State *L)
{
    attrNames.push_back(lua_tostring(L, -1));
    return 0;
}

/// Sets the SQL WHERE CLAUSE to the string received as parameter
int luaCellularSpace::setWhereClause(lua_State *L)
{
    whereClause =  string(lua_tostring(L, -1));
    return 0;
}

/// Clear all luaCellularSpace object content(cells)
int luaCellularSpace::clear(lua_State *)
{
    CellularSpace::clear();
    return 0;
}

/// Adds a the luaCell received as parameter to the luaCellularSpace object
/// parameters: x, y, luaCell
int luaCellularSpace::addCell(lua_State *L)
{
    CellIndex indx;
    luaCell *cell = Luna<luaCell>::check(L, -1);
    indx.second = luaL_checknumber(L, -2);
    indx.first = luaL_checknumber(L, -3);
    CellularSpace::add(indx, cell);

    return 0;
}

/// Returns the number of cells of the CellularSpace object
/// no parameters
int luaCellularSpace::size(lua_State* L)
{
    lua_pushnumber(L, CellularSpace::size());
    return 1;
}

/// Sets the name of the TerraLib layer related to the CellularSpace object
/// parameter: layerName is a string containing the new layerName
/// \author Raian Vargas Maretto
void luaCellularSpace::setLayerName(string layerName)
{
    this->inputLayerName = layerName;
}

/// Gets the name of the TerraLib layer related to the CellularSpace object
/// no parameters
/// \author Raian Vargas Maretto
string luaCellularSpace::getLayerName()
{
    return this->inputLayerName;
}

/// Gets the name of the TerraLib layer related to the CellularSpace object
/// parameter: a pointer to the Lua Stack
/// \author Raian Vargas Maretto
int luaCellularSpace::getLayerName(lua_State *L)
{
    lua_pushstring(L, this->inputLayerName.c_str());
    return 1;
}

/// Creates several types of observers to the luaCellularSpace object
/// parameters: observer type, observeb attributes table, observer type parameters
int luaCellularSpace::createObserver(lua_State * luaL)
{
    // lua_rawgeti(luaL, LUA_REGISTRYINDEX, ref);
    Reference<luaCellularSpace>::getReference(luaL);

    getSpaceDimensions = false;

    // flags para a definicao do uso de compressao
    // na transmissao de datagramas e da visibilidade
    // dos observadores Udp Sender e Image
    bool compressDatagram = false, obsVisible = true;

    // recupero a tabela de atributos da celula
    int top = lua_gettop(luaL);

    // Nao modifica em nada a pilha recupera o enum referente ao tipo
    // do observer
    int typeObserver =(int)luaL_checkinteger(luaL, top - 5);

    //if (! lua_istable(luaL, top - 3))
    //{
    //    qFatal("\nError: The Attribute table not found. Incorrect sintax.\n");
    //    return -1;
    //}

    QStringList allCellSpaceAttribs, allCellAttribs, obsAttribs;
    QStringList obsParams, obsParamsAtribs; // parametros/atributos da legenda
    QStringList imagePath; //diretorio onde as imagens do ObsImage serao salvas

    const char *strAux;
    double numAux = -1;
    //int cellsNumber = 0;
    bool boolAux = false;

    lua_pushnil(luaL);
    while (lua_next(luaL, top) != 0)
    {
        if (lua_type(luaL, -2) == LUA_TSTRING)
        {
            QString key = luaL_checkstring(luaL, -2);
            allCellSpaceAttribs.append(key);

            if (key == "cells")
            {
                int cellstop = lua_gettop(luaL);
                int stop = false;

                lua_pushnil(luaL);
                while ((!stop) && (lua_next(luaL, cellstop) != 0))
                {
                    int cellTop = lua_gettop(luaL);
                    // lua_pushstring(luaL, "cObj_");
                    lua_pushnumber(luaL, 1);
                    lua_gettable(luaL, cellTop);

                    lua_pushnil(luaL);
                    while (lua_next(luaL, cellTop) != 0)
                    {
                        if (lua_type(luaL, -2) == LUA_TSTRING)
                            allCellAttribs.append(luaL_checkstring(luaL, -2));
                        stop = true;
                        lua_pop(luaL, 1);
                    }
                    lua_pop(luaL, 1); // lua_pushnumber/lua_pushstring
                    lua_pop(luaL, 1); // lua_pushnil
                    lua_pop(luaL, 1); // breaks the loop
                }
            } //(key == "cells")
        } // lua_type == LUA_TSTRING
        lua_pop(luaL, 1);
    }

    // Recupera a tabela de parametros
    lua_pushnil(luaL);
    while (lua_next(luaL, top - 2) != 0)
    {
        lua_pushstring(luaL, "Minimum");
        lua_gettable(luaL, -1);

        //********************************************************************************
        int firstLegPos = lua_gettop(luaL);
        int iAux = 1;

        // percorre cada item da tabela parametros
        lua_pushnil(luaL);

        if (!lua_istable(luaL, firstLegPos - 1))
        {
            // ---- Observer Image: Recupera o path/nome dos arquivos de imagem
            if (typeObserver == TObsImage)
            {
                if (lua_type(luaL, firstLegPos - 1) == LUA_TSTRING)
                {
                    // recupera o path para o arquivo
                    QString k(luaL_checkstring(luaL, firstLegPos - 1));
                    imagePath.push_back(k);
                }
                else
                {
                    if (lua_type(luaL, firstLegPos - 1) == LUA_TBOOLEAN)
                        obsVisible = lua_toboolean(luaL, firstLegPos - 1);
                }
                iAux = 4;
            }
            else
            {
                // Recupera os valores da tabela parametros
                if (lua_type(luaL, firstLegPos - 1) == LUA_TSTRING)
                    obsParamsAtribs.append(luaL_checkstring(luaL, firstLegPos - 1));
            }
            lua_pop(luaL, 1); // lua_pushnil
        }
        else
        {
            while (lua_next(luaL, firstLegPos - iAux) != 0)
            {
                QString key;

                if (lua_type(luaL, -2) == LUA_TSTRING)
                {
                    key = luaL_checkstring(luaL, -2);
                }
                else
                {
                    if (lua_type(luaL, -2) == LUA_TNUMBER)
                    {
                        char aux[100];
                        double number = luaL_checknumber(luaL, -2);
                        sprintf(aux, "%g", number);
                        key = aux;
                    }
                }
                obsParams.push_back(key);

                switch (lua_type(luaL, -1))
                {
                case LUA_TBOOLEAN:
                    boolAux = lua_toboolean(luaL, -1);
                    //obsParamsAtribs.push_back(boolAux ? "true" : "false");
                    // Recupera o valor do paramentro
                    if (key == "compress")
                        compressDatagram = boolAux;

                    // Recupera o valor do paramentro
                    if (key == "visible")
                        obsVisible = boolAux;
                    break;

                case LUA_TNUMBER:
                    numAux = luaL_checknumber(luaL, -1);
                    obsParamsAtribs.push_back(QString::number(numAux));
                    break;

                case LUA_TSTRING:
                    strAux = luaL_checkstring(luaL, -1);
                    obsParamsAtribs.push_back(strAux);
                    break;

                case LUA_TNIL:
                case LUA_TTABLE:
                default:
                    break;
                }
                lua_pop(luaL, 1); // lua_pushnil
            }
        }
        //********************************************************************************
        lua_pop(luaL, 1); // lua_pushstring
        lua_pop(luaL, 1); // lua_pushnil
    }

    // Recupera a tabela de atributos
    lua_pushnil(luaL);
    while (lua_next(luaL, top - 3) != 0)
    {
        QString key(luaL_checkstring(luaL, -1));
        obsAttribs.push_back(key);
        lua_pop(luaL, 1);
    }

    //if ((typeObserver == TObsImage) ||(typeObserver == TObsMap) ||(typeObserver == TObsShapefile))
    //{
    //    // LEGEND_ITENS esta definido dentro do observer.h
    //    if (obsAttribs.size() * LEGEND_ITENS < obsParams.size())
    //    {
    //    }
    //}

    QList<int> obsDim;

    // Recupera a tabela de dimensoes
    lua_pushnil(luaL);
    while (lua_next(luaL, top - 4) != 0)
    {
        int v = luaL_checknumber(luaL, -1);

        obsDim.push_back(v);
        lua_pop(luaL, 1);
    }

    int width, height;
    if (!obsDim.isEmpty())
    {
        width = obsDim.at(0);
        height = obsDim.at(1);
        if ((width > 0) && (height > 0))
            getSpaceDimensions = true;
    }

    if ((typeObserver == TObsMap) ||(typeObserver == TObsImage) ||(typeObserver == TObsShapefile))
    {
        if (obsAttribs.isEmpty())
        {
            obsAttribs = allCellAttribs;
            observedAttribs = allCellAttribs;
        }
        else
        {
            // posicao da celula no espaco celular
            obsAttribs.push_back("x");
            obsAttribs.push_back("y");
            if (typeObserver == TObsShapefile) obsAttribs.push_back("objectId_");

            // Verifica se o atributo informado realmente existe na celula
            for (int i = 0; i < obsAttribs.size(); i++)
            {
                // insere na lista de atributos do cellspace o atributo recuperado
                if (!observedAttribs.contains(obsAttribs.at(i)))
                    observedAttribs.push_back(obsAttribs.at(i));

                if (!allCellAttribs.contains(obsAttribs.at(i)))
                {
                    string err_out = string("Error: Attribute name '") + string(qPrintable(obsAttribs.at(i))) + string("' not found.");
					lua_getglobal(L, "customError");
					lua_pushstring(L, err_out.c_str());
					lua_pushnumber(L, 5);
					lua_call(L, 2, 0);
                    return 0;
                }
            }
        }
    }
    else
    {
        if (obsAttribs.isEmpty())
        {
            obsAttribs = allCellSpaceAttribs;
            observedAttribs = allCellSpaceAttribs;
        }
        else
        {
            for (int i = 0; i < obsAttribs.size(); i++)
            {
                // insere na lista de atributos do cellspace o atributo recuperado
                if (!observedAttribs.contains(obsAttribs.at(i)))
                    observedAttribs.push_back(obsAttribs.at(i));

                if (!allCellSpaceAttribs.contains(obsAttribs.at(i)))
                {
                    string err_out = string("Error: Attribute name '") + string(qPrintable(obsAttribs.at(i))) + string("' not found or not belongs to this subject.");
                    lua_getglobal(L, "customError");
                    lua_pushstring(L, err_out.c_str());
                    lua_pushnumber(L, 5);
                    lua_call(L, 2, 0);

                    return 0;
                }
            }
        }
    }

    AgentObserverMap *obsMap = 0;
    ObserverUDPSender *obsUDPSender = 0;
    ObserverTextScreen *obsText = 0;
    ObserverTable *obsTable = 0;
    ObserverGraphic *obsGraphic = 0;
    ObserverLogFile *obsLog = 0;

    int obsId = -1;

    switch (typeObserver)
    {
    case TObsTextScreen:
        obsText =(ObserverTextScreen*)
                CellSpaceSubjectInterf::createObserver(TObsTextScreen);
        if (obsText)
        {
            obsId = obsText->getId();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;

    case TObsLogFile:
        obsLog =(ObserverLogFile*)
                CellSpaceSubjectInterf::createObserver(TObsLogFile);
        if (obsLog)
        {
            obsId = obsLog->getId();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;

    case TObsTable:
        obsTable =(ObserverTable *)
                CellSpaceSubjectInterf::createObserver(TObsTable);
        if (obsTable)
        {
            obsId = obsTable->getId();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;

    case TObsDynamicGraphic:
        obsGraphic =(ObserverGraphic *)
                CellSpaceSubjectInterf::createObserver(TObsDynamicGraphic);

        if (obsGraphic)
        {
            obsGraphic->setObserverType(TObsDynamicGraphic);
            obsId = obsGraphic->getId();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;

    case TObsGraphic:
        obsGraphic =(ObserverGraphic *)
                CellSpaceSubjectInterf::createObserver(TObsGraphic);
        if (obsGraphic)
        {
            obsId = obsGraphic->getId();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;

    case TObsMap:
        obsMap =(AgentObserverMap *) CellSpaceSubjectInterf::createObserver(TObsMap);
        if (obsMap)
        {
            obsId = obsMap->getId();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;
    case TObsUDPSender:
        obsUDPSender =(ObserverUDPSender *) CellSpaceSubjectInterf::createObserver(TObsUDPSender);
        if (obsUDPSender)
        {
            obsId = obsUDPSender->getId();
            obsUDPSender->setCompressDatagram(compressDatagram);

            if (obsVisible)
                obsUDPSender->show();
        }
        else
        {
            if (execModes != Quiet)
                qWarning("%s", qPrintable(TerraMEObserver::MEMORY_ALLOC_FAILED));
        }
        break;
    default:
        if (execModes != Quiet)
        {
            qWarning("Warning: In this context, the code '%s' does not "
                     "correspond to a valid type of Observer.",  getObserverName(typeObserver));
        }
        return 0;
    }

    if (obsLog)
    {
        obsLog->setAttributes(obsAttribs);
        obsLog->setFileName(obsParamsAtribs.at(0));
        obsLog->setSeparator(obsParamsAtribs.at(1));
        obsLog->setWriteMode(obsParamsAtribs.at(2));

        lua_pushnumber(luaL, obsId);
        lua_pushlightuserdata(luaL, (void*) obsLog);

        return 2;
    }

    if (obsText)
    {
        obsText->setAttributes(obsAttribs);
        lua_pushnumber(luaL, obsId);
        lua_pushlightuserdata(luaL, (void*) obsText);

        return 2;
    }

    if (obsTable)
    {
        obsTable->setColumnHeaders(obsParamsAtribs);
        obsTable->setAttributes(obsAttribs);

        lua_pushnumber(luaL, obsId);
        lua_pushlightuserdata(luaL, (void*) obsTable);

        return 2;
    }

    if (obsGraphic)
    {
        obsGraphic->setLegendPosition();

        // Takes titles of three first locations
        obsGraphic->setTitles(obsParamsAtribs.at(0), obsParamsAtribs.at(1), obsParamsAtribs.at(2));
        obsParamsAtribs.removeFirst(); // remove graphic title
        obsParamsAtribs.removeFirst(); // remove axis x title
        obsParamsAtribs.removeFirst(); // remove axis y title

        // Splits the attribute labels in the cols list
        obsGraphic->setAttributes(obsAttribs, obsParamsAtribs.takeFirst()
                                  .split(";", QString::SkipEmptyParts), obsParams, obsParamsAtribs);

        lua_pushnumber(luaL, obsId);
		lua_pushlightuserdata(luaL, (void*) obsGraphic);

		return 2;
    }

    if (obsMap)
    {
        if (getSpaceDimensions)
            obsMap->setCellSpaceSize(width, height);

       ((ObserverMap *)obsMap)->setAttributes(obsAttribs, obsParams, obsParamsAtribs);
        observersHash.insert(obsMap->getId(), obsMap);
        lua_pushnumber(luaL,  obsMap->getId());

		lua_pushlightuserdata(luaL, (void*) obsMap);

		return 2;
    }

    if (obsUDPSender)
    {
        obsUDPSender->setAttributes(obsAttribs);

        obsUDPSender->setPort(obsParamsAtribs.at(0).toInt());

        // broadcast
        if ((obsParamsAtribs.size() == 1)
                ||((obsParamsAtribs.size() == 2) && obsParamsAtribs.at(1).isEmpty()))
        {
            obsUDPSender->addHost(BROADCAST_HOST);
        }
        else
        {
            // multicast or unicast
            for (int i = 1; i < obsParamsAtribs.size(); i++)
            {
                if (!obsParamsAtribs.at(i).isEmpty())
                    obsUDPSender->addHost(obsParamsAtribs.at(i));
            }
        }

        lua_pushnumber(luaL, obsId);
        lua_pushlightuserdata(luaL, (void*) obsUDPSender);

        return 2;
    }

    return 0;
}

const TypesOfSubjects luaCellularSpace::getType()
{
    return subjectType;
}

/// Notifies the Observer objects about changes in the luaCellularSpace internal state
int luaCellularSpace::notify(lua_State *)
{
    double time = luaL_checknumber(L, -1);
    CellSpaceSubjectInterf::notify(time);
    return 0;
}

/// Returns the Agent Map Observers linked to this cellular space
Observer * luaCellularSpace::getObserver(int id)
{
    if (observersHash.contains(id))
        return observersHash.value(id);
    else
        return NULL;
}

QString luaCellularSpace::getAll(QDataStream& /*in*/, int /*observerId*/ , QStringList &attribs)
{
    Reference<luaCellularSpace>::getReference(luaL);
    return pop(luaL, attribs);
}

QString luaCellularSpace::getChanges(QDataStream& in, int observerId , QStringList &attribs)
{
    return getAll(in, observerId, attribs);
}

//------------
/// Serializes the luaCellularSpace object to the Observer objects
#ifdef TME_BLACK_BOARD
QDataStream& luaCellularSpace::getState(QDataStream& in, Subject *, int observerId, QStringList & /* attribs */)
#else
QDataStream& luaCellularSpace::getState(QDataStream& in, Subject *, int observerId, QStringList &  attribs)
#endif
{
    int obsCurrentState = 0; //serverSession->getState(observerId);
    QString content;

    switch (obsCurrentState)
    {
    case 0:
#ifdef TME_BLACK_BOARD
        content = getAll(in, observerId, observedAttribs);
#else
        content = getAll(in, observerId, attribs);
#endif

        // serverSession->setState(observerId, 1);
        //if (execModes == Quiet)
        // 	qWarning(QString("Observer %1 passou ao estado %2").arg(observerId).arg(1).toLatin1().constData());
        break;

    case 1:
#ifdef TME_BLACK_BOARD
        content = getChanges(in, observerId, observedAttribs);
#else
        content = getChanges(in, observerId, attribs);
#endif

        // serverSession->setState(observerId, 0);
        //if (execModes != Quiet)
        // 	qWarning(QString("Observer %1 passou ao estado %2").arg(observerId).arg(0).toLatin1().constData());
        break;
    }
    // cleans the stack
    // lua_settop(L, 0);

    in << content;
    return in;
}

QString luaCellularSpace::pop(lua_State *luaL, QStringList& attribs)
{
    QString msg;

    // id
    msg.append(QString::number(getId()));
    msg.append(PROTOCOL_SEPARATOR);

    // subjectType
    msg.append(QString::number(subjectType));
    msg.append(PROTOCOL_SEPARATOR);

    // recupero a referencia na pilha lua
    Reference<luaCellularSpace>::getReference(luaL);

    int cellSpacePos = lua_gettop(luaL);

    int attrCounter = 0;
    int elementCounter = 0;
    // bool contains = false;
    double num = 0;
    QString text, key, attrs, elements;

    lua_pushnil(luaL);
    while (lua_next(luaL, cellSpacePos) != 0)
    {
        key = QString(luaL_checkstring(luaL, -2));

        if ((attribs.contains(key)) ||(key == "cells"))
        {
            attrCounter++;
            attrs.append(key);
            attrs.append(PROTOCOL_SEPARATOR);

            switch (lua_type(luaL, -1))
            {
            case LUA_TBOOLEAN:
                attrs.append(QString::number(TObsBool));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append(QString::number(lua_toboolean(luaL, -1)));
                attrs.append(PROTOCOL_SEPARATOR);
                break;

            case LUA_TNUMBER:
                num = luaL_checknumber(luaL, -1);
                doubleToQString(num, text, 20);
                attrs.append(QString::number(TObsNumber));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append(text);
                attrs.append(PROTOCOL_SEPARATOR);
                break;

            case LUA_TSTRING:
                text = QString(luaL_checkstring(luaL, -1));
                attrs.append(QString::number(TObsText));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append((text.isEmpty() || text.isNull() ? VALUE_NOT_INFORMED : text));
                attrs.append(PROTOCOL_SEPARATOR);
                break;

            case LUA_TTABLE:
            {
                char result[100];
                sprintf(result, "%p", lua_topointer(luaL, -1));
                attrs.append(QString::number(TObsText));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append(QString("Lua-Address(TB): ") + QString(result));
                attrs.append(PROTOCOL_SEPARATOR);

                // Recupera a tabela de cells e delega a cada
                // celula sua serializacao
                // if (key == "cells")
                //{
                int top = lua_gettop(luaL);

                lua_pushnil(luaL);
                while (lua_next(luaL, top) != 0)
                {
                    int cellTop = lua_gettop(luaL);
                    lua_pushstring(luaL, "cObj_");
                    lua_gettable(luaL, cellTop);

                    luaCell*  cell;
                    cell =(luaCell*)Luna<luaCell>::check(L, -1);
                    lua_pop(luaL, 1);

                    // luaCell->pop(...) requer uma celula no topo da pilha
                    QString cellMsg = cell->pop(L, attribs);
                    elements.append(cellMsg);
                    elementCounter++;

                    lua_pop(luaL, 1);
                }
                break;
                //}
                //break;
            }

            case LUA_TUSERDATA	:
            {
                char result[100];
                sprintf(result, "%p", lua_topointer(luaL, -1));
                attrs.append(QString::number(TObsText));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append(QString("Lua-Address(UD): ") + QString(result));
                attrs.append(PROTOCOL_SEPARATOR);
                break;
            }

            case LUA_TFUNCTION:
            {
                char result[100];
                sprintf(result, "%p", lua_topointer(luaL, -1));
                attrs.append(QString::number(TObsText));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append(QString("Lua-Address(FT): ") + QString(result));
                attrs.append(PROTOCOL_SEPARATOR);
                break;
            }

            default:
            {
                char result[100];
                sprintf(result, "%p", lua_topointer(luaL, -1));
                attrs.append(QString::number(TObsText));
                attrs.append(PROTOCOL_SEPARATOR);
                attrs.append(QString("Lua-Address(O): ") + QString(result));
                attrs.append(PROTOCOL_SEPARATOR);
                break;
            }
            }
        }
        lua_pop(luaL, 1);
    }

    // #attrs
    msg.append(QString::number(attrCounter));
    msg.append(PROTOCOL_SEPARATOR);

    // #elements
    msg.append(QString::number(elementCounter));
    msg.append(PROTOCOL_SEPARATOR);
    msg.append(attrs);

    msg.append(PROTOCOL_SEPARATOR);
    msg.append(elements);
    msg.append(PROTOCOL_SEPARATOR);

    return msg;
}

int luaCellularSpace::kill(lua_State *luaL)
{
    int id = luaL_checknumber(luaL, 1);

    bool result = CellSpaceSubjectInterf::kill(id);
    lua_pushboolean(luaL, result);
    return 1;
}

/// Find a cell given a cell ID
/// \author Raian Vargas Maretto
luaCell * luaCellularSpace::findCellByID(const char* cellID)
{
    luaCell *cell;
    CellularSpace::iterator it = this->begin();
    const char *idAux;
    while (it != this->end())
    {
        cell =(luaCell*)it->second;
        idAux = cell->getID();
        if (strcmp(idAux, cellID) == 0)
        {
            return cell;
        }
        it++;
    }
    return NULL;
    //return(luaCell*)0;
}

//@RAIAN: Fim.
/// Find a cell given a luaCellularSpace object and a luaCellIndex object
luaCell * findCell(luaCellularSpace* cs, CellIndex& cellIndex)
{
    Region_<CellIndex>::iterator it = cs->find(cellIndex);
    if (it != cs->end()) return(luaCell*)it->second;
    return(luaCell*)0;
}
