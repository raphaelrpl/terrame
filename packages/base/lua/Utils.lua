-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

-- This code is part of the TerraME framework.
-- This framework is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 2.1 of the License, or (at your option) any later version.

-- You should have received a copy of the GNU Lesser General Public
-- License along with this library.

-- The authors reassure the license terms regarding the warranties.
-- They specifically disclaim any warranties, including, but not limited to,
-- the implied warranties of merchantability and fitness for a particular purpose.
-- The framework provided hereunder is on an "as is" basis, and the authors have no
-- obligation to provide maintenance, support, updates, enhancements, or modifications.
-- In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
-- indirect, special, incidental, or consequential damages arising out of the use
-- of this software and its documentation.
--
-------------------------------------------------------------------------------------------

-- @header Some basic and useful functions for modeling.

local observers

local deadObserverMetaTable_ = {__index = function(self, idx)
	if idx == "type_" then return "<DestroyedObserver>" end
	if idx == "update" then return function() end end
	if idx == "parent" then return self end

    customError("Trying to call a function of an observer that was destroyed.")
end}

--- Remove all graphical interfaces (Chart, Map, etc.).
-- This function is particularly useful when one wants to simulate
-- a Model repeated times.
-- @usage clean()
function clean()
	forEachElement(_Gtme.createdObservers, function(_, obs)
		if obs.target.cObj_ then
			if obs.type == 11 or obs.type == "neighborhood" then
				obs.target.cObj_:kill(obs.id, obs.observer.target.cObj_) -- SKIP
			else
				obs.target.cObj_:kill(obs.id)
			end
		elseif type(obs.target) == "Society" then
			obs.target:remove() -- SKIP
		else
			return
		end
		setmetatable(obs, deadObserverMetaTable_)
	end)
	_Gtme.createdObservers = {}
	cpp_restartobservercounter()
end

--- Return a copy of a given table. It does not copy metatables.
-- @arg mtable A table.
-- @usage animal = {
--     age = 5,
--     height = 10,
--     weight = 8
-- }
--
-- copy = clone(animal)
-- copy.age = 2
--
-- print(animal.age)
function clone(mtable)
	mandatoryArgument(1, "table", mtable)

	local result = {}

	forEachElement(mtable, function(idx, value, mtype)
		if mtype == "table" then
			result[idx] = clone(value)
		else
			result[idx] = value
		end
	end)

	return result
end

--- Return whether a given value belong to a table.
-- @arg value A value.
-- @arg values A table with a set of values.
-- @usage belong(2, {1, 2, 3})
function belong(value, values)
	if not isTable(values) then
		incompatibleTypeError(2, "table", values)
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

--- Return whether a given value is a Model or an instance of a Model.
-- @arg value A value.
-- @usage print(isModel(2)) -- false
function isModel(value)
	local mtype = type(value)

	return mtype == "Model" or (isTable(value) and type(value.parent) == "Model")
end

--- Return a function that executes a given function of an object.
-- It is particularly useful as argument action for an Event.
-- @arg obj Any TerraME object.
-- @arg func A string with the function to be executed.
-- @usage a = Agent{exec = function(self, ev) print(ev:getTime()) end}
--
-- t = Timer{
--     Event{action = call(a, "exec")}
-- }
--
-- t:run(10)
function call(obj, func)
	mandatoryArgument(2, "string", func)

	if not isTable(obj) then
		customError("Cannot access elements from an object of type '"..type(obj).."'.")
	elseif type(obj[func]) ~= "function" then
		customError("Function '"..func.."' does not exist.")
	end

	return function(ev) obj[func](obj, ev) end
end

--- Constructor for an ordinary differential equation. It works in the same way of Utils:integrate(),
-- but it is more efficient as it does not get a table as argument. The default integration method
-- is Euler but the modeler can declare a global variable INTEGRATION_METHOD to change the
-- default method.
-- @arg data.1 A differential equation or a vector of differential equations. Each
-- equation is described as a function of one or two arguments that returns a value of its
-- derivative f(t, y), where t is the time instant, and y starts with the value of attribute
-- initial and changes according to the result of f() and the chosen method. The calls to f
-- will use the first argument (t) in the interval [a,b[, according to the argument step.
-- @arg data.2 The initial condition, or a vector of initial conditions, which must be
-- satisfied. Each initial condition represents the value of y when t (first argument of f)
-- is equal to the value of argument a.
-- @arg data.3 A number with the beginning of the interval.
-- @arg data.4 A number with the end of the interval.
-- @arg data.5 A positive number with the step within the interval. The default value is
-- 0.2, but the user can change it by declaring a global variable DELTA.
-- @usage df = function(x, y) return y - x ^ 2 + 1 end
-- a = 0
-- b = 2
-- init = 0.5
-- delta = 0.2
--
-- result = d{df, init, a, b, delta}
-- print(result)
function d(data)
	local delta = DELTA
	if delta == nil then
		delta = 0.2
	end

	if data == nil then data = {} end

	local sizedata = getn(data)
	if sizedata < 4 then
		local str = "Error: bad arguments in diferential equation constructor \"d{arguments}\". "..
		"TerraME has found ".. #data.." arguments.\n"..
		" - the first attribute of a differential equantion must be a function which return a number. "..
		"It can also be a table of functions like that,\n"..
		" - the second one must be the initial condition value. "..
		"It can also be a table of initial conditions,\n"..
		" - the third one must be the lower integration limit value,\n"..
		" - the fourth one must be the upper integration limit value, and\n"..
		" - the fifth, OPTIONAL, must be the integration increment value (default = 0.2).\n"
		customError(str)
	end
	if sizedata == 5 then
		delta = data[5]
	end

	if type(data[1]) == "table" then
		if #data[1] ~= #data[2] then
			customError("You should provide the same number of differential equations and initial conditions.")
		end
	end

	local method = INTEGRATION_METHOD
	if method == nil then
		method = integrationEuler
	end

	local y = method(data[1], data[2], data[3], data[4], delta)

	if type(data[1]) == "table" then
		local str = "return "..y[1]
		for i = 2, #y do
			str = str ..", "..y[i]
		end
		return load(str)()
	else
		return y
	end
end

--- Pause the simulation for a given time.
-- @arg delay_s A number indicating how long in seconds should the model pause.
-- The default value is 1.
-- @usage delay(0.1)
function delay(delay_s)
	optionalArgument(1, "number", delay_s)

	if not delay_s then
		delay_s = 1
	end

	local time_to = os.time() + delay_s
	while os.time() <= time_to do end
end

--- Disable all graphics. If one create a Chart, Map, or any other object that
-- has a graphical interface, it will not be shown. Because of that, it will
-- not be possible to save the output from these objects.
-- @see Utils:enableGraphics
-- @usage -- DONTRUN
-- disableGraphics()
function disableGraphics()
	observers = {
		Chart = Chart,
		Map = Map,
		Clock = Clock,
		TextScreen = TextScreen,
		VisualTable = VisualTable
	}

	local setConstructor = function(mtype)
		local indexFunction = function(_, func)
			if func == "type_" then return mtype end
			if func == "parent" then return nil end
			if func == "update" then return function() end end

			customError("It is not possible to call '"..func.."' with graphics disabled.")
		end

		local constructor = function(attrTab)
			setmetatable(attrTab, {__index = indexFunction})
			return attrTab
		end

		rawset(_G, mtype, constructor)
	end

	forEachElement(observers, function(idx)
		setConstructor(idx)
	end)
end

--- Enable all graphics. This function is useful to restore
-- TerraME status after calling Utils:disableGraphics().
-- @usage -- DONTRUN
-- enableGraphics()
function enableGraphics()
	if observers == nil then return end

	rawset(_G, "Chart", observers.Chart)
	rawset(_G, "Map", observers.Map)
	rawset(_G, "Clock", observers.Clock)
	rawset(_G, "TextScreen", observers.TextScreen)
	rawset(_G, "VisualTable", observers.VisualTable)
end

--- Convert the time in seconds to a more readable value. It returns a string in the format
-- "hours:minutes:seconds", or "days:hours:minutes:seconds" if the elapsed time is
-- more than one day.
-- @arg s A number.
-- @usage print(elapsedTime(100)) -- 00:01:40
function elapsedTime(s)
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

--- Second order function to traverse a Society, Group, or Cell, applying a function to each of
-- its Agents. It returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- @arg obj A Society, Group, or Cell. Cells need to have a placement in order to execute
-- this function.
-- @arg _sof_ A function that takes one single Agent as argument. If some call to it returns
-- false, forEachAgent() stops and does not process any other Agent.
-- This function can optionally get a second argument with a positive number representing the
-- position of the Agent in the vector of Agents.
-- @usage ag = Agent{age = Random{min = 0, max = 2}}
-- soc = Society{
--     instance = ag,
--     quantity = 5
-- }
--
-- forEachAgent(soc, function(agent)
--     agent.age = agent.age + 1
-- end)
-- @see Environment:createPlacement
function forEachAgent(obj, _sof_)
	local t = type(obj)
	if t ~= "Society" and t ~= "Cell" and t ~= "Group" then
		incompatibleTypeError(1, "Society, Group, or Cell", obj)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	local ags = obj.agents
	if ags == nil then
		customError("Could not get agents from the "..type(obj)..".")
	end
	-- forEachAgent needs to be different from the other forEachs because the
	-- ageng can die along its own execution and it shifts back all the other
	-- agents in society.agents. If ipairs was used instead, forEach would
	-- skip the next agent of the vector after the removed agent.
	local k = 1
	for i = 1, #ags do
		local ag = ags[k]
		if ag and _sof_(ag, i) == false then return false end
		if ag == ags[k] then k = k + 1 end
	end
	return true
end

--- Second order function to traverse a given CellularSpace, Trajectory, or Agent,
-- applying a given function to each of its Cells. If any of the function calls returns
-- false, forEachCell() stops and returns false, otherwise it returns true.
-- @arg cs A CellularSpace, Trajectory, or Agent. Agents need to have a placement
-- in order to execute this function.
-- @arg _sof_ A user-defined function that takes a Cell as argument.
-- It can optionally have a second argument with a positive number representing the position of
-- the Cell in the vector of Cells. If it returns false when processing a given Cell,
-- forEachCell() stops and does not process any other Cell.
-- @usage cellularspace = CellularSpace{xdim = 10}
--
-- forEachCell(cellularspace, function(cell)
--     cell.water = 0
-- end)
-- @see Environment:createPlacement
function forEachCell(cs, _sof_)
	local t = type(cs)
	if t ~= "CellularSpace" and t ~= "Trajectory" and t ~= "Agent" then
		incompatibleTypeError(1, "CellularSpace, Trajectory, or Agent", cs)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	for i, cell in ipairs(cs.cells) do
		if _sof_(cell, i) == false then return false end
	end
	return true
end

--- Second order function to traverse two CellularSpaces with the same resolution and
-- size. It applies a function that gets two Cells as arguments, one from each
-- CellularSpace. Both Cells share the same (x, y) location.
-- It returns true if no call to the function taken as argument returns false, otherwise
-- it returns false.
-- @arg cs1 A CellularSpace.
-- @arg cs2 Another CellularSpace.
-- @arg _sof_ A user-defined function that takes two Cells as arguments, one coming from the
-- first argument and the other from the second one.
-- If some call returns false, forEachCellPair() stops and does not
-- process any other pair of Cells.
-- @usage cs1 = CellularSpace{
--     xdim = 10,
--     instance = Cell{water = Random{min = 0, max = 20}}
-- }
-- cs2 = CellularSpace{xdim = 10}
--
-- forEachCellPair(cs1, cs2, function(cell1, cell2)
--     cell2.water = cell1.water
--     cell1.water = 0
-- end)
function forEachCellPair(cs1, cs2, _sof_)
	if type(cs1) ~= "CellularSpace" then
		incompatibleTypeError(1, "CellularSpace", cs1)
	elseif type(cs2) ~= "CellularSpace" then
		incompatibleTypeError(2, "CellularSpace", cs2)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(3, "function", _sof_)
	end

	verify(#cs1 == #cs2, "CellularSpaces should have the same size.")

	for i, cell1 in ipairs(cs1.cells) do
		local cell2 = cs2.cells[i]
		if _sof_(cell1, cell2, i) == false then return false end
	end
	return true
end

--- Second order function to traverse the connections of a given Agent, applying a function to
-- each of them. It returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- There are two ways of using this function because the second argument is optional.
-- @arg agent An Agent.
-- @arg name (Optional) A string with the name of the SocialNetwork to be traversed. The default value is "1".
-- @arg _sof_ A function that takes three arguments: the Agent itself, its connection, and the
-- connection weight. If some call to f returns false, forEachConnection() stops and does not
-- process any other connection. In the case where the second argument is missing, this
-- function becomes the second argument.
-- @usage ag = Agent{
--     value = 2,
--     on_message = function() print("thanks") end
-- }
--
-- soc = Society{instance = ag, quantity = 10}
--
-- soc:createSocialNetwork{quantity = 3}
--
-- forEachConnection(soc:sample(), function(ag1, ag2)
--     ag1:message{receiver = ag2}
-- end)
-- @see Society:createSocialNetwork
function forEachConnection(agent, name, _sof_)
	if type(agent) ~= "Agent" then
		incompatibleTypeError(1, "Agent", agent)
	elseif type(name) == "function" then
		_sof_ = name
		name = "1"
	elseif type(name) ~= "string" then
		incompatibleTypeError(2, "function or string", name)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(3, "function", _sof_)
	end

	local socialnetwork = agent:getSocialNetwork(name)
	if not socialnetwork then
		customError("Agent does not have a SocialNetwork named '"..name.."'.")
	end

	for mname, connection in pairs(socialnetwork.connections) do
		local weight = socialnetwork.weights[mname]
		if _sof_(agent, connection, weight) == false then return false end
	end

	return true
end

--- Second order function to traverse a given object, applying a function to each of its
-- elements. It can be used for instance to traverse all the elements of an Agent or an
-- Environment. According to the current Lua version, if one uses this function twice, Lua
-- does not guarantee that the objects will be traversed in the same order. If you need to
-- guarantee this, it is recommended to use Utils:forEachOrderedElement() instead.
-- This function returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- @arg obj A TerraME object or a table.
-- @arg _sof_ A user-defined function that takes three arguments: the name of the element,
-- the element itself, and the type of the element. If some call to this function returns
-- false then forEachElement() stops.
-- @usage cell = Cell{
--     value1 = 10,
--     value2 = 5
-- }
--
-- forEachElement(cell, function(idx, _, etype)
--     print(idx.."\t"..etype)
-- end)
function forEachElement(obj, _sof_)
	if obj == nil then
		mandatoryArgumentError(1)
	elseif not isTable(obj) then
		incompatibleTypeError(1, "table", obj)
	elseif _sof_ == nil then
		mandatoryArgumentError(2)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	if type(obj) == "DataFrame" then
		local rows = obj:rows()

		return forEachOrderedElement(rows, function(idx)
			if _sof_(idx, obj[idx], "table") == false then return false end
		end)
	end

	for k, ud in pairs(obj) do
		local t = type(ud)
		if _sof_(k, ud, t) == false then return false end
	end

	return true
end

--- Second order function to traverse a given directory,
-- applying a given function on each of its files. Internal directories are
-- ignored. If any of the function calls returns
-- false, forEachFile() stops and returns false, otherwise it returns true.
-- @arg directory A string with the path to a directory, or a vector of files.
-- @arg _sof_ A user-defined function that takes a file name as argument. Note that
-- the name does not include the directory where the file is placed.
-- @usage forEachFile(packageInfo("base").path, function(file)
--     print(file)
-- end)
-- @see Directory:list
function forEachFile(directory, _sof_)
	if type(directory) == "string" then directory = Directory(directory) end

	mandatoryArgument(1, "Directory", directory)
	mandatoryArgument(2, "function", _sof_)

	if not directory:exists() then
		customError("Directory '"..directory.."' is not valid or does not exist.")
	end

	local files

	if not pcall(function() files = directory:list() end) then
		return true
	end

	local directoryIdx = {}

	for i = 1, #files do
		directoryIdx[files[i]] = true
	end

	return forEachOrderedElement(directoryIdx, function(file)
		if isFile(directory..file) then
			if _sof_(File(directory..file)) == false then return false end
		end
	end)
end

--- Second order function to traverse a given directory,
-- applying a given function on each of its internal directories.
-- If any of the function calls returns
-- false, forEachDirectory() stops and returns false, otherwise it returns true.
-- @arg directory A string with the path to a directory, or a vector of files.
-- @arg _sof_ A user-defined function that takes a file name as argument. Note that
-- the name does not include the directory where the file is placed.
-- @usage forEachDirectory(packageInfo("base").path, function(dir)
--     print(dir)
-- end)
-- @see Directory:list
function forEachDirectory(directory, _sof_)
	if type(directory) == "string" then directory = Directory(directory) end

	mandatoryArgument(1, "Directory", directory)
	mandatoryArgument(2, "function", _sof_)

	if not directory:exists() then
		customError("Directory '"..directory.."' is not valid or does not exist.")
	end

	local files
	if not pcall(function() files = directory:list() end) then
		return true
	end

	local directoryIdx = {}

	for i = 1, #files do
		directoryIdx[files[i]] = true
	end

	return forEachOrderedElement(directoryIdx, function(file)
		if isDirectory(directory..file) then
			if _sof_(Directory(directory..file)) == false then return false end
		end
	end)
end

local function getFilesRecursively(directory)
	local files = {}

	if not directory:exists() then return files end

	_Gtme.forEachDirectory(directory, function(dir)
		for _, v in ipairs(getFilesRecursively(dir)) do
			table.insert(files, v)
		end
	end)

	_Gtme.forEachFile(directory, function(file)
		table.insert(files, file)
	end)

	return files
end

--- Second order function to traverse a given directory recursively,
-- applying a given function on each of its internal files.
-- If any of the function calls returns
-- false, forEachRecursiveDirectory() stops and returns false, otherwise it returns true.
-- @arg directory A string with the path to a directory, or a base::Directory.
-- @arg _sof_ A user-defined function that takes a file path as argument.
-- @usage forEachRecursiveDirectory(packageInfo("base").path.."data", function(file)
--     print(file)
-- end)
function forEachRecursiveDirectory(directory, _sof_)
	local dir = directory

	if type(dir) ~= "Directory" then
		if type(dir) == "string" then
			dir = Directory(dir)
		else
			customError("Argument '#1' must be a 'Directory' or 'string' path.")
		end
	end

	return forEachElement(getFilesRecursively(dir), function(_, file)
		if _sof_(file) == false then return false end
	end)
end

--- Second order function to traverse the instances of Models within a given Environment.
-- It applies a given function on each of its instances. If any of the function calls returns
-- false, forEachModel() stops and returns false, otherwise it returns true.
-- @arg env An Environment.
-- @arg _sof_ A user-defined function that takes an instance of Model as first argument and
-- its name within the Environment as second argument.
-- @usage MyTube = Model{
--     water = 200,
--     sun = Choice{min = 0, default = 10},
--     init = function(model)
--         model.finalTime = 100
--
--         model.timer = Timer{
--             Event{action = function()
--                 -- ...
--             end}
--         }
--     end
-- }
--
-- e = Environment{
--     scenario0 = MyTube{},
--     scenario1 = MyTube{water = 100},
--     scenario2 = MyTube{water = 100, sun = 5},
--     scenario3 = MyTube{water = 100, sun = 10}
-- }
--
-- forEachModel(e, function(model, name)
--     print(name.."  "..model:title())
-- end)
function forEachModel(env, _sof_)
	mandatoryArgument(1, "Environment", env)
	mandatoryArgument(2, "function", _sof_)

	forEachOrderedElement(env, function(idx, value)
		if isModel(value) then
			if _sof_(value, idx) == false then return false end
		end
	end)

	return true
end

--- Second order function to traverse a given Neighborhood of a Cell, applying a
-- function in each of its neighbors. It returns true if no call to the function taken as
-- argument returns false, otherwise it returns false.
-- There are two ways of using this function because the second argument is optional.
-- @arg cell A Cell.
-- @arg name (Optional) A string with the name of the Neighborhood to be traversed.
-- The default value is "1".
-- @arg _sof_ A user-defined function that takes three arguments: the Cell itself, the neighbor
-- Cell, and the connection weight. If some call to it returns false, forEachNeighbor() stops
-- and does not process any other neighbor. In the case where the second argument is missing,
-- this function becomes the second argument.
-- @usage cs = CellularSpace{
--     xdim = 10,
--     instance = Cell{deforestation = Random{min = 0, max = 1}}
-- }
--
-- cs:createNeighborhood()
--
-- forEachNeighbor(cs:sample(), function(cell, neighbor)
--     if neighbor.deforestation > 0.9 then
--         cell.deforestation = cell.deforestation * 1.01
--     end
-- end)
--
-- cs:createNeighborhood{
--     strategy = "vonneumann",
--     name = "vonneumann",
--     self = true
-- }
--
-- forEachNeighbor(cs:sample(), "vonneumann", function(cell, neighbor)
--     if cell.deforestation <= neighbor.deforestation then
--         cell.deforestation = neighbor.deforestation
--     end
-- end)
-- @see CellularSpace:createNeighborhood
-- @see CellularSpace:loadNeighborhood
function forEachNeighbor(cell, name, _sof_)
	if type(cell) ~= "Cell" then
		incompatibleTypeError(1, "Cell", cell)
	elseif type(name) == "function" then
		_sof_ = name
		name = "1"
	elseif type(name) ~= "string" then
		incompatibleTypeError(2, "function or string", name)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(3, "function", _sof_)
	end

	local neighborhood = cell:getNeighborhood(name)
	if neighborhood == nil then
		if name == "1" then
				customError("The CellularSpace does not have a default neighborhood. Please call 'CellularSpace:createNeighborhood' first.")
		else
			customError("Neighborhood '"..name.."' does not exist.")
		end
	end

	neighborhood.cObj_:first()

	while not neighborhood.cObj_:isLast() do
		local neigh = neighborhood.cObj_:getNeighbor()
		local weight = neighborhood.cObj_:getWeight()
		if _sof_(cell, neigh, weight) == false then return false end
		neighborhood.cObj_:next()
	end

	return true
end

--- Second order function to traverse the Agents within the neighbor Cells fom the
-- current location of a given Agent, applying a function to each of them.
-- This function requires that the Agent has a default placement ("placement") and
-- its Cell has a default Neighborhood ("1"). More complex placements and neighborhoods
-- need to be traversed manually using Agent:getCell() and Cell:getNeighborhood().
-- It returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- @arg agent An Agent.
-- @arg _sof_ A function that takes one single Agent as argument. This function is called
-- once for each agent within a neighbor cell of the current cell where the Agent belongs.
-- If some call to it returns false, forEachNeighborAgent() stops and does not process
-- any other Agent.
-- @usage ag = Agent{age = Random{min = 0, max = 2}}
-- soc = Society{
--     instance = ag,
--     quantity = 5
-- }
--
-- cs = CellularSpace{xdim = 5}
-- cs:createNeighborhood{}
--
-- env = Environment{soc, cs}
-- env:createPlacement{}
--
-- forEachNeighborAgent(soc:sample(), function(agent)
--     print("Found Agent "..agent.id)
-- end)
-- @see CellularSpace:createNeighborhood
-- @see Environment:createPlacement
function forEachNeighborAgent(agent, _sof_)
	if type(agent) ~= "Agent" then
		incompatibleTypeError(1, "Agent", agent)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	local cell = agent:getCell()

	forEachNeighbor(cell, function(_, neigh)
		forEachAgent(neigh, function(ag)
			if _sof_(ag) == false then return false end
		end)
	end)
end

--- Second order function to traverse all Neighborhoods of a Cell, applying a given function
-- on them. It returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- @arg cell A Cell.
-- @arg _sof_ A function that receives a Neighborhood name as argument.
-- @usage cs = CellularSpace{
--     xdim = 10
-- }
--
-- cs:createNeighborhood()
-- cs:createNeighborhood{
--     name = "2"
-- }
--
-- cell = cs:sample()
-- forEachNeighborhood(cell, function(idx)
--     print(idx)
--     print(#cell:getNeighborhood(idx))
-- end)
function forEachNeighborhood(cell, _sof_)
	if type(cell) ~= "Cell" then
		incompatibleTypeError(1, "Cell", cell)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	cell.cObj_:first()
	while not cell.cObj_:isLast() do
		local idx = cell.cObj_:getCurrentNeighborhood():getID()
		if _sof_(idx) == false then return false end
		cell.cObj_:next()
	end

	return true
end

local function greaterString(str1, str2)
	local countChar = 1

	local size1 = string.len(str1)
	local size2 = string.len(str2)

	local ch1 = string.sub(str1, countChar, countChar)
	local ch2 = string.sub(str2, countChar, countChar)

	while countChar <= size1 and countChar <= size2 and ch1 == ch2 do
		countChar = countChar + 1

		ch1 = string.sub(str1, countChar, countChar)
		ch2 = string.sub(str2, countChar, countChar)
	end

	local last1 = string.sub(str1, countChar - 1, countChar - 1)
	local last2 = string.sub(str2, countChar - 1, countChar - 1)

	local function upper(str)
		return string.lower(str) ~= str
	end

	if countChar > size1 then
		return  last1 == last2
	elseif countChar > size2 then
		return last1 ~= last2
	elseif string.lower(ch1) == string.lower(ch2) then
		return string.lower(ch1) ~= ch1
	elseif upper(ch1) and not upper(ch2) then
		return true
	elseif not upper(ch1) and upper(ch2) then
		return false
	else
		return ch1 < ch2
	end
end

--- Second order function to traverse a given object, applying a function to each of its
-- elements according to their alphabetical order. It can be used for instance to traverse all
-- the elements of an Agent or an Environment. This function executes first the positions with
-- numeric names and then the string ones, with
-- upper case characters having priority over lower case.
-- This function returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- @arg obj A TerraME object or a table.
-- @arg _sof_ A user-defined function that takes three arguments: the name of the element,
-- the element itself, and the type of the element. If some call to this function returns
-- false then forEachElement() stops.
-- @usage cell = Cell{
--     value1 = 10,
--     value2 = 5
-- }
--
-- forEachOrderedElement(cell, function(idx, _, etype)
--     print(idx.."\t"..etype)
-- end)
function forEachOrderedElement(obj, _sof_)
	if obj == nil then
		mandatoryArgumentError(1)
	elseif not isTable(obj) then
		incompatibleTypeError(1, "table", obj)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	local sorder = {}
	local norder = {}
	local nreference = {}

	for k in pairs(obj) do
		if type(k) == "string" then
			local count = 1

			while count <= #sorder and greaterString(sorder[count], k) do
				count = count + 1
			end

			table.insert(sorder, count, k)
		else
			table.insert(norder, k)
			nreference[k] = k
		end
	end

	table.sort(norder)

	for k = 1, #norder do
		local idx = nreference[norder[k]]
		if _sof_(idx, obj[idx], type(obj[idx])) == false then return false end
	end

	for k = 1, #sorder do
		local ref = sorder[k]
		if _sof_(ref, obj[ref], type(obj[ref])) == false then return false end
	end

	return true
end

--- Second order function to traverse all SocialNetworks of an Agent, applying a given function
-- on them. It returns true if no call to the function taken as argument returns false,
-- otherwise it returns false.
-- @arg agent An Agent.
-- @arg _sof_ A function that receives a SocialNetwork name as argument.
-- @usage ag = Agent{value = 2}
-- soc = Society{instance = ag, quantity = 20}
--
-- soc:createSocialNetwork{quantity = 3}
-- soc:createSocialNetwork{
--     quantity = 5,
--     name = "2"
-- }
--
-- agent = soc:sample()
-- forEachSocialNetwork(agent, function(idx)
--     print(idx)
--     print(#agent:getSocialNetwork(idx))
-- end)
function forEachSocialNetwork(agent, _sof_)
	if type(agent) ~= "Agent" then
		incompatibleTypeError(1, "Agent", agent)
	elseif type(_sof_) ~= "function" then
		incompatibleTypeError(2, "function", _sof_)
	end

	for idx in pairs(agent.socialnetworks) do
		if _sof_(idx) == false then return false end
	end

	return true
end

local config

--- Return a table with the content of the file config.lua, stored in the current directory
-- of the simulation. All the global variables of the file are elements of the returned table.
-- Some packages require specific variables in this file in order to be tested or executed.
-- Additional calls to getConfig will return the same output of the first call even
-- if the current directory changes along the simulation.
-- @usage getConfig()
function getConfig()
	if config then
		return config
	elseif not File("config.lua"):exists() then
		customError("There is no 'config.lua' in the current directory.") -- SKIP
	else
		config = getLuaFile("config.lua") -- SKIP
		return config
	end
end


-- The following function was implemented using the code available at http://stackoverflow.com/questions/17673657/loading-a-file-and-returning-its-environment

--- Load a lua file and return its global values as a Lua table.
-- @arg scriptfile A File or a string with a file name.
-- @arg basetable An optional table where the new values will be placed.
-- @usage print(getLuaFile(packageInfo("base").path.."description.lua").version)
function getLuaFile(scriptfile, basetable)
	if type(scriptfile) == "string" then
		scriptfile = File(scriptfile)
	end

	mandatoryArgument(1, "File", scriptfile)
	optionalArgument(2, "table", basetable)

	if basetable == nil then
		basetable = {}
	end

	local env = setmetatable(basetable, {__index = _G})
	if not scriptfile:exists() then
		_Gtme.customError("File '"..scriptfile.."' does not exist.")
	end
	local lf = loadfile(tostring(scriptfile), "t", env)

	if lf == nil then
		_Gtme.printError("Could not load file '"..scriptfile.."'.")
		dofile(tostring(scriptfile)) -- this line will show the error when parsing the file
	end

	lf()

	return setmetatable(env, nil)
end


--- Return the number of elements of a table, be them named or not.
-- It is a substitute for the old Lua function table.getn. It can
-- also be used to compute the number of elements of any TerraME
-- object, such as Agent or Environment.
-- @arg t A table.
-- @usage getn{name = "john", age = 20}
function getn(t)
	if not isTable(t) then
		incompatibleTypeError(1, "table", t)
	end

	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end

	return n
end

--- Return the names of a given object derived from a table.
-- The output is a vector with the names as values alphabetically ordered.
-- @arg data Any table or TerraME type that works as a table.
-- @see Utils:isTable
-- @usage t = {
--     cover = "forest",
--     area = 200,
--     water = false
-- }
--
-- getNames(t) -- {"area", "cover", "water"}
function getNames(data)
	if not isTable(data) then
		incompatibleTypeError(1, "table", data)
	end

	local result = {}

	forEachOrderedElement(data, function(idx)
		table.insert(result, idx)
	end)

	return result
end

--- Return a function that compares two tables (which can be, for instance, Agents or Cells).
-- The function returns which one has a priority over the other, according to an attribute of the
-- objects and a given operator. If the function was not successfully built it returns nil.
-- @arg attribute A string with the name of the attribute.
-- @arg operator A string with the operator, which can be ">", "<", "<=", or ">=". The default value is "<".
-- @usage cs = CellularSpace{
--     xdim = 10,
--     instance = Cell{cover = Random{min = 0, max = 1}}
-- }
--
-- t = Trajectory{
--     target = cs,
--     greater = greaterByAttribute("cover")
-- }
-- @see Trajectory
-- @see Group
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
-- @usage cs = CellularSpace{
--     xdim = 10
-- }
--
-- t = Trajectory{
--     target = cs,
--     greater = greaterByCoord()
-- }
-- @see Trajectory
function greaterByCoord(operator)
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

--- A second order function to numerically solve ordinary differential equations with a given
-- initial value.
-- @arg attrs.method the name of a numeric algorithm to solve the ordinary differential
-- equations. See the options below.
-- @tabular method
-- Method & Description \
-- "euler" (default) & Euler integration method \
-- "heun" & Heun (Second Order Euler) \
-- "rungekutta" & Runge-Kutta Method (Fourth Order)
-- @arg attrs.equation A differential equation or a vector of differential equations. Each
-- equation is described as a function of one or two arguments that returns a value of its
-- derivative f(t, y), where t is the time instant, and y starts with the value of attribute
-- initial and changes according to the result of f() and the chosen method. The calls to f
-- will use the first argument (t) in the interval [a,b[, according to the argument step.
-- @arg attrs.initial The initial condition, or a vector of initial conditions, which must be
-- satisfied. Each initial condition represents the value of y when t (first argument of f)
-- is equal to the value of argument a.
-- @arg attrs.a A number with the beginning of the interval.
-- @arg attrs.b A number with the end of the interval.
-- @arg attrs.step A positive number with the step within the interval. It must
-- satisfy the condition that (b - a) is a multiple of step.
-- @arg attrs.event An Event that can be used to set arguments a and b with values
-- event:getTime() - event:getPeriodicity() and event:getTime(), respectively. The period of the
-- event must be a multiple of step. Note that the first execution of the event will compute the
-- equation relative to a time interval between event.time - event.period and event.time. Be
-- careful about that, as it can start before the initial Event of the simulation.
-- @usage v = integrate{
--     equation = function(t, y)
--         return t - 0.1 * y
--     end,
--     initial = 0,
--     a = 0,
--     b = 100,
--     step = 0.1
-- }
function integrate(attrs)
	verifyNamedTable(attrs)
	verifyUnnecessaryArguments(attrs, {"a", "b", "event", "method", "initial", "equation", "step"})

	if attrs.event ~= nil then
		mandatoryTableArgument(attrs, "event", "Event")
		verify(attrs.a == nil, "Argument 'a' should not be used together with argument 'event'.")
		verify(attrs.b == nil, "Argument 'b' should not be used together with argument 'event'.")
		attrs.a = attrs.event:getTime() - attrs.event:getPeriod()
		attrs.b = attrs.event:getTime()
	end

	if type(attrs.equation) ~= "function" then
		mandatoryTableArgument(attrs, "equation", "table")

		forEachElement(attrs.equation, function(_, value)
			if type(value) ~= "function" then
				customError("Table 'equation' should contain only functions, got "..type(value)..".")
			end
		end)

		mandatoryTableArgument(attrs, "initial", "table")
	end

	if type(attrs.initial) ~= "number" then
		mandatoryTableArgument(attrs, "initial", "table")
		mandatoryTableArgument(attrs, "equation", "table")

		forEachElement(attrs.initial, function(_, value)
			if type(value) ~= "number" then
				customError("Table 'initial' should contain only numbers, got "..type(value)..".")
			end
		end)

		if #attrs.equation ~= #attrs.initial then
			customError("Tables equation and initial shoud have the same size.")
		end
	end

	mandatoryTableArgument(attrs, "step", "number")
	positiveTableArgument(attrs, "step")

	defaultTableValue(attrs, "method", "euler")

	local result = switch(attrs, "method"):caseof {
		euler = function() return integrationEuler(attrs.equation, attrs.initial, attrs.a, attrs.b, attrs.step) end,
		rungekutta = function() return integrationRungeKutta(attrs.equation, attrs.initial, attrs.a, attrs.b, attrs.step) end,
		heun = function() return integrationHeun(attrs.equation, attrs.initial, attrs.a, attrs.b, attrs.step) end
	}

	if type(attrs.equation) == "table" then
		local str = "return "..result[1]
		for i = 2, getn(attrs.equation) do
			str = str ..", "..result[i]
		end
		return load(str)()
	end

	return result
end

--- Implements the Euler (Euler-Cauchy) Method to integrate ordinary differential equations.
-- @arg df The differential equation.
-- @arg initCond The initial condition that must be satisfied.
-- @arg a The value of 'a' in the interval [a,b[.
-- @arg b The value of 'b' of in the interval [a,b[.
-- @arg delta The step of the independent variable.
-- @usage f = function(x) return x^3 end
-- v = integrationEuler(f, 0, 0, 3, 0.1)
function integrationEuler(df, initCond, a, b, delta)
	if type(df) == "function" then
		local y = initCond
		local bb = b - delta
		for x = a, bb, delta do
			y = y + delta * df(x, y)
		end

		return y
	else
		local y = initCond
		local bb = b - delta
		local values = {} -- each equation must be computed from the same "past" value ==> o(n2),
		                  -- where n is the number of equations
		for x = a, bb, delta do
			for i = 1, #df do
				values[i] = df[i](x, y)
			end

			for i = 1, #df do
				y[i] = y[i] + delta * values[i]
			end
		end

		return y
	end
end

--- Implements the Heun (Euler Second Order) Method to integrate ordinary differential equations.
-- It is a method of type Predictor-Corrector.
-- @arg df The differential equation.
-- @arg initCond The initial condition that must be satisfied.
-- @arg a The value of 'a' in the interval [a,b[.
-- @arg b The value of 'b' of in the interval [a,b[.
-- @arg delta The step of the independent variable.
-- @usage f = function(x) return x^3 end
-- v = integrationHeun(f, 0, 0, 3, 0.1)
function integrationHeun(df, initCond, a, b, delta)
	if type(df) == "function" then
		local y = initCond
		local y1
		local val
		local bb = b - delta
		for x = a, bb, delta do
			val = df(x, y)
			y1 = y + delta * val
			y = y + 0.5 * delta * (val + df(x + delta, y1))
		end

		return y
	else
		local y = initCond
		local bb = b - delta
		local sizeDF = #df
		for x = a, bb, delta do
			local val = {}
			local y1 = {}
			for i = 1, sizeDF do
				val[i] = df[i](x, y)
				y1[i] = y[i] + delta * val[i]
			end

			local values = {}
			for i = 1, sizeDF do
				values[i] = df[i](x + delta, y1)
			end

			for i = 1, sizeDF do
				y[i] = y[i] + 0.5 * delta * (val[i] + values[i])
			end
		end

		return y
	end
end

--- Implements the Runge-Kutta Method (Fourth Order) to integrate ordinary differential equations.
-- @arg df The differential equation.
-- @arg initCond The initial condition that must be satisfied.
-- @arg a The value of 'a' in the interval [a,b[.
-- @arg b The value of 'b' of in the interval [a,b[.
-- @arg delta The step of the independent variable.
-- @usage f = function(x) return x^3 end
-- v = integrationRungeKutta(f, 0, 0, 3, 0.1)
function integrationRungeKutta(df, initCond, a, b, delta)
	if type(df) == "function" then
		local y = initCond
		local y1
		local y2
		local y3
		local y4
		local bb = b - delta
		local midDelta = 0.5 * delta
		for x = a, bb, delta do
			y1 = df(x, y)
			y2 = df(x + midDelta, y + midDelta * y1)
			y3 = df(x + midDelta, y + midDelta * y2)
			y4 = df(x + delta, y + delta* y3)
			y = y + delta * (y1 + 2 * y2 + 2 * y3 + y4) / 6
		end

		return y
	else
		local y = initCond
		local y1
		local y2
		local y3
		local y4
		local bb = b - delta
		local midDelta = 0.5 * delta
		local sizeDF = #df
		for x = a, bb, delta do
			local yTemp = {}
			local values = {}
			for i = 1, sizeDF do
				yTemp[i] = y[i]
			end

			for i = 1, sizeDF do
				y1 = df[i](x, y)
				yTemp[i] = y[i] + midDelta * y1
				y2 = df[i](x + midDelta, yTemp)
				yTemp[i] = y[i] + midDelta * y2
				y3 = df[i](x + midDelta, yTemp)
				yTemp[i] = y[i] + delta * y3
				y4 = df[i](x + delta, yTemp)
				values[i] = y[i] + delta * (y1 + 2 * y2 + 2 * y3 + y4) / 6
			end

			for i = 1, sizeDF do
				y[i] = values[i]
			end
		end

		return y
	end
end

--- Return whether an object can be used as a table. This includes
-- tables themselves as well as all TerraME types (Cell, CellularSpace, etc.).
-- @arg data A value of any type.
-- @see Utils:type
-- @usage c = Cell{}
-- print(isTable(c))
function isTable(data)
	return _Gtme.type(data) == "table"
end
--- Return the Levenshtein's distance between two strings.
-- See http://en.wikipedia.org/wiki/Levenshtein_distance for more details.
-- @arg s A string.
-- @arg t Another string.
-- @usage levenshtein("abc", "abb")
function levenshtein(s, t)
	mandatoryArgument(1, "string", s)
	mandatoryArgument(2, "string", t)

	if s == t then return 0 end

	local d, sn, tn = {}, #s, #t

	if sn > tn then -- invert arguments
		sn, tn = tn, sn
		s, t = t, s
	end

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
-- @usage round(2.34566, 3)
function round(num, idp)
	mandatoryArgument(1, "number", num)
	optionalArgument(2, "number", idp)

	if not idp then idp = 0 end

	local mult = 10 ^ idp
	return math.floor(num * mult + 0.5) / mult
end

--- Convert a string into a more readable name. It is useful to work
-- with Model:init() when the model will be available through a graphical interface.
-- In graphical interfaces (see OS:sessionInfo()), if the string contains underscores, it
-- replaces them by spaces and convert the next characters to uppercase.
-- Otherwise, it adds a space before each uppercase character.
-- It also converts the first character of the string to uppercase.
-- @arg mstring A string with the parameter name.
-- @arg parent A string with the name of the table the parameter belongs to.
-- This parameter is optional.
-- @usage toLabel("maxValue") --  'Max Value' (with graphical interface) or 'maxValue' (without)
function toLabel(mstring, parent)
	if type(mstring) == "number" then
		mstring = tostring(mstring)
	end

	mandatoryArgument(1, "string", mstring)
	optionalArgument(2, "string", parent)

	if sessionInfo().interface then
		mstring = "'".._Gtme.stringToLabel(mstring).."'"

		if parent then
			mstring = mstring.." (in '".._Gtme.stringToLabel(parent).."')"
		end

		return mstring
	elseif parent then
		return "'"..parent.."."..mstring.."'"
	else
		return "'"..mstring.."'"
	end
end

--- Return whether a string ends with a given substring (no case sensitive).
-- @arg str A string.
-- @arg send A substring describing the end of #1.
-- @usage string.endswith("abcdef", "def")
function string.endswith(str, send)
	send = send:lower().."$"
	return str:lower():match(send) ~= nil
end

--- Implement a switch case function, where functions are associated to the available options.
-- This function returns a table that contains a function called caseof, that gets a named
-- table with functions describing what to do for each case (which is the name for the respective
-- function). This table can have a field "missing" that is used when
-- the first argument does not have an attribute whose name is the value of the second argument.
-- The error messages of this function come from ErrorHandling:switchInvalidArgumentMsg() and
-- ErrorHandling:switchInvalidArgumentSuggestionMsg().
-- @arg data A named table.
-- @arg att A string with the chosen attribute of the named table.
-- @usage data = {protocol = "udp"}
--
-- switch(data, "protocol"):caseof{
--     tcp = function() print("tcp") end,
--     udp = function() print("udp") end
-- }
function switch(data, att)
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
-- @see Utils:isTable
-- @usage c = Cell{value = 3}
-- print(type(c)) -- "Cell"
function type(data)
	local t = _Gtme.type(data)
	if t == "table" then
		if data.type_ ~= nil then
			return data.type_
		end
	end

	return t
end

local function recursiveVardump(o, indent, tables)
	if isTable(o) then
		if tables[o] then
			return "\"<copy of another table above>\""
		end

		tables[o] = true
	end

	if indent == nil then indent = "" end

	local indent2 = indent.."    "
	if isTable(o) then
		if getn(o) == 0 then
			return "{}"
		end

		local s = "{".."\n"

		if type(o) ~= "table" then
			s = type(o)..s
		end

		local first = true
		local count = 1

		forEachOrderedElement(o, function(k, v)
			if k == "parent" then v = type(v) end

			if first == false then s = s .. ",\n" end

			first = false

			s = s..indent2
			if type(k) == "string" then
				local char = string.sub(k, 1, 1)
				if string.match(k, "[%w_]+") == k and string.match(char, "%a") == char then
					s = s..tostring(k).." = "..recursiveVardump(v, indent2, tables)
				else
					s = s.."[\""..tostring(k).."\"] = "..recursiveVardump(v, indent2, tables)
				end
			elseif type(k) == "boolean" then
				s = s.."["..tostring(k).."] = "..recursiveVardump(v, indent2, tables)
			elseif type(k) == "number" then
				if k ~= count then
					s = s.."["..k.."] = "
				else
					count = count + 1
				end

				s = s..recursiveVardump(v, indent2, tables)
			else
				customError("Function vardump cannot handle an index of type "..type(k)..".")
			end
		end)

		return s.."\n"..indent.."}"
	elseif type(o) == "number" then
		return tostring(o)
	elseif type(o) == "boolean" then
		return tostring(o)
	else
		return "\""..string.gsub(tostring(o), "\n", "\\n").."\""
	end
end

-- This function is taken from https://gist.github.com/lunixbochs/5b0bb27861a396ab7a86
--- Function that returns a string describing the internal content of an object.
-- It converts a table into a string that represents a Lua code that declares such table.
-- If some internal object is named "parent", it will be converted into a string with the
-- type of the object. It avoids infinite loops due to the internal cyclic representation
-- of TerraME.
-- @arg o The object to be converted into a string.
-- @arg indent A string to be placed in the beginning of each line of the returning string.
-- @usage vardump{name = "john", age = 20}
-- -- {
-- --     age = 20,
-- --     name = "john"
-- -- }
function vardump(o, indent)
	return recursiveVardump(o, indent, {})
end

