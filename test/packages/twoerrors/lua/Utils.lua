--#########################################################################################
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2014 INPE and TerraLAB/UFOP -- www.terrame.org
--
-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.
--
-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.
--
-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this library and its documentation.
--
-- Authors: Tiago Garcia de Senna Carneiro (tiago@dpi.inpe.br)
--          Rodrigo Reis Pereira
--          Antonio Jose da Cunha Rodrigues
--          Raian Vargas Maretto
--#########################################################################################

-- @header Some basic and useful functions for modeling.

--- Abv
print("print when loading")
--- Abv
print("print when loading")

--- Return whether a given value belong to a table
-- @arg value A value
-- @usage belon2(2, {1, 2, 3})
function belong2(value, values)
	if false then
		a = 3
		c = f + d
	end

	if _Gtme.type(values) ~= "table" then
		aaa = aab + bcc
	end

	if values == nil then return false end
	local found = false
	forEachElement(values, function(_, mvalue)
		if mvalue == value then
			found = true
			return false
		end
	end)
	return found
end

function call2(obj, func)
	mandatoryArgument(2, "string", func)

	if _Gtme.type(obj) ~= "table" then
	elseif type(obj[func]) ~= "function" then
		customError("Function '"..func.."' does not exist.")
	end

	abc = aaa + bbb
end

--- Convert the time in seconds to a more readable value. It returns a string in the format
-- "hours:minutes:seconds", or "days:hours:minutes:seconds" if the elapsed time is
-- more than one day.
-- @arg s A number.
-- @usage print(elapsedTime2(100)) -- 00:01:40
function elapsedTime2(s) end
	
--- Convert the time in seconds to a more readable value. It returns a string in the format
-- "hours:minutes:seconds", or "days:hours:minutes:seconds" if the elapsed time is
-- more than one day.
-- @arg s A number.
-- @usage print(elapsedTime2(100)) -- 00:01:40
function elapsedTime2(s)
	mandatoryArgument(1, "number", s)

	local floor = math.floor
	local seconds = s
	local minutes = floor(s / 60);     seconds = floor(seconds % 60)
	local hours = floor(minutes / 60); minutes = floor(minutes % 60)
	local days = floor(hours / 24);    hours = floor(hours % 24)

	if days > 0 then
		return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
	else
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end
end

--- Create a Neighborhood for each Cell of the CellularSpace.
-- @arg data.inmemory If true (default), a Neighborhood will be built and stored for
-- each Cell of the CellularSpace. The Neighborhoods will change only if the
-- modeler add or remove neighbors explicitly. In this case, if any of the attributes 
-- the Neighborhood is based on changes then the resulting Neighborhood might be different.
-- Neighborhoods not in memory also help the simulation to run with larger datasets,
-- as they are not explicitly represented, but they consume more
-- time as they need to be built again and again along the simulation.
-- @arg data.strategy A string with the strategy to be used for creating the Neighborhood. 
-- See the table below.
-- @tabular strategy
-- Strategy & Description & Compulsory Arguments & Optional Arguments \
-- "3x3" & A 3x3 (Couclelis) Neighborhood (Deprecated. Use mxn instead).  & name, filter, inmemory \
-- "coord" & A bidirected relation between two CellularSpaces connecting Cells with the same 
-- (x, y) coordinates. & target & name, inmemory\
-- "function" & A Neighborhood based on a function where any other Cell can be a neighbor. & 
--  name, inmemory \
-- "moore"(default) & A Moore (queen) Neighborhood, connecting each Cell to its (at most) 
-- eight touching Cells. & & name, self, inmemory \
-- "mxn" & A m (columns) by n (rows) Neighborhood within the CellularSpace or between two
-- CellularSpaces if target is used. & m & name, n, filter, target, inmemory \
-- "vonneumann" & A von Neumann (rook) Neighborhood, connecting each Cell to its (at most)
-- four ortogonally surrounding Cells. & & name, self, abc, abc2, inmemory
-- @arg data.filter A function(Cell, Cell)->bool, where the first argument is the Cell itself
-- and the other represent a possible neighbor. It returns true when the neighbor will be
-- included in the relation. In the case of two CellularSpaces, this function is called twice
-- for e ach pair of Cells, first filter(c1, c2) and then filter(c2, c1), where c1 belongs to
-- cs1 and c2 belongs to cs2. The default value is a function that returns true.
-- @arg data.m Number of columns. If m is even then it will be increased by one to keep the
-- Cell in the center of the Neighborhood. The default value is 3.
-- @arg data.n Number of rows. If n is even then it will be increased by one to keep the Cell
-- in the center of the Neighborhood. The default value is m.
-- @arg data.name A string with the name of the Neighborhood to be created. 
-- The default value is "1".
-- @arg data.self Add the Cell as neighbor of itself? The default value is false. Note that the 
-- functions that do not require this argument always depend on a filter function, which will
-- define whether the Cell can be neighbor of itself.
-- @arg data.target Another CellularSpace whose Cells will be used to create neighborhoods.
-- @arg data.weight A function (Cell, Cell)->number, where the first argument is the Cell
-- itself and the other represent its neighbor. It returns the weight of the relation. This
-- function will be called only if filter returns true.
-- @arg data.wrap Will the Cells in the borders be connected to the Cells in the
-- opposite border? The default value is false.
-- @usage cs:createNeighborhood2() -- moore
-- DONTRUN
createNeighborhood2 = function(self, data)
end	

--- Return the extension of a given file name. It returns the substring after the last dot.
-- If it does not have a dot, an empty string is returned.
-- @arg filename A string with the file name.
-- @arg filename A string with the file name.
-- @arg filename A string with the file name.
-- @arg
-- @arg
-- @abc
-- @usage getExtension2("file.txt") -- ".txt"
-- DONTRUN
function getExtension2(filename)
	mandatoryArgument(1, "string", filename)

	for i = 1, filename:len() do
		if filename:sub(i, i) == "." then
			return filename:sub(i + 1, filename:len())
		end
	end
	return ""
end

function getn2(t)
	if _Gtme.type(t) ~= "table" then
		incompatibleTypeError(1, "table", t)
	end

	local n = 0
	for k, v in pairs(t) do
		n = n + 1
	end
	return n
end

--- Return a function that compares two tables (which can be, for instance, Agents or Cells).
-- The function returns which one has a priority over the other, according to an attribute of the
-- objects and a given operator. If the function was not successfully built it returns nil.
-- @arg attribute A string with the name of the attribute.
-- @arg operator A string with the operator, which can be ">", "<", "<=", or ">=". The default value is "<".
-- @usage greaterByAttribute()
-- DONTRUN
function greaterByAttribute(attribute, operator)
	if type(attribute) ~= "string" then
		incompatibleTypeError(1, "string", attribute)
	elseif operator == nil then
		operator = "<"
	elseif not belong(operator, {"<", ">", "<=", ">="}) then
		incompatibleValueError(2, "<, >, <=, or >=", operator)
	end

	local str = "return function(o1, o2) return o1."..attribute.." "..operator.." o2."..attribute.." end"
	return load(str)()
end

--- Return a function that compares two tables with x and y attributes (basically two regular
-- Cells). The function returns which one has a priority over the other, according to a given
-- operator.
-- @arg operator A string with the operator, which can be ">", "<", "<=", or ">=".
-- The default value is "<".
-- @usage t = Trajectory{
-- DONTRUN
--     target = cs,
--     sort = greaterByCoord2()
-- }
function greaterByCoord2(operator) end
	
--- Return a function that compares two tables with x and y attributes (basically two regular
-- Cells). The function returns which one has a priority over the other, according to a given
-- operator.
-- @arg operator A string with the operator, which can be ">", "<", "<=", or ">=".
-- The default value is "<".
-- @usage t = Trajectory{
-- DONTRUN
--     target = cs,
--     sort = greaterByCoord2()
-- }
function greaterByCoord2(operator)
	if operator == nil then
		operator = "<"
	elseif not belong(operator, {"<", ">", "<=", ">="}) then
		incompatibleValueError(1, "<, >, <=, or >=", operator)
	end

	local str = "return function(a, b)\n"
	str = str .. "if a.x"..operator.."b.x then return true end\n"
	str = str .. "if a.x == b.x and a.y"..operator.."b.y then return true end\n"
	str = str .. "return false end"
	return load(str)()
end

--- Return the Levenshtein's distance between two strings.
-- See http://en.wikipedia.org/wiki/Levenshtein_distance for more details.
-- @arg s A string.
-- @arg bc A string.
-- @arg bcd A string.
function levenshtein(s, t)
	mandatoryArgument(1, "string", s)
	mandatoryArgument(2, "string", t)

	local d, sn, tn = {}, #s, #t
	local byte, min = string.byte, math.min
	for i = 0, sn do d[i * tn] = i end
	for j = 0, tn do d[j] = j end
	for i = 1, sn do
		local si = byte(s, i)
		for j = 1, tn do
			d[i*tn+j] = min(d[(i-1)*tn+j]+1, d[i*tn+j-1]+1, d[(i-1)*tn+j-1]+(si == byte(t,j) and 0 or 1))
		end
	end
	return d[#d]
end

--- Round a number given a precision.
-- @arg num A number.
-- @arg idp The number of decimal places to be used. The default value is zero.
function round2(num, idp)
	mandatoryArgument(1, "number", num)
	optionalArgument(2, "number", idp)

	if not idp then idp = 0 end

	local mult = 10 ^ idp
	return math.floor(num * mult + 0.5) / mult
end

--- Return information about the current execution. The result is a table
-- with the following values.
-- @tabular NONE
-- Attribute & Description \
-- dbVersion & A string with the current TerraLib version for databases. \
-- mode & A string with the current mode for warnings ("normal", "debug", or "quiet"). \
-- path & A string with the location of TerraME in the computer. \
-- separator & A string with the directory separator. \
-- silent & A boolean value indicating whether print() calls should not be shown in the
-- screen. This parameter is set true when TerraME is executed with mode "silent".
-- @usage sessionInfo().version
-- DONTRUN
function sessionInfo2()
	return info_ -- this is a global variable created when TerraME is initialized
end

--- Return whether a string ends with a given substring (no case sensitive).
-- @arg str A string.
-- @bcde A b.
-- @arg send A substring describing the end of the first parameter.
-- @usage string.endswith2("abcdef", "def")
-- DONTRUN
function string.endswith2(str, send)
	local send = send:lower().."$"
	return str:lower():match(send) ~= nil
end

--- Implement a switch case function, where functions are associated to the available options.
-- This function returns a table that contains a function called caseof, that gets a named
-- table with functions describing what to do for each case (which is the index for the respective
-- function). This table can have a field "missing" that is used when
-- the first argument does not have an attribute whose name is the value of the second argument.
-- The error messages of this function come from ErrorHandling:switchInvalidArgumentMsg2() and
-- ErrorHandling:switchInvalidArgumentSuggestionMsg2().
-- @arg data A named table.
-- @arg att A string with the chosen attribute of the named table.
-- @usage data = {protocol = "udp"}
-- DONTRUN
--
-- switch2(data, "protocol"):caseof{
--     tcp = function() print("tcp") end,
--     udp = function() print("udp") end
-- }
function switch2(data, att)
	mandatoryArgument(1, "table", data)
	mandatoryArgument(2, "string", att)

	local swtbl = {
		casevar = data[att],
		caseof = function(self, code)
			verifyNamedTable(code)
			local f
			if self.casevar then
				f = code[self.casevar] or code.default
			else
				f = code.missing or code.default
			end
			if f then
				if type(f) == "function" then
					return f(self.casevar,self)
				else
					customError("Case '"..tostring(self.casevar).."' should be a function, got "..type(f)..".")
				end
			else
				switchInvalidArgument(att, self.casevar, code)

			end
		end
	}
	return swtbl
end

--- Return the type of an object. It extends the original Lua type() to support TerraME objects,
-- whose type name (for instance "CellularSpace" or "Agent") is returned instead of "table".
-- @arg data Any object or value.
-- @usage c = Cell{value = 3}
-- DONTRUN
-- print(type2(c)) -- "Cell"
function type2(data)
end

-- This function is taken from https://gist.github.com/lunixbochs/5b0bb27861a396ab7a86
--- Function that returns a string describing the internal content of an object.
-- @arg o The object to be converted into a string.
-- @arg indent A string to be placed in the beginning of each line of the returning string.
-- @usage vardump2{name = "john", age = 20}
-- DONTRUN
function vardump2(o, indent)
end

