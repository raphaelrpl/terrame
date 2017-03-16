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
## This script defines how to compile TerraME and generate installer
## Remember that it runs after "build-terralib.sh" that compiles terralib and prepare terrame environment.
#

# Copy generated doc into Git package directory
cp -r $_TERRAME_INSTALL_PATH/bin/packages/base/doc $_TERRAME_GIT_DIR/packages/base
cp -r $_TERRAME_INSTALL_PATH/bin/packages/terralib/doc $_TERRAME_GIT_DIR/packages/terralib

# Remove TerraME build and install to compile again
rm -rf $_TERRAME_OUT_DIR $_TERRAME_INSTALL_PATH

# Compile TerraME
$_TERRAME_GIT_DIR/build/scripts/linux/ci/build-terrame.sh

cd $_TERRAME_OUT_DIR
# Once compiled, call cpack to generate TerraME installer
cpack -G TGZ -C Release --config ./CPackConfig.cmake
RESULT=$?

exit $RESULT
