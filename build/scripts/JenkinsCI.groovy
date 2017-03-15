/*
  Structure (See https://github.com/terrame/terrame/wiki for further details):
  - Folder (/path/to/[ci|daily])
    - terralib
      * 3rdparty
        - Versions (5.1, 5.2, etc)
      - solution
        ! build (terralib_mod_binding_lua)
        * install
      * git
    - terrame
      + GitHubCommitHash
        * git
        * solution
          * build
          * install
        * git
        * test (With test.lua. The file will be created during TerraLib compilation and should be kept during TerraME lifecycle)
      - 3rdparty (TODO: change it in order to follow TerraLib style)
        - build
        - install

  Where:
    "-" represents folders that should not remove
    "*" represents folder that must be removed every job execution
    "!" represents folder that need removed specific files
    "+" represents grouped folder based on GitHub Commmit Hash. As GitHub Pull Requests
        are made from N forks from N branches, it is necessary to group TerraME
        compilation|installation using hash in to avoid artifacts overwriting.

*/

String prefix = "terrame-testing-ci-";
String environment = "-linux-ubuntu-14.04";

String _ROOT_BUILD_DIR =           "/home/jenkins/MyDevel/terrame/ci";
String _TERRALIB_BUILD_BASE =      "$_ROOT_BUILD_DIR/terralib"
String _TERRALIB_3RDPARTY_DIR =    "$_TERRALIB_BUILD_BASE/3rdparty/5.2";
String _TERRALIB_GIT_DIR =         "$_TERRALIB_BUILD_BASE/git";
String _TERRALIB_OUT_DIR =         "$_TERRALIB_BUILD_BASE/solution/build";
String _TERRALIB_INSTALL_PATH =    "$_TERRALIB_BUILD_BASE/solution/install";
String _TERRALIB_MODULES_DIR =     "$_TERRALIB_INSTALL_PATH"
String _TERRAME_BUILD_BASE =       "$_ROOT_BUILD_DIR/terrame/\${ghprbActualCommit}";
String _TERRAME_GIT_DIR =          "$_TERRAME_BUILD_BASE/git";
String _TERRAME_TEST_DIR =         "$_TERRAME_BUILD_BASE/test"
String _TERRAME_DEPENDS_DIR =      "$_TERRAME_BUILD_BASE/3rdparty/install";
String _TERRAME_OUT_DIR =          "$_TERRAME_BUILD_BASE/solution/build";
String _TERRAME_INSTALL_PATH =     "$_TERRAME_BUILD_BASE/solution/install";
String _TERRAME_CREATE_INSTALLER = "OFF";
String _TERRAME_BUILD_AS_BUNDLE =  "OFF";
String PATH =                      "/opt/cmake-3.5.2/bin:\$PATH"


job(prefix + "terralib-build" + environment) {
  scm {
      git {
          remote {
              github("raphaelrpl/terrame")
              refspec("+refs/pull/*:refs/remotes/origin/pr/*")
          }
          branch("\${ghprbActualCommit}")
      }
  }

  triggers {
      githubPullRequest {
          cron("H/5 * * * *")
          triggerPhrase("jenkins build")
          extensions {
              commitStatus {
                  context("Linux TerraLib Compilation")
                  triggeredStatus("Triggered...")
                  startedStatus("Building...")
                  addTestResults(true)
                  statusUrl("$BUILD_URL/consoleFull")
                  completedStatus("SUCCESS", "All is well")
                  completedStatus("FAILURE", "Something went wrong. Investigate!")
                  completedStatus("PENDING", "still in progress...")
                  completedStatus("ERROR", "Something went really wrong. Investigate!")
              }
          }
      }
  }

  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell(readFileFromWorkspace("build/scripts/linux/ci/build-terralib.sh"))
  }

  wrappers {
    xvfb('Xvfb') {
      screen('1280x1080x24')
    }

    colorizeOutput()
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "cpp-syntax-check" + environment) {
        condition("SUCCESS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }   // end publishers
}

job(prefix + "cpp-syntax-check" + environment) {
  wrappers {
      downstreamCommitStatus {
          context("C++ Syntax")
          triggeredStatus("The job has triggered")
          startedStatus("The job has started")
          statusUrl("$BUILD_URL/consoleFull")
          completedStatus("SUCCESS", "The job has passed")
          completedStatus("FAILURE", "The job has failed")
          completedStatus("ERROR", "The job has resulted in an error")
      }
  }

  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell(readFileFromWorkspace("build/scripts/linux/ci/cpp-check.sh"))
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "build" + environment) {
        condition("ALWAYS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }
}

job(prefix + "build" + environment) {
  wrappers {
    downstreamCommitStatus {
      context("Linux Compilation")
      triggeredStatus("The job has triggered")
      startedStatus("The job has started")
      statusUrl("$BUILD_URL/consoleFull")
      completedStatus("SUCCESS", "The job has passed")
      completedStatus("FAILURE", "The job has failed")
      completedStatus("ERROR", "The job has resulted in an error")
    }
  }
  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell(readFileFromWorkspace("build/scripts/linux/ci/build-terrame.sh"))
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "doc-base" + environment) {
        condition("ALWAYS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }
}

job(prefix + "doc-base" + environment) {
  wrappers {
    downstreamCommitStatus {
      context("Documentation of package base")
      triggeredStatus("The job has triggered")
      startedStatus("The job has started")
      statusUrl("$BUILD_URL/consoleFull")
      completedStatus("SUCCESS", "The job has passed")
      completedStatus("FAILURE", "The job has failed")
      completedStatus("ERROR", "The job has resulted in an error")
    }
  }
  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell(readFileFromWorkspace("build/scripts/linux/ci/doc.sh"))
  }

  wrappers {
    xvfb('Xvfb') {
      screen('1280x1080x24')
    }

    colorizeOutput()
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "doc-terralib" + environment) {
        condition("ALWAYS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }
}

job(prefix + "doc-terralib" + environment) {
  wrappers {
    downstreamCommitStatus {
      context("Documentation of package terralib")
      triggeredStatus("The job has triggered")
      startedStatus("The job has started")
      statusUrl("$BUILD_URL/consoleFull")
      completedStatus("SUCCESS", "The job has passed")
      completedStatus("FAILURE", "The job has failed")
      completedStatus("ERROR", "The job has resulted in an error")
    }
  }
  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell("build/scripts/linux/ci/doc.sh terralib")
  }

  wrappers {
    xvfb('Xvfb') {
      screen('1280x1080x24')
    }

    colorizeOutput()
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "unittest-base" + environment) {
        condition("ALWAYS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }
}
job(prefix + "unittest-base" + environment) {
  wrappers {
      downstreamCommitStatus {
        context("Functional test of package base")
        triggeredStatus("The job has triggered")
        startedStatus("The job has started")
        statusUrl("$BUILD_URL/consoleFull")
        completedStatus("SUCCESS", "The job has passed")
        completedStatus("FAILURE", "The job has failed")
        completedStatus("ERROR", "The job has resulted in an error")
      }
  }

  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell(readFileFromWorkspace("build/scripts/linux/ci/unittest.sh"))
  }

  wrappers {
    xvfb('Xvfb') {
      screen('1280x1080x24')
    }

    colorizeOutput()
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "unittest-terralib" + environment) {
        condition("ALWAYS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }
}
job(prefix + "unittest-terralib" + environment) {
  wrappers {
    downstreamCommitStatus {
      context("Functional test of package terralib")
      triggeredStatus("The job has triggered")
      startedStatus("The job has started")
      statusUrl("$BUILD_URL/consoleFull")
      completedStatus("SUCCESS", "The job has passed")
      completedStatus("FAILURE", "The job has failed")
      completedStatus("ERROR", "The job has resulted in an error")
    }
  }
  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell("build/scripts/linux/ci/unittest.sh terralib")
  }

  wrappers {
    xvfb('Xvfb') {
      screen('1280x1080x24')
    }

    colorizeOutput()
  }

  publishers {
    downstreamParameterized {
      trigger(prefix + "test-execution" + environment) {
        condition("ALWAYS")
        parameters {
          predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
        }
      }
    } // end downstreamParameterized
  }
}

job(prefix + "test-execution" + environment) {
  wrappers {
    downstreamCommitStatus {
      context("Execution Test")
      triggeredStatus("The job has triggered")
      startedStatus("The job has started")
      statusUrl("$BUILD_URL/consoleFull")
      completedStatus("SUCCESS", "The job has passed")
      completedStatus("FAILURE", "The job has failed")
      completedStatus("ERROR", "The job has resulted in an error")
    }
  }

  steps {
    environmentVariables {
      env("_ROOT_BUILD_DIR",           _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",      _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR",    _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",         _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",         _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH",    _TERRALIB_INSTALL_PATH)
      env("_TERRALIB_MODULES_DIR",     _TERRALIB_MODULES_DIR)
      env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
      env("_TERRAME_INSTALL_PATH",     _TERRAME_INSTALL_PATH)
      env("_TERRAME_OUT_DIR",          _TERRAME_OUT_DIR)
      env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
      env("_TERRAME_DEPENDS_DIR",      _TERRAME_DEPENDS_DIR)
      env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
      env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
      env("PATH",                      PATH)
    }
    shell(readFileFromWorkspace("build/scripts/linux/ci/test-execution.sh"))
  }
}
