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
-- Author: Pedro R. Andrade (pedro.andrade@inpe.br)
-------------------------------------------------------------------------------------------

return{
	Choice = function(unitTest)
		local c = Choice{1, 2, 3}

		unitTest:assertType(c, "Choice")
		unitTest:assertEquals(#c.values, 3)

		c = Choice{min = 2, max = 3, step = 0.1}
		unitTest:assertType(c, "Choice")
		unitTest:assertEquals(c.min, 2)
		unitTest:assertEquals(c.max, 3)
		unitTest:assertEquals(c.default, 2)
		unitTest:assertEquals(c.step, 0.1)

		c = Choice{min = 5, default = 7}
		unitTest:assertType(c, "Choice")
		unitTest:assertEquals(c.min, 5)
		unitTest:assertEquals(c.default, 7)

		c = Choice{min = 5}
		unitTest:assertType(c, "Choice")
		unitTest:assertEquals(c.default, 5)

		c = Choice{max = 5, default = 3}
		unitTest:assertType(c, "Choice")
		unitTest:assertEquals(c.max, 5)
		unitTest:assertEquals(c.default, 3)

		c = Choice{max = 5}
		unitTest:assertType(c, "Choice")
		unitTest:assertEquals(c.default, 5)

		c = Choice{1, 2, 3, 4, default = 3}
		unitTest:assertEquals(#c.values, 4)
		unitTest:assertEquals(c.default, 3)
	end,
	__tostring = function(unitTest)
		local c = Choice{min = 2, max = 3, step = 0.1}

		unitTest:assertEquals(tostring(c), [[default  number [2]
max      number [3]
min      number [2]
step     number [0.1]
]])
	end,
	sample = function(unitTest)
		Random{seed = 12345}
		local c = Choice{1, 2, 3}

		unitTest:assertEquals(c:sample(), 2)
		unitTest:assertEquals(c:sample(), 3)
		unitTest:assertEquals(c:sample(), 1)
		unitTest:assertEquals(c:sample(), 2)

		c = Choice{min = 2, max = 3, step = 0.1}
		unitTest:assertEquals(c:sample(), 2)
		unitTest:assertEquals(c:sample(), 2.6)
		unitTest:assertEquals(c:sample(), 2.2)

		c = Choice{min = 1, max = 3}
		unitTest:assertEquals(c:sample(), 2.1551348191386, 0.01)
		unitTest:assertEquals(c:sample(), 1.4584970893453, 0.01)
		unitTest:assertEquals(c:sample(), 1.3813645669887, 0.01)

		c = Choice{min = 1}
		unitTest:assertEquals(c:sample(), 8.9154393315407e+14, 100)
		unitTest:assertEquals(c:sample(), 2.2675725759938e+15, 100)
		unitTest:assertEquals(c:sample(), 1.6018419319141e+15, 100)

		c = Choice{max = 1}
		unitTest:assertEquals(c:sample(), -4.0177913715186e+15, 100)
		unitTest:assertEquals(c:sample(), -37689686765332, 1)
		unitTest:assertEquals(c:sample(), -2.9210200615381e+15, 100)
	end
}

