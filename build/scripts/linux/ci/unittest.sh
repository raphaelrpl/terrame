#!/bin/bash
# TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
# Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org
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
###########################################################################################
#
## This script defines how to run TerraME packages doc generator
##
## Usage:
## ./build/scripts/ci/unittest.sh PACKAGE_NAME
## Note: For base package, do not pass PACKAGE_NAME
#

export TME_PATH=$_TERRAME_INSTALL_PATH/bin
export PATH=$PATH:$TME_PATH
export LD_LIBRARY_PATH=$TME_PATH

terrame -version

TERRAME_COMMANDS=""
if [ $1 != "" -o $1 != "base" ]; then
  TERRAME_COMMANDS="-package $1"
fi

cd $_TERRAME_TEST_DIR

# Checking File test.lua exists. If not, set default. It is useful when you want customize flags. You just need to update this file
if [ ! -e test.lua ]; then
  echo "test.lua not in $(pwd). Creating default..."
  echo "
  lines = true
  time = true
  examples = true
  " > test.lua
fi

# Execute TerraME doc generation
terrame -color $TERRAME_COMMANDS -test  test.lua 2> /dev/null
# Retrieve TerraME exit code
RESULT=$?

# clean up
rm -rf .terrame*
exit $RESULT
