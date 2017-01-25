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

local printError = _Gtme.printError
local printNote  = _Gtme.printNote

function _Gtme.executeProject(package)
	local initialTime = os.clock()

	printNote("Creating projects for package '"..package.."'")

	local package_path = _Gtme.packageInfo(package).path
	local data_path = Directory(package_path.."data")

	data_path:setCurrentDir()

	local project_report = {
		projects = 0,
		errors_processing = 0,
		errors_output = 0,
		errors_invalid = 0
	}

	printNote("Removing output files")
	forEachFile(data_path, function(file)
		if file:extension() == "lua" then
			local _, name = file:split()
			local output = File(name..".tview")

			if output:exists() then
				print("Removing 'data/"..output:name().."'")
				output:delete()
			end
		end
	end)

	printNote("Checking if data does not contain any .tview file")
	forEachFile(data_path, function(file)
		if file:extension() == "tview" then
			printError("File 'data/"..file:name().."' should not exist as there is no Lua script with this name.")
			project_report.errors_invalid = project_report.errors_invalid + 1
		end
	end)

	local oldProject = Project
	local oldLayer = Layer


	local createdLayers = {}

	Layer = function(data)
		if data.resolution then -- a cellular layer
			local mfile = data.file

			if type(mfile) == "string" then
				mfile = File(mfile)
			end

			mfile = mfile:name()
			print("Creating 'data/"..mfile.."'")

			if createdLayers[mfile] then
				printError("File 'data/"..mfile.."' was created previously. Please update its name.")
				project_report.errors_output = project_report.errors_output + 1
			else
				createdLayers[mfile] = true
			end
		end

		return oldLayer(data)
	end

	forEachFile(data_path, function(file)
		if file:extension() ~= "lua" then return end

		local hasProject = false

		Project = function(data)
			local mfile = data.file

			if type(mfile) == "string" then
				mfile = File(mfile)
			end

			mfile = mfile:name()

			if isFile(mfile) then return oldProject(data) end

			print("Creating 'data/"..mfile.."'")

			if hasProject then
				printError("File 'data/"..mfile.."' should create only one Project.")
				project_report.errors_output = project_report.errors_output + 1
			end

			hasProject = true

			local _, projName = File(mfile):split()
			local _, luaName = file:split()

			if projName ~= luaName then
				printError("File 'data/"..mfile.."' should be called 'data/"..luaName..".tview'. Please update its name.")
				project_report.errors_output = project_report.errors_output + 1
			end

			return oldProject(data)
		end

		printNote("Processing 'data/"..file:name().."'")
		project_report.projects = project_report.projects + 1

		local _, filename = file:split()
		local output = filename..".tview"

		local ok = true

		xpcall(function() dofile(tostring(file)) end, function(err)
			ok = false
			printError("Could not execute the script properly: "..err)
			project_report.errors_processing = project_report.errors_processing + 1
		end)

		if File(output):exists() then
			if ok then
				print("File '"..output.."' was successfully created")
			else
				print("Removing file 'data/"..output.."'")
				File(output):delete()
			end
		else
			printError("File '"..output.."' was not created.")
			project_report.errors_output = project_report.errors_output + 1
		end
	end)

	local finalTime = os.clock()

	print("\nProjects report for package '"..package.."':")
	printNote("Projects were created in "..round(finalTime - initialTime, 2).." seconds.")

	if project_report.projects == 0 then
		printNote("No project file was created.")
	elseif project_report.projects == 1 then
		printNote("One project file was created.")
	else
		printNote(project_report.projects.." project files were created.")
	end

	local errors = project_report.errors_processing + project_report.errors_output + project_report.errors_invalid

	if project_report.errors_invalid == 0 then
		printNote("No invalid .tview file was found in the package.")
	elseif project_report.errors_invalid == 1 then
		printError("One invalid .tview file was found in the package.")
	else
		printError(project_report.errors_invalid.." invalid .tview file were found in the package.")
	end

	if project_report.errors_processing == 0 then
		printNote("No error was found while creating projects.")
	elseif project_report.errors_processing == 1 then
		printError("One error was found while creating projects.")
	else
		printError(project_report.errors_processing.." errors were found while creating projects.")
	end

	if project_report.errors_output == 0 then
		printNote("No problem was found in the output of lua files.")
	elseif project_report.errors_output == 1 then
		printNote("One problem was found in the output of lua files.")
	else
		printError(project_report.errors_output.." problems were found in the output of lua files.")
	end

	if errors == 0 then
		printNote("Summing up, all projects were successfully created.")
	elseif errors == 1 then
		printError("Summing up, one problem was found while creating projects.")
	else
		printError("Summing up, "..errors.." problems were found while creating projects.")
	end

	return errors
end

