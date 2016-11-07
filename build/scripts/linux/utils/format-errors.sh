#!/bin/bash
# TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
# Copyright (C) 2001-2016 INPE and TerraLAB/UFOP -- www.terrame.org
#
# This code is part of the TerraME framework.
# This framework is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.
#
# The authors reassure the license terms regarding the warranties.
# They specifically disclaim any warranties, including, but not limited to,
# the implied warranties of merchantability and fitness for a particular purpose.
# The framework provided hereunder is on an "as is" basis, and the authors have no
# obligation to provide maintenance, support, updates, enhancements, or modifications.
# In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
# indirect, special, incidental, or consequential damages arising out of the use
# of this software and its documentation.

#
## It formats GitHub status message based on Exit code given. After executes, it exports two variables
#
## GITHUB_STATUS containing Build status (success,failure)
## GITHUB_DESCRIPTION containing Status description
#
## Usage:
## ./utils/format-errors.sh EXIT_CODE CONTEXT
#
# EXIT_CODE Int value to compares and make status
# CONTEXT Optional values to describe description intent
#

RESULT=$1
CONTEXT=$2

if [ $RESULT -eq 0 ]; then
  GITHUB_STATUS="success"
  GITHUB_DESCRIPTION="$CONTEXT executed successfully"
elif [ $RESULT -eq 255 ]; then
  GITHUB_STATUS="failure"
  GITHUB_DESCRIPTION="$RESULT or more errors found"
else
  GITHUB_STATUS="failure"
  GITHUB_DESCRIPTION="$RESULT errors found"
fi

export GITHUB_STATUS=$GITHUB_STATUS
export GITHUB_DESCRIPTION=$GITHUB_DESCRIPTION