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

/*
  It defines a spec class for Job.
  TODO: Improve it and split into multiple files (TriggerSpec, ConditionSpec, etc.)
*/
class JobSpec {
  public String name;
  public String bashScript;
  public String triggerCron;
  public String downstreamJob;
  public String conditionName;
  public boolean publishOverSSH;

  public JobSpec(String jobName) {
    this.name = jobName;
    this.publishOverSSH = false;
  }
}

/*
  It defines common operations for JobDSL
*/
class JobCommons {
  /*
    It creates a new job from JobSpec.

    @param jobSpec - Job Definition
  */
  def build(def dsl, JobSpec jobSpec) {
    String prefix = "terrame-daily-";
    String environment = "-linux-ubuntu-14.04";
    String _ROOT_BUILD_DIR =           "/home/jenkins/MyDevel/terrame/daily/";
    String _TERRALIB_BUILD_BASE =      "$_ROOT_BUILD_DIR/terralib"
    String _TERRALIB_3RDPARTY_DIR =    "$_TERRALIB_BUILD_BASE/3rdparty/5.2";
    String _TERRALIB_GIT_DIR =         "$_TERRALIB_BUILD_BASE/git";
    String _TERRALIB_OUT_DIR =         "$_TERRALIB_BUILD_BASE/solution/build";
    String _TERRALIB_INSTALL_PATH =    "$_TERRALIB_BUILD_BASE/soluti'on/install";
    String _TERRAME_BUILD_BASE =       "$_ROOT_BUILD_DIR/terrame/";
    String _TERRAME_GIT_DIR =          "$_TERRAME_BUILD_BASE/git";
    String _TERRAME_TEST_DIR =         "$_TERRAME_BUILD_BASE/test;"
    String _TERRAME_CREATE_INSTALLER = "OFF";
    String _TERRAME_BUILD_AS_BUNDLE =  "OFF";

    dsl.job(prefix + jobSpec.name + environment) {
      if (jobSpec.triggerCron != null) {
        triggers {
          cron(jobSpec.triggerCron) // Build everyday at 02:00 AM
        }
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
          env("_TERRAME_BUILD_BASE",       _TERRAME_BUILD_BASE)
          env("_TERRAME_GIT_DIR",          _TERRAME_GIT_DIR)
          env("_TERRAME_TEST_DIR",         _TERRAME_TEST_DIR)
          env("_TERRAME_CREATE_INSTALLER", _TERRAME_CREATE_INSTALLER)
          env("_TERRAME_BUILD_AS_BUNDLE",  _TERRAME_BUILD_AS_BUNDLE)
        }

        shell(jobSpec.bashScript)
      }
      /*
        If set, it will trigger a specific job with current build parameters based on Condition role (SUCCESS, ALWAYS (Always), etc).
      */
      if (jobSpec.downstreamJob != null) {
        publishers {
          downstreamParameterized {
            trigger(jobSpec.downstreamJob) {
              condition(jobSpec.conditionName)
              parameters {
                currentBuild()
              }
            }
          }
        }
      }
    }
  }
}

JobSpec terralib = new JobSpec("terrame-terralilb-build");
terralib.downstreamJob = "terrame-cpp-syntax-check";
terralib.bashScript = "build/scripts/linux/ci/build-terralib.sh \"daily\"";
terralib.triggerCron = "H 2 * * *";
terralib.conditionName = "SUCCESS";
new JobCommons().build(this, terralib);

JobSpec syntaxCpp = new JobSpec("terrame-cpp-syntax-check");
syntaxCpp.downstreamJob = "terrame-build";
syntaxCpp.bashScript = "build/scripts/linux/ci/cpp-check.sh";
syntaxCpp.conditionName = "ALWAYS";
new JobCommons().build(this, syntaxCpp);

JobSpec terrame = new JobSpec("terrame-build");
terrame.downstreamJob = "terrame-code-analysis-base";
terrame.bashScript = "build/scripts/linux/ci/build-terrame.sh";
terrame.conditionName = "SUCCESS";
new JobCommons().build(this, terrame);

JobSpec codeAnalysisBase = new JobSpec("terrame-code-analysis-base");
codeAnalysisBase.downstreamJob = "terrame-code-analysis-terralib";
codeAnalysisBase.bashScript = "build/scripts/linux/ci/code-analysis.sh";
codeAnalysisBase.conditionName = "ALWAYS";
new JobCommons().build(this, codeAnalysisBase);

JobSpec codeAnalysisTerralib = new JobSpec("terrame-code-analysis-terralib");
codeAnalysisTerralib.downstreamJob = "terrame-doc-base";
codeAnalysisTerralib.bashScript = "build/scripts/linux/ci/code-analysis.sh \"terralib\"";
codeAnalysisTerralib.conditionName = "ALWAYS";
new JobCommons().build(this, codeAnalysisTerralib);

JobSpec docBase = new JobSpec("terrame-doc-base");
docBase.downstreamJob = "terrame-doc-terralib";
docBase.bashScript = "build/scripts/linux/ci/doc.sh";
docBase.conditionName = "ALWAYS";
new JobCommons().build(this, docBase);

JobSpec docTerralib = new JobSpec("terrame-doc-terralib");
docTerralib.downstreamJob = "terrame-doc-terralib";
docTerralib.bashScript = "build/scripts/linux/ci/doc.sh";
docTerralib.conditionName = "ALWAYS";
new JobCommons().build(this, docTerralib);

JobSpec unittestBase = new JobSpec("terrame-unittest-base");
unittestBase.downstreamJob = "terrame-unittest-terralib";
unittestBase.bashScript = "build/scripts/linux/ci/unittest.sh";
unittestBase.conditionName = "ALWAYS";
new JobCommons().build(this, unittestBase);

JobSpec unittestTerralib = new JobSpec("terrame-unittest-terralib");
unittestTerralib.downstreamJob = "terrame-test-execution";
unittestTerralib.bashScript = "build/scripts/linux/ci/unittest.sh";
unittestTerralib.conditionName = "ALWAYS";
new JobCommons().build(this, unittestTerralib);

JobSpec testExecution = new JobSpec("terrame-test-execution");
testExecution.downstreamJob = "terrame-repository-test";
testExecution.bashScript = "build/scripts/linux/ci/test-execution.sh";
testExecution.conditionName = "ALWAYS";
new JobCommons().build(this, testExecution);

JobSpec repositoryTest = new JobSpec("terrame-repository-test");
repositoryTest.downstreamJob = "terrame-installer";
repositoryTest.bashScript = "build/scripts/linux/ci/repository-test.sh";
repositoryTest.conditionName = "ALWAYS";
new JobCommons().build(this, repositoryTest);

_TERRAME_CREATE_INSTALLER = "ON";
JobSpec installer = new JobSpec("terrame-installer");
installer.bashScript = "build/scripts/linux/ci/installer.sh";
installer.publishOverSSH = true;
new JobCommons().build(this, installer);
