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

return{
	notify = function(unitTest)
		local cs = CellularSpace{
			xdim = 5,
			myvalue = function() return 4 end
		}

		Chart{
			target = cs,
			select = "myvalue"
		}

		cs.myvalue = 3

		local error_func = function()
			cs:notify()
		end
		unitTest:assertError(error_func, "Could not execute function 'myvalue' from CellularSpace because it was replaced by a 'number'.")

		local c = Cell{value = function() return 5 end}

		cs = CellularSpace{
			xdim = 5,
			instance = c,
		}

		Map{
			target = cs,
			select = "value",
			value = {5, 8},
			color = {"red", "blue"}
		}

		cs:sample().value = 3

		error_func = function()
			cs:notify()
		end
		unitTest:assertError(error_func, "Could not execute function 'value' from Cell because it was replaced by a 'number'.")
  end
}

