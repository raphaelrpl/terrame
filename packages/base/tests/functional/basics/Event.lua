-------------------------------------------------------------------------------------------
-- TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
-- Copyright (C) 2001-2014 INPE and TerraLAB/UFOP.
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
--          Pedro R. Andrade (pedro.andrade@inpe.br)
-------------------------------------------------------------------------------------------

return{
	Event = function(unitTest)
		local event = Event{action = function() end}

		unitTest:assertEquals(event:getTime(), 1)
		unitTest:assertEquals(event:getPeriod(), 1)
		unitTest:assertEquals(event:getPriority(), 0)
		unitTest:assertEquals(type(event), "Event")

		event = Event{start = 0.5, period = 2, priority = 1, action = function() end}

		unitTest:assertEquals(event:getTime(), 0.5)
		unitTest:assertEquals(event:getPeriod(), 2)
		unitTest:assertEquals(event:getPriority(), 1)

		event = Event{start = -1, period = 2, priority = -5.2, action = function() end}

		unitTest:assertEquals(event:getTime(), -1)
		unitTest:assertEquals(event:getPeriod(), 2)
		unitTest:assertEquals(event:getPriority(), -5.2)

		event = Event{start = 0.5, period = 2, priority = "verylow", action = function() end}
		unitTest:assertEquals(event:getPriority(), 10)

		event = Event{start = 0.5, period = 2, priority = "low", action = function() end}
		unitTest:assertEquals(event:getPriority(), 5)

		event = Event{start = 0.5, period = 2, priority = "veryhigh", action = function() end}
		unitTest:assertEquals(event:getPriority(), -10)

		local count = 0

		local ag = Agent{
			execute = function()
				count = count + 100
			end
		}

		local soc = Society{
			instance = ag,
			quantity = 5
		}

		local c = Cell{
			execute = function()
				count = count + 1
			end
		}

		local sum = 0

		local cinstance = Cell{
			execute = function()
				sum = sum + 1
			end
		}

		local cs = CellularSpace{
			xdim = 5,
			instance = cinstance
		}

		forEachCell(cs, function(cell)
			cell.value = Random():integer(10)
		end)

		local traj = Trajectory{target = cs, greater = function(c1, c2) return c1.value > c2.value end}

		local m = Model{
			finalTime = 10,
			init = function(model)
				model.execute = function()
					count = count + 10
				end

				model.timer = Timer{
					Event{action = model}
				}
			end
		}

		local instance = m{}

		local t = Timer{
			Event{action = soc}, -- 1000
			Event{action = c},   -- 2
			Event{action = cs},
			Event{action = instance}, -- 20
			Event{action = ag},  -- 100
			Event{action = traj}
		}

		t:run(2)
		unitTest:assertEquals(count, 1222)
		unitTest:assertEquals(sum, 5 * 5 * 2 + #traj * 2)

		cs = CellularSpace{xdim = 5}

		t = Timer{
			Event{action = cs}
		}

		t:run(2)

		unitTest:assertType(cs.cells[1].past, "table")

		sum = 0

		ag = Agent{
			on_message = function()
				sum = sum + 1
			end
		}

		soc = Society{
			instance = ag,
			quantity = 5
		}

		for i = 1, 10 do
			soc.agents[1]:message{
				receiver = soc.agents[2],
				delay = i
			}
		end

		t = Timer{
			Event{action = soc}
		}

		t:run(5)
		unitTest:assertEquals(sum, 5)

		local log = Log{
			target = soc,
			file = "logfile-event.csv"
		}

		event = Event{action = log}

		unitTest:assertEquals(event:getPeriod(), 1)
		unitTest:assertEquals(event:getPriority(), 10)

		log:update()
		unitTest:assertFile("logfile-event.csv")
	end,
	config = function(unitTest)
		local event = Event{action = function() end}

		event:config{
			time = 0.5,
			period = 2,
			priority = 1
		}

		unitTest:assertEquals(event:getTime(), 0.5)
		unitTest:assertEquals(event:getPeriod(), 2)
		unitTest:assertEquals(event:getPriority(), 1)

		event:config{
			time = 1
		}

		unitTest:assertEquals(event:getTime(), 1)
		unitTest:assertEquals(event:getPeriod(), 2)
		unitTest:assertEquals(event:getPriority(), 1)
	end,
	getParent = function(unitTest)
		local event = Event{action = function()
			return false
		end}

		local timer = Timer{event}

		unitTest:assertEquals(timer, event.parent)

		timer:run(2)

		unitTest:assertNil(event.parent)
	end,
	getPeriod = function(unitTest)
		local event = Event{period = 2, action = function() end}
		unitTest:assertEquals(event:getPeriod(), 2)
	end,
	getPriority = function(unitTest)
		local event = Event{priority = -10, action = function() end}
		unitTest:assertEquals(event:getPriority(), -10)
	end,
	getTime = function(unitTest)
		local event = Event{start = -10, action = function() end}
		unitTest:assertEquals(event:getTime(), -10)
	end,
	__tostring = function(unitTest)
		local event = Event{start = -10, action = function() end}

		unitTest:assertEquals(tostring(event), [[action    function
period    number [1]
priority  number [0]
time      number [-10]
]])
	end
}

