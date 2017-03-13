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
## This script defines how to prepare TerraME environment, compiling TerraLib and copying required files into respective directories.
## We must download respective PR from "ghprbActualCommit" in order to retrieve collaborator changes.
#
## Global Variables
# _ROOT_BUILD_DIR - Path to TerraME common folder structure. See more in https://github.com/terrame/terrame/wiki
# _TERRAME_BUILD_BASE - Base Path of TerraME structure. $_ROOT_BUILD_DIR/terrame
# ghprbActualCommit - Current GitHub Pull Request (Injected by Jenkins GitHub Pull Request Plugin. See more in https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin)
#

# Removing Old git repositories
rm -rf $_TERRAME_GIT_DIR $_TERRALIB_GIT_DIR
# Removing TerraLib install path and TerraLib build binding lua in order to re-generate
rm -rf $_TERRALIB_OUT_DIR/terralib_mod_binding_lua $_TERRALIB_INSTALL_PATH

# Cloning a new TerraLib Git Files. Branch: release-5.2
git clone -b release-5.2 https://gitlab.dpi.inpe.br/rodrigo.avancini/terralib.git $_TERRALIB_GIT_DIR

# Creating Target TerraME build dir
mkdir -p $_TERRAME_GIT_DIR $_TERRAME_TEST_DIR

cd $_TERRAME_GIT_DIR

if [ "$1" == "daily" ]; then
  git clone https://github.com/TerraME/terrame.git .
else
  # Clone terrame and set PR refspec
  git init
  git config remote.origin.url https://github.com/TerraME/terrame.git
  git fetch --tags --progress https://github.com/TerraME/terrame.git +refs/pull/*:refs/remotes/origin/pr/* --quiet
  git rev-parse $ghprbActualCommit
  git config core.sparsecheckout
  git checkout -f $ghprbActualCommit
  git rev-list $ghprbActualCommit --quiet
fi

mkdir -p $_TERRALIB_BUILD_BASE/solution $_TERRAME_BUILD_BASE/solution
cd $_TERRALIB_BUILD_BASE/solution
# Copying TerraME TerraLib build scripts into current workspace
cp $_TERRAME_GIT_DIR/build/scripts/linux/terralib-conf.* .
# Copying TerraME config.lua file used during tests
cp /home/jenkins/Configs/terrame/tests/files/config.lua $_TERRAME_TEST_DIR

./terralib-conf.sh

# Returning execution code in order to help jenkins to identify stable/unstable builds
exit $?
