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

return {
	Layer = function(unitTest)
		local projName = "layer_postgis_basic.tview" -- TODO: (#1442)

		if File(projName):exists() then
			File(projName):delete()
		end

		local proj1 = Project{
			file = projName,
			clean = true
		}

		local layerName1 = "Sampa"

		local layer1 = Layer{
			project = proj1,
			name = layerName1,
			file = filePath("test/sampa.shp", "terralib")
		}

		unitTest:assertEquals(layer1.name, layerName1)

		local host
		local port
		local user = "postgres"
		local password = getConfig().password
		local database = "postgis_22_sample"
		local encoding
		local tableName = "sampa"

		local pgData = {
			source = "postgis",
			--host = host,
			--port = port,
			user = user,
			password = password,
			database = database,
			overwrite = true
		}

		layer1:export(pgData, true)

		local layerName2 = "SampaDB"

		local layer2 = Layer{
			project = proj1,
			source = "postgis",
			name = layerName2,
			-- host = host,
			-- port = port,
			user = user,
			password = password,
			database = database,
			table = tableName
		}

		unitTest:assertEquals(layer2.name, layerName2)

		local layerName3 = "Another_SampaDB"

		local layer3 = Layer{
			project = proj1,
			source = "postgis",
			name = layerName3,
			-- host = host,
			-- port = port,
			user = user,
			password = password,
			database = database,
			table = tableName
		}

		unitTest:assert(layer3.name ~= layer2.name)
		unitTest:assertEquals(layer3.sid, layer2.sid)

		TerraLib{}:dropPgTable(pgData)

		-- TODO: ADO DON'T WORK (REVIEW)
		-- if _Gtme.sessionInfo().system == "windows" then
			-- local adoData = {
				-- type = "ADO",
				-- file = "D:/terrame/tests/sampa.accdb" --file("sampa.accdb", "fillcell")
			-- }

			-- TerraLib{}:copyLayer(proj1, layerName1, adoData)
		-- end

		-- local layerName4 = "SampaAdoDB"
		-- local adofilePath =
		-- proj1:addLayer{
			-- source = "access",
			-- name = layerName4,
			-- user = user,
			-- password = password,
			-- database = database,
			-- table = tableName
		-- }

		File(projName):deleteIfExists()

		projName = "cells_setores_2000.tview"

		local proj = Project{
			file = projName,
			clean = true
		}

		layerName1 = "Sampa"
		Layer{
			project = proj,
			name = layerName1,
			file = filePath("test/sampa.shp", "terralib")
		}

		local clName1 = "Sampa_Cells"
		local tName1 = "add_cellslayer_basic"

		host = "localhost"
		port = "5432"
		user = "postgres"
		password = "postgres"
		database = "postgis_22_sample"
		encoding = "CP1252"

		pgData = {
			type = "POSTGIS",
			host = host,
			port = port,
			user = user,
			password = password,
			database = database,
			table = tName1,
			encoding = encoding
		}

		TerraLib{}:dropPgTable(pgData)

		local l1 = Layer{
			project = proj,
			source = "postgis",
			input = layerName1,
			name = clName1,
			resolution = 0.7,
			user = user,
			password = password,
			database = database,
			table = tName1
		}

		unitTest:assertEquals(l1.name, clName1)

		local clName2 = "Another_Sampa_Cells"
		local tName2 = "add_cellslayer_basic_another"

		pgData.table = tName2
		TerraLib{}:dropPgTable(pgData)

		local l2 = Layer{
			project = proj,
			source = "postgis",
			input = layerName1,
			name = clName2,
			resolution = 0.7,
			user = user,
			password = password,
			database = database,
			table = tName2
		}

		unitTest:assertEquals(l2.name, clName2)

		local clName3 = "Other_Sampa_Cells"
		local tName3 = "add_cellslayer_basic_from_db"

		pgData.table = tName3
		TerraLib{}:dropPgTable(pgData)

		local l3 = Layer{
			project = proj,
			source = "postgis",
			input = clName2,
			name = clName3,
			resolution = 0.7,
			user = user,
			password = password,
			database = database,
			table = tName3
		}

		unitTest:assertEquals(l3.name, clName3)

		local newDbName = "new_pg_db_30032017"
		pgData.database = newDbName
		TerraLib{}:dropPgDatabase(pgData)
		pgData.database = database

		local clName4 = "New_Sampa_Cells"

		local layer4 = Layer{
			project = proj,
			source = "postgis",
			input = clName2,
			name = clName4,
			resolution = 0.7,
			user = user,
			password = password,
			database = newDbName
		}

		unitTest:assertEquals(layer4.source, "postgis")
		unitTest:assertEquals(layer4.host, host)
		unitTest:assertEquals(layer4.port, port)
		unitTest:assertEquals(layer4.user, user)
		unitTest:assertEquals(layer4.password, password)
		unitTest:assertEquals(layer4.database, newDbName)
		unitTest:assertEquals(layer4.table, string.lower(clName4))

		-- BOX TEST
		local clSet = TerraLib{}:getDataSet(proj, clName1)
		unitTest:assertEquals(getn(clSet), 68)

		clName1 = clName1.."_Box"
		local tName4 = string.lower(clName1)
		pgData.table = tName4
		TerraLib{}:dropPgTable(pgData)

		Layer{
			project = proj,
			source = "postgis",
			input = layerName1,
			name = clName1,
			resolution = 0.7,
			box = true,
			user = user,
			password = password,
			database = database
		}

		clSet = TerraLib{}:getDataSet(proj, clName1)
		unitTest:assertEquals(getn(clSet), 104)

		-- CHANGE SRID
		local layerName5 = "SampaDBNewSrid"

		local layer5 = Layer{
			project = proj,
			source = "postgis",
			name = layerName5,
			-- host = host,
			-- port = port,
			user = user,
			password = password,
			database = database,
			table = tName1,
			srid = 29901
		}

		unitTest:assertEquals(layer5.srid, 29901.0)
		unitTest:assert(layer5.srid ~= layer4.srid)
		-- // CHANGE SRID

		File(projName):deleteIfExists()

		pgData.table = tName1
		TerraLib{}:dropPgTable(pgData)
		pgData.table = tName2
		TerraLib{}:dropPgTable(pgData)
		pgData.table = tName3
		TerraLib{}:dropPgTable(pgData)
		pgData.table = tName4
		TerraLib{}:dropPgTable(pgData)
		pgData.database = newDbName
		TerraLib{}:dropPgDatabase(pgData)
	end,
	projection = function(unitTest)
		local projName = "layer_basic.tview"

		local proj = Project{
			file = projName,
			clean = true
		}

		local layerName1 = "Setores"

		local layer1 = Layer{
			project = proj,
			name = layerName1,
			file = filePath("Setores_Censitarios_2000_pol.shp", "terralib")
		}

		unitTest:assertEquals(layer1.name, layerName1)

		local host = "localhost"
		local port = "5432"
		local user = "postgres"
		local password = "postgres"
		local database = "postgis_22_sample"
		local encoding = "CP1252"
		local tableName = "setores_cells"

		local pgData = {
			type = "POSTGIS",
			host = host,
			port = port,
			user = user,
			password = password,
			database = database,
			table = tableName,
			encoding = encoding

		}

		local tl = TerraLib{}
		tl:dropPgTable(pgData)

		local clName1 = "Setores_Cells"
		local layer = Layer{
			project = proj,
			source = "postgis",
			input = layerName1,
			name = clName1,
			resolution = 5e3,
			user = user,
			password = password,
			database = database
		}

		unitTest:assertEquals(layer:projection(), "'SAD69 / UTM zone 21S', with SRID: 29191.0 (PROJ4: '+proj=utm +zone=21 +south +ellps=aust_SA +towgs84=-66.87,4.37,-38.52,0,0,0,0 +units=m +no_defs ').")

		proj.file:delete()
		tl:dropPgTable(pgData)
	end,
	attributes = function(unitTest)
		local projName = "layer_basic.tview"

		local proj = Project{
			file = projName,
			clean = true
		}

		local layerName1 = "Setores"

		local layer1 = Layer{
			project = proj,
			name = layerName1,
			file = filePath("Setores_Censitarios_2000_pol.shp", "terralib")
		}

		unitTest:assertEquals(layer1.name, layerName1)

		local host = "localhost"
		local port = "5432"
		local user = "postgres"
		local password = "postgres"
		local database = "postgis_22_sample"
		local encoding = "CP1252"
		local tableName = "setores_cells"

		local pgData = {
			type = "POSTGIS",
			host = host,
			port = port,
			user = user,
			password = password,
			database = database,
			table = tableName,
			encoding = encoding
		}

		local tl = TerraLib{}
		tl:dropPgTable(pgData)

		local clName1 = "Setores_Cells"
		local layer = Layer{
			project = proj,
			input = layerName1,
			name = clName1,
			resolution = 5e3,
			user = user,
			password = password,
			database = database
		}

		local propNames = layer:attributes()

		for i = 1, #propNames do
			unitTest:assert((propNames[i] == "id") or (propNames[i] == "geom") or
						(propNames[i] == "col") or (propNames[i] == "row"))
		end

		proj.file:delete()
		tl:dropPgTable(pgData)
	end,
	export = function(unitTest)
		local projName = "layer_postgis_basic.tview"

		if File(projName):exists() then -- TODO: (#1442)
			File(projName):delete()
		end

		local proj = Project {
			file = projName,
			clean = true
		}

		local filePath1 = filePath("Setores_Censitarios_2000_pol.shp", "terralib")

		local layerName1 = "setores"
		local layer1 = Layer{
			project = proj,
			name = layerName1,
			file = filePath1
		}

		local overwrite = true

		local user = "postgres"
		local password = getConfig().password
		local database = "postgis_22_sample"
		local tableName = string.lower("Setores_Censitarios_2000_pol")

		local pgData = {
			source = "postgis",
			user = user,
			password = password,
			database = database,
			overwrite = overwrite
		}

		layer1:export(pgData)

		local layerName2 = "setorespg"
		local layer2 = Layer{
			project = proj,
			source = "postgis",
			name = layerName2,
			user = user,
			password = password,
			database = database,
			table = tableName
		}

		local geojson = "setores.geojson"
		local data1 = {
			file = geojson,
			overwrite = overwrite
		}

		layer2:export(data1)
		unitTest:assert(File(geojson):exists())

		-- OVERWRITE AND CHANGE SRID
		data1.srid = 4326
		layer2:export(data1)

		local layerName3 = "GJ"
		local layer3 = Layer{
			project = proj,
			name = layerName3,
			file = geojson
		}

		unitTest:assertEquals(layer3.srid, data1.srid)
		unitTest:assert(layer2.srid ~= data1.srid)

		local shp = "setores.shp"
		local data2 = {
			file = shp,
			overwrite = overwrite
		}

		layer2:export(data2)
		unitTest:assert(File(shp):exists())

		-- OVERWRITE AND CHANGE SRID
		data2.srid = 4326
		layer2:export(data2)

		local layerName4 = "SHP"
		local layer4 = Layer{
			project = proj,
			name = layerName4,
			file = shp
		}

		unitTest:assertEquals(layer4.srid, data2.srid)
		unitTest:assert(layer2.srid ~= data2.srid)

		File(geojson):delete()
		File(shp):delete()
		proj.file:delete()

		pgData.table = tableName
		TerraLib{}:dropPgTable(pgData)
	end
}

