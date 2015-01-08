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
-- Authors: Pedro R. Andrade (pedro.andrade@inpe.br)
-------------------------------------------------------------------------------------------

return{
	Model = function(unitTest)
		local error_func = function()
			local Tube = Model{
				simulationSteps = {10, 20, "30"},
			}
		end
		unitTest:assert_error(error_func, "All the elements of table 'simulationSteps' should have the same type.")

		local error_func = function()
			local Tube = Model{
				simulationSteps = {aa = 3, bb = {10, 20, "30"}},
			}
		end
		unitTest:assert_error(error_func, "All the elements of table 'simulationSteps.bb' should have the same type.")

		local Tube = Model{
			setup = function(model) end,
		}

		local error_func = function()
			local m = Tube{}
		end
		unitTest:assert_error(error_func, "The object does not have a Timer or an Environment with at least one Timer.")

		local Tube = Model{
			setup = function(model)
				model.t = Timer{}
				model.t2 = Timer{}
			end,
		}

		local error_func = function()
			local m = Tube{}
		end
		unitTest:assert_error(error_func, "The object has two running objects: 't2' (Timer) and 't' (Timer).")

		local Tube = Model{
			setup = function(model)
				model.t = Timer{}
				model.e = Environment{t2 = Timer{}}
			end,
		}

		local error_func = function()
			local m = Tube{}
		end
		unitTest:assert_error(error_func, "The object has two running objects: 't' (Timer) and 'e' (Environment).")

		-- this test is necessary because it changes the searching order between the Timer and the Environment
		local Tube = Model{
			setup = function(model)
				model.e = Timer{}
				model.t = Environment{t2 = Timer{}}
			end,
		}

		local error_func = function()
			local m = Tube{}
		end
		unitTest:assert_error(error_func, "The object has two running objects: 't' (Environment) and 'e' (Timer).")

		local Tube = Model{
			simulationSteps = {10, 20, 30},
			initialWater    = 200,
			flow            = 20,
			observingStep   = 1,
			checkZero       = false,
			block           = {xmin = 0, xmax = math.huge, ymin = 0, ymax = math.huge},
			setup = function(model) model.timer = Timer{} end,
			check = function(model)
				verify(model.simulationSteps > 0, "Simulation steps should be greater than zero.")
				verify(model.initialWater > 0, "Initial water should be greater than zero.")
			end
		}

		local error_func = function()
			local m = Tube{flow = {a = 2}}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("flow", "number", {a = 2}))

		local error_func = function()
			local m = Tube{simulationSteps = 40}
		end
		unitTest:assert_error(error_func, incompatibleValueMsg("simulationSteps", "one of {10, 20, 30}", 40))

		local error_func = function()
			local m = Tube{s = 3}
		end
		unitTest:assert_error(error_func, "Attribute 's' does not exist in the Model.")

		local error_func = function()
			local m = Tube{checkZero = 3}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("checkZero", "boolean", 3))
	
		local error_func = function()
			local m = Tube{initialWater = -5}
		end
		unitTest:assert_error(error_func, "Initial water should be greater than zero.")

		local error_func = function()
			local m = Tube{block = {xmix = 5}}
		end
		unitTest:assert_error(error_func, "Attribute 'block.xmix' does not exist in the Model.")

		local error_func = function()
			local m = Tube{block = {xmin = false}}
		end
		unitTest:assert_error(error_func, incompatibleTypeMsg("block.xmin", "number", false))
			
		local Tube = Model{simulationSteps = 10}

		local Tube = Model{
			simulationSteps = 10,
			check = function() end
		}

		local error_func = function()
			local m = Tube{}
		end
		unitTest:assert_error(error_func, "Function 'setup' was not implemented by the Model.")
	end,
	execute = function(unitTest)
		local Tube = Model{
			finalTime = 10,
			setup = function(m) m.t = Timer{} end
		}
	
		local t = Tube{}

		local error_func = function()
			t:execute(5)
		end
		unitTest:assert_error(error_func, "execute() should not take any argument because the model already has a final time.")
	end,
	interface = function(unitTest)
		local error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				interface = function() return 2 end
			}
		end
		unitTest:assert_error(error_func, "Models with graphical interfaces should have finalTime as argument.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return 2 end
			}
		end
		unitTest:assert_error(error_func, "The returning value of interface() should be a table, got number.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return {2} end
			}
		end
		unitTest:assert_error(error_func, "There is an element in the interface() that is not a table.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return {{2}} end
			}
		end
		unitTest:assert_error(error_func, "All the elements in each interface() vector should be string, got number.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return {{"number", "number"}} end
			}
		end
		unitTest:assert_error(error_func, "Argument 'number' cannot be displayed twice in the interface().")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return {{"number", "string"}} end
			}
		end
		unitTest:assert_error(error_func, "There is no argument 'string' in the Model, although it is described in the interface().")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return {{"number", "table"}} end
			}
		end
		unitTest:assert_error(error_func, "There is no non-named table parameter in the Model, but it is described in the interface().")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				interface = function() return {{"number", "aaa"}} end
			}
		end
		unitTest:assert_error(error_func, "interface() element 'aaa' is not an argument of the Model.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				aaa = 3,
				interface = function() return {{"number", "aaa"}} end
			}
		end
		unitTest:assert_error(error_func, "interface() element 'aaa' is not a table in the Model.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				aaa = {1, 2, 3},
				interface = function() return {{"number", "aaa"}} end
			}
		end
		unitTest:assert_error(error_func, "interface() element 'aaa' is a non-named table in the Model.")

		error_func = function()
			local Tube = Model{
				simulationSteps = 10,
				finalTime = 5,
				aaa = {},
				interface = function() return {{"number", "aaa"}} end
			}
		end
		unitTest:assert_error(error_func, "interface() element 'aaa' is empty in the Model.")
	end
}

