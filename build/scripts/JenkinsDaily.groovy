/*
 TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
 Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

 This code is part of the TerraME framework.
 This framework is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 You should have received a copy of the GNU Lesser General Public
 License along with this library.

 The authors reassure the license terms regarding the warranties.
 They specifically disclaim any warranties, including, but not limited to,
 the implied warranties of merchantability and fitness for a particular purpose.
 The framework provided hereunder is on an "as is" basis, and the authors have no
 obligation to provide maintenance, support, updates, enhancements, or modifications.
 In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
 indirect, special, incidental, or consequential damages arising out of the use
 of this software and its documentation.
*/
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
      - 3rdparty (TODO: change it in order to follow TerraLib style, versioning dependencies)
        - build
        - install
      * solution
        * build
        * install
      * git
      * test (With test.lua. The file will be created during TerraLib compilation and should be kept during TerraME lifecycle)

  Where:
    "-" represents folders that should not remove
    "*" represents folder that must be removed every job execution
    "!" represents folder that need removed specific files
*/
class BashSpec {
  public String script;
  public boolean isFile = false;
  public BashSpec(String script, boolean isFile) {
    this.script = script;
    this.isFile = isFile;
  }
  public BashSpec(String script) {
    this(script, false);
  }
}

/*
  It defines a spec class for Job.
  TODO: Improve it and split into multiple files (TriggerSpec, ConditionSpec, etc.)
*/
class JobSpec {
  public String name;
  public BashSpec bashSpec;
  public String triggerCron;
  public String downstreamJob;
  public String conditionName;
  public boolean publishOverSSH;
  public boolean installer;

  public JobSpec(String jobName, boolean installer) {
    this.name = jobName;
    this.installer = installer;
    this.publishOverSSH = false;
  }

  public JobSpec(String jobName) {
    this(jobName, false);
  }
}

/*
  It defines common operations for JobDSL
*/
class JobCommons {
  public static int c = 0;
  /*
    It creates a new job from JobSpec.

    @param jobSpec - Job Definition
  */
  def build(def dsl, JobSpec jobSpec) {
    c += 1
    String prefix = "terrame-daily-";
    String environment = "-linux-ubuntu-14.04";
    String _ROOT_BUILD_DIR =           "/home/jenkins/MyDevel/terrame/daily";
    String _TERRALIB_BUILD_BASE =      "$_ROOT_BUILD_DIR/terralib"
    String _TERRALIB_3RDPARTY_DIR =    "$_TERRALIB_BUILD_BASE/3rdparty/5.2";
    String _TERRALIB_GIT_DIR =         "$_TERRALIB_BUILD_BASE/git";
    String _TERRALIB_OUT_DIR =         "$_TERRALIB_BUILD_BASE/solution/build";
    String _TERRALIB_INSTALL_PATH =    "$_TERRALIB_BUILD_BASE/solution/install";
    String _TERRALIB_MODULES_DIR =     "$_TERRALIB_INSTALL_PATH"
    String _TERRAME_BUILD_BASE =       "$_ROOT_BUILD_DIR/terrame";
    String _TERRAME_GIT_DIR =          "$_TERRAME_BUILD_BASE/git";
    String _TERRAME_TEST_DIR =         "$_TERRAME_BUILD_BASE/test"
    String _TERRAME_DEPENDS_DIR =      "$_TERRAME_BUILD_BASE/3rdparty/install";
    String _TERRAME_OUT_DIR =          "$_TERRAME_BUILD_BASE/solution/build";
    String _TERRAME_INSTALL_PATH =     "$_TERRAME_BUILD_BASE/solution/install";
    String _TERRAME_CREATE_INSTALLER = jobSpec.installer ? "ON" : "OFF";
    String _TERRAME_BUILD_AS_BUNDLE =  "OFF";
    String PATH =                      "/opt/cmake-3.5.2/bin:\$PATH"
    // Creating Job
    dsl.job(prefix + jobSpec.name + environment) {
      label("ubuntu-14.04-terrame")

      if (jobSpec.triggerCron != null) {
        // It is important, due the first job must have a build script in order to prepare environment
        scm {
          git {
            remote {
              github("raphaelrpl/terrame")
            }
            branch("master")
          }
        }
        triggers {
          cron(jobSpec.triggerCron) // Build everyday at 02:00 AM
        }
      } else {
        // Setting default jenkins Workspace
        customWorkspace(_TERRAME_OUT_DIR)
      }
      /*
        It defines Build Steps. First, inject required variables and then execute bash script to compile/execute/ etc.
      */
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

          if (c > 3 && c <= 11) {
            String TME_PATH = "$_TERRAME_INSTALL_PATH/bin";
            env("TME_PATH",        TME_PATH);
            env("LD_LIBRARY_PATH", TME_PATH);
            PATH += ":$TME_PATH";
          }
          env("PATH", PATH)
        }

        if (c == 1) {
          shell(jobSpec.bashSpec.script)
        } else {
          shell(_TERRAME_GIT_DIR + "/" + jobSpec.bashSpec.script)
        }

        // If it is job generates a installer, make it available in website, sending through SSH
        if (jobSpec.installer) {
          publishOverSsh {
            server('Jenkins Slave Linux (Public)') {
              transferSet {
                sourceFiles("$_TERRAME_OUT_DIR/terrame*.tar.gz")
                removePrefix("$_TERRAME_OUT_DIR")
                remoteDirectory("Public/terrame/installers")
              }
            }
          }
        }
      }
      /*
        If set, it will trigger a specific job with current build parameters based on Condition role (SUCCESS, ALWAYS (Always), etc).
      */
      if (jobSpec.downstreamJob != null) {
        wrappers {
          xvfb('Xvfb') {
            screen('1280x1080x24')
          }

          colorizeOutput()
        }

        publishers {
          downstreamParameterized {
            trigger(prefix + jobSpec.downstreamJob + environment) {
              condition(jobSpec.conditionName)
              parameters {
                predefinedProp("", "") // It is important to set empty values due the wrapper parameters requires a property even blank.
              }
            }
          } // end downstreamParameterized
        }   // end publishers
      }     // end if
    }       // end dsl.job
  }         // end JobCommons.build
}           // end class

JobSpec terralib = new JobSpec("terralilb-build");
terralib.downstreamJob = "cpp-syntax-check";
terralib.bashSpec = new BashSpec("build/scripts/linux/ci/build-terralib.sh", true);
terralib.triggerCron = "H 2 * * *";
terralib.conditionName = "SUCCESS";
new JobCommons().build(this, terralib);

JobSpec syntaxCpp = new JobSpec("cpp-syntax-check");
syntaxCpp.downstreamJob = "build";
syntaxCpp.bashSpec = new BashSpec("build/scripts/linux/ci/cpp-check.sh");
syntaxCpp.conditionName = "ALWAYS";
new JobCommons().build(this, syntaxCpp);

JobSpec terrame = new JobSpec("build");
terrame.downstreamJob = "code-analysis-base";
terrame.bashSpec = new BashSpec("build/scripts/linux/ci/build-terrame.sh");
terrame.conditionName = "SUCCESS";
new JobCommons().build(this, terrame);

JobSpec codeAnalysisBase = new JobSpec("code-analysis-base");
codeAnalysisBase.downstreamJob = "code-analysis-terralib";
codeAnalysisBase.bashSpec = new BashSpec("build/scripts/linux/ci/code-analysis.sh");
codeAnalysisBase.conditionName = "ALWAYS";
new JobCommons().build(this, codeAnalysisBase);

JobSpec codeAnalysisTerralib = new JobSpec("code-analysis-terralib");
codeAnalysisTerralib.downstreamJob = "doc-base";
codeAnalysisTerralib.bashSpec = new BashSpec("build/scripts/linux/ci/code-analysis.sh \"terralib\"");
codeAnalysisTerralib.conditionName = "ALWAYS";
new JobCommons().build(this, codeAnalysisTerralib);

JobSpec docBase = new JobSpec("doc-base");
docBase.downstreamJob = "doc-terralib";
docBase.bashSpec = new BashSpec("build/scripts/linux/ci/doc.sh");
docBase.conditionName = "ALWAYS";
new JobCommons().build(this, docBase);

JobSpec docTerralib = new JobSpec("doc-terralib");
docTerralib.downstreamJob = "unittest-base";
docTerralib.bashSpec = new BashSpec("build/scripts/linux/ci/doc.sh \"terralib\"");
docTerralib.conditionName = "ALWAYS";
new JobCommons().build(this, docTerralib);

JobSpec unittestBase = new JobSpec("unittest-base");
unittestBase.downstreamJob = "unittest-terralib";
unittestBase.bashSpec = new BashSpec("build/scripts/linux/ci/unittest.sh");
unittestBase.conditionName = "ALWAYS";
new JobCommons().build(this, unittestBase);

JobSpec unittestTerralib = new JobSpec("unittest-terralib");
unittestTerralib.downstreamJob = "test-execution";
unittestTerralib.bashSpec = new BashSpec("build/scripts/linux/ci/unittest.sh \"terralib\"");
unittestTerralib.conditionName = "ALWAYS";
new JobCommons().build(this, unittestTerralib);

JobSpec testExecution = new JobSpec("test-execution");
testExecution.downstreamJob = "repository-test";
testExecution.bashSpec = new BashSpec("build/scripts/linux/ci/test-execution.sh");
testExecution.conditionName = "ALWAYS";
new JobCommons().build(this, testExecution);

JobSpec repositoryTest = new JobSpec("repository-test");
repositoryTest.downstreamJob = "installer";
repositoryTest.bashSpec = new BashSpec("build/scripts/linux/ci/repository-test.sh");
repositoryTest.conditionName = "ALWAYS";
new JobCommons().build(this, repositoryTest);

JobSpec installer = new JobSpec("installer", true);
installer.bashSpec = new BashSpec("build/scripts/linux/ci/installer.sh");
installer.publishOverSSH = true;
new JobCommons().build(this, installer);
