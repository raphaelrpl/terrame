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
-------------------------------------------------------------------------------------------

return{
	DataFrame = function(unitTest)
		local error_func = function()
			DataFrame(2)
		end
		unitTest:assertError(error_func, incompatibleTypeMsg(1, "table", 2))

		error_func = function()
			DataFrame{{1, 2, 3}, x = {1, 2, 3}}
		end
		unitTest:assertError(error_func, "It is not possible to use named and non-named elements to create a DataFrame.")

		error_func = function()
			DataFrame{y = {1, 2, 3}, x = 1}
		end
		unitTest:assertError(error_func, "All arguments for DataFrame must be table values.")

		error_func = function()
			DataFrame{
				x = {1, 2, 3, 4, 5},
				y = {1, 1, 2, 2}
			}
		end
		unitTest:assertError(error_func, "All arguments for DataFrame must have the same size, got 5 ('x') and 4 ('y').")

		error_func = function()
			x = DataFrame{
				first = 2000,
				step = 10,
				last = 2025
			}
		end
		unitTest:assertError(error_func, "Invalid 'last' value (2025). It could be 2020.0 or 2030.0.")

		error_func = function()
			x = DataFrame{
				first = 2000,
				step = 10
			}
		end
		unitTest:assertError(error_func, "It is not possible to create a DataFrame from an empty table using arguments 'first' or 'step'.")

		error_func = function()
			x = DataFrame{
				first = 2000,
				step = 10,
				last = 2030,
				demand = {7, 8, 9}
			}
		end
		unitTest:assertError(error_func, "Argument 'demand' should range until position 2030, got 2020.")

		error_func = function()
			x = DataFrame{
				{demand = 7},
				{demand = 8},
				{demand = 9},
				first = 2000,
				step = 10,
				last = 2030
			}
		end
		unitTest:assertError(error_func, "Rows should range until position 2030, got 2020.")

		error_func = function()
			x = DataFrame{
				first = 2000,
				step = 10,
				demand = {7, 8, 9, 10},
				limit = {0.1, 0.04, 0.3}
			}
		end
		unitTest:assertError(error_func, "All arguments for DataFrame must have the same size, got 4 ('demand') and 3 ('limit').")

		error_func = function()
			x = DataFrame{
				instance = 10,
				demand = {7, 8, 9, 10},
				limit = {0.1, 0.04, 0.3}
			}
		end
		unitTest:assertError(error_func, "Argument 'instance' should be an isTable() object, got number.")
	end
}

