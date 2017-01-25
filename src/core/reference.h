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

#ifndef REFFERENCE_H
#define REFFERENCE_H

#include <lua.hpp>

/// Class responsible for creating and manipulating references on the Lua Registry table
// @DANIEL
// Based on Curiously recurring template pattern - class Derived : public Reference<Derived>
template <class T>
class Reference
{
    // Index for the table holding the objects on the Lua Registry
    static int m_ref;

    // Create a weak table on the Lua Registry to hold all instances of a given derived class
    void createWeakTable(lua_State *L)
    {
        // weaktable = {}
        lua_newtable(L);

        // mt = {__mode = "kv"}
        lua_newtable(L);
        lua_pushstring(L, "__mode");
        lua_pushstring(L, "kv");
        lua_rawset(L, -3);

        // setmetatable(weaktable, mt)
        lua_setmetatable(L, -2);

        m_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }
public:
    /// Sets the reference for the Lua object using the cObj pointer.
    int setReference(lua_State *L)
    {
        if (m_ref == LUA_REFNIL)
            createWeakTable(L);
        // retrieves the container
        lua_rawgeti(L, LUA_REGISTRYINDEX, m_ref);

        // container[cObj] = lua_object
        lua_pushvalue(L, -2);
        lua_rawsetp(L, -2, this);
        lua_pop(L, 2);

        return 0;
    }

    /// Gets the lua object.
    int getReference(lua_State *L)
    {
        // retrieves the container
        lua_rawgeti(L, LUA_REGISTRYINDEX, m_ref);

        // container[cObj]
        lua_rawgetp(L, -1, this);
        lua_remove(L, -2);

        return 1;
    }
};

template <typename T> int Reference<T>::m_ref = LUA_REFNIL;

#endif // REFFERENCE_H

