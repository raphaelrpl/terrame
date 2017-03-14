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

String _ROOT_BUILD_DIR =        "/home/jenkins/MyDevel/terrame/ci/";
String _TERRALIB_BUILD_BASE =   "$_ROOT_BUILD_DIR/terralib"
String _TERRALIB_3RDPARTY_DIR = "$_TERRALIB_BUILD_BASE/3rdparty/5.2";
String _TERRALIB_GIT_DIR =      "$_TERRALIB_BUILD_BASE/git";
String _TERRALIB_OUT_DIR =      "$_TERRALIB_BUILD_BASE/solution/build";
String _TERRALIB_INSTALL_PATH = "$_TERRALIB_BUILD_BASE/solution/install";
String _TERRAME_BUILD_BASE =    "$_ROOT_BUILD_DIR/terrame/\${ghprbActualCommit}";
String _TERRAME_GIT_DIR =       "$_TERRAME_BUILD_BASE/git";
String _TERRAME_TEST_DIR =      "$_TERRAME_BUILD_BASE/test;"


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
    env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
    env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
    env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
    env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
    env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
    env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
    env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
    env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
    env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
}
    shell(readFileFromWorkspace("build/scripts/unix/build-terralib.sh"))
  }
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
        env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
        env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
        env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
        env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
        env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
        env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
        env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
        env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
        env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell(readFileFromWorkspace("build/scripts/unix/cpp-check.sh"))
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
      env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
      env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
      env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell(readFileFromWorkspace("build/scripts/unix/build-terrame.sh"))
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
      env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
      env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
      env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell(readFileFromWorkspace("build/scripts/unix/doc.sh"))
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
      env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
      env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
      env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell("build/scripts/unix/doc.sh terralib")
  }
}
job(prefix + "unittest-base") {
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
      env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
      env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
      env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell(readFileFromWorkspace("build/scripts/unix/unittest.sh"))
  }
}
job(prefix + "unittest-terralib") {
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
      env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
      env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
      env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell("build/scripts/unix/unittest.sh terralib")
  }
}

job(prefix + "test-execution") {
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
      env("_ROOT_BUILD_DIR",        _ROOT_BUILD_DIR)
      env("_TERRALIB_BUILD_BASE",   _TERRALIB_BUILD_BASE)
      env("_TERRALIB_3RDPARTY_DIR", _TERRALIB_3RDPARTY_DIR)
      env("_TERRALIB_GIT_DIR",      _TERRALIB_GIT_DIR)
      env("_TERRALIB_OUT_DIR",      _TERRALIB_OUT_DIR)
      env("_TERRALIB_INSTALL_PATH", _TERRALIB_INSTALL_PATH)
      env("_TERRAME_BUILD_BASE",    _TERRAME_BUILD_BASE)
      env("_TERRAME_GIT_DIR",       _TERRAME_GIT_DIR)
      env("_TERRAME_TEST_DIR",      _TERRAME_TEST_DIR)
    }
    shell(readFileFromWorkspace("build/scripts/unix/test-execution.sh"))
  }
}
