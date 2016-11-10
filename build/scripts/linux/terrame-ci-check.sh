#!/bin/bash -l
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
## It enables to run terrame code analysis of package on UNIX environments.
## **Remember to export some variables before**
# 
## TERRAME_PATH - Path to TerraME installation
## TERRAME_GIT_DIR - Path to TerraME git directory
#
## Usage
# ./terrame-ci-check.sh PACKAGE COMMIT
# 
# PACKAGE - Represents which package will be tested
# COMMIT - Pull Request Commit Hash used to notify GitHub

# GitHub Status Name
GITHUB_CONTEXT="Code analysis of package $1"
GITHUB_STATUS="pending"
GITHUB_DESCRIPTION="Running."
TARGET_URL="$BUILD_URL/consoleFull"
# GitHub Commit hash
COMMIT=$2
# Sending pending status
$TERRAME_GIT_DIR/build/scripts/linux/terrame-ci-notify.sh $COMMIT "$GITHUB_CONTEXT" "$GITHUB_STATUS" "$TARGET_URL" "$GITHUB_DESCRIPTION"

# Exporting terrame vars
. $TERRAME_GIT_DIR/build/scripts/linux/utils/environment.sh "$TERRAME_PATH"

TERRAME_COMMANDS=""
# Extra commands if package is terralib
if [ "$PACKAGE" != "base" ]; then
  TERRAME_COMMANDS="-package $1"
fi

# Execute TerraME doc generation
terrame -color $TERRAME_COMMANDS -check
# Retrieve TerraME exit code
RESULT=$?

# Formatting output errors
. $TERRAME_GIT_DIR/build/scripts/linux/utils/format-errors.sh $RESULT "Code analysis"

$TERRAME_GIT_DIR/build/scripts/linux/terrame-ci-notify.sh $COMMIT "$GITHUB_CONTEXT" "$GITHUB_STATUS" "$TARGET_URL" "$GITHUB_DESCRIPTION"

exit $RESULT