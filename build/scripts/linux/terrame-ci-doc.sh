#!/bin/bash -l

# 
## It enables to run terrame doc generation on UNIX environments.
## **Remember to export some variables before**
# 
## TERRAME_PATH - Path to TerraME installation
## TERRAME_GIT_DIR - Path to TerraME git directory
#
## Usage
# ./terrame-ci-doc.sh PACKAGE COMMIT
# 
# PACKAGE - Represents which package will be tested
# COMMIT - Pull Request Commit Hash used to notify GitHub

# GitHub Status Name
GITHUB_CONTEXT="Documentation of package $1"
GITHUB_STATUS="pending"
GITHUB_DESCRIPTION="Running."
TARGET_URL="$BUILD_URL/consoleFull"
# GitHub Commit hash
COMMIT=$2
# Sending pending status
$TERRAME_GIT_DIR/build/scripts/linux/terrame-ci-notify.sh $COMMIT "$GITHUB_CONTEXT" "$GITHUB_STATUS" "$TARGET_URL" "$GITHUB_DESCRIPTION"

# Exporting terrame vars
export TME_PATH="$TERRAME_PATH/bin"
export PATH=$PATH:$TME_PATH
export LD_LIBRARY_PATH=$TME_PATH

terrame -version

# Extra commands if package is terralib
TERRAME_COMMANDS=""
if [ "$1" != "base" ]; then
  TERRAME_COMMANDS="-package $1"
fi
# Execute TerraME doc generation
terrame -color $TERRAME_COMMANDS -doc 2> /dev/null
# Retrieve TerraME exit code
RESULT=$?

if [ $RESULT -eq 0 ]; then
  GITHUB_STATUS="success"
  GITHUB_DESCRIPTION="Tests executed successfully"
elif [ $RESULT -eq 255 ]; then
  GITHUB_STATUS="failure"
  GITHUB_DESCRIPTION="$RESULT or more errors found"
else
  GITHUB_STATUS="failure"
  GITHUB_DESCRIPTION="$RESULT tests failed"
fi

$TERRAME_GIT_DIR/build/scripts/linux/terrame-ci-notify.sh $COMMIT "$GITHUB_CONTEXT" "$GITHUB_STATUS" "$TARGET_URL" "$GITHUB_DESCRIPTION"

exit $RESULT