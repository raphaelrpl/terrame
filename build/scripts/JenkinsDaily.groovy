String prefix = "terrame-daily-";
String environment = "-linux-ubuntu-14.04";

String _ROOT_BUILD_DIR =           "/home/jenkins/MyDevel/terrame/daily/";
String _TERRALIB_BUILD_BASE =      "$_ROOT_BUILD_DIR/terralib"
String _TERRALIB_3RDPARTY_DIR =    "$_TERRALIB_BUILD_BASE/3rdparty/5.2";
String _TERRALIB_GIT_DIR =         "$_TERRALIB_BUILD_BASE/git";
String _TERRALIB_OUT_DIR =         "$_TERRALIB_BUILD_BASE/solution/build";
String _TERRALIB_INSTALL_PATH =    "$_TERRALIB_BUILD_BASE/solution/install";
String _TERRAME_BUILD_BASE =       "$_ROOT_BUILD_DIR/terrame/";
String _TERRAME_GIT_DIR =          "$_TERRAME_BUILD_BASE/git";
String _TERRAME_TEST_DIR =         "$_TERRAME_BUILD_BASE/test;"
String _TERRAME_CREATE_INSTALLER = "OFF";
String _TERRAME_BUILD_AS_BUNDLE =  "OFF";

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
  public JobSpec(String jobName) {
    this.name = jobName;
  }
}

class JobCommons {
  static void build(JobSpec jobSpec) {
    job(prefix + jobName + environment) {
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
        If set, it will trigger a specific job with current build parameters based on Condition role (STABLE, COMPLETED (Always), etc).
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
terralib.conditionName = "STABLE";
JobCommons.build(terralib);

JobSpec syntaxCpp = new JobSpec("terrame-cpp-syntax-check");
syntaxCpp.downstreamJob = "terrame-build";
syntaxCpp.bashScript = "build/scripts/linux/ci/cpp-check.sh";
syntaxCpp.conditionName = "COMPLETED";
JobCommons.build(syntaxCpp);

JobSpec terrame = new JobSpec("terrame-build");
terrame.downstreamJob = "terrame-code-analysis-base";
terrame.bashScript = "build/scripts/linux/ci/build-terrame.sh";
terrame.conditionName = "STABLE";
JobCommons.build(terrame);

JobSpec codeAnalysisBase = new JobSpec("terrame-code-analysis-base");
codeAnalysisBase.downstreamJob = "terrame-code-analysis-terralib";
codeAnalysisBase.bashScript = "build/scripts/linux/ci/code-analysis.sh";
codeAnalysisBase.conditionName = "COMPLETED";
JobCommons.build(codeAnalysisBase);

JobSpec codeAnalysisTerralib = new JobSpec("terrame-code-analysis-terralib");
codeAnalysisTerralib.downstreamJob = "terrame-doc-base";
codeAnalysisTerralib.bashScript = "build/scripts/linux/ci/code-analysis.sh \"terralib\"";
codeAnalysisTerralib.conditionName = "COMPLETED";
JobCommons.build(codeAnalysisTerralib);

JobSpec docBase = new JobSpec("terrame-doc-base");
docBase.downstreamJob = "terrame-doc-terralib";
docBase.bashScript = "build/scripts/linux/ci/doc.sh";
docBase.conditionName = "COMPLETED";
JobCommons.build(docBase);

JobSpec docTerralib = new JobSpec("terrame-doc-terralib");
docTerralib.downstreamJob = "terrame-doc-terralib";
docTerralib.bashScript = "build/scripts/linux/ci/doc.sh";
docTerralib.conditionName = "COMPLETED";
JobCommons.build(docTerralib);

JobSpec unittestBase = new JobSpec("terrame-unittest-base");
unittestBase.downstreamJob = "terrame-unittest-terralib";
unittestBase.bashScript = "build/scripts/linux/ci/unittest.sh";
unittestBase.conditionName = "COMPLETED";
JobCommons.build(unittestBase);

JobSpec unittestTerralib = new JobSpec("terrame-unittest-terralib");
unittestTerralib.downstreamJob = "terrame-test-execution";
unittestTerralib.bashScript = "build/scripts/linux/ci/unittest.sh";
unittestTerralib.conditionName = "COMPLETED";
JobCommons.build(unittestTerralib);

JobSpec testExecution = new JobSpec("terrame-test-execution");
testExecution.downstreamJob = "terrame-repository-test";
testExecution.bashScript = "build/scripts/linux/ci/test-execution.sh";
testExecution.conditionName = "COMPLETED";
JobCommons.build(testExecution);

JobSpec repositoryTest = new JobSpec("terrame-repository-test");
repositoryTest.downstreamJob = "terrame-installer";
repositoryTest.bashScript = "build/scripts/linux/ci/repository-test.sh";
repositoryTest.conditionName = "COMPLETED";
JobCommons.build(repositoryTest);

_TERRAME_CREATE_INSTALLER = "ON";
JobSpec installer = new JobSpec("terrame-installer");
installer.bashScript = "build/scripts/linux/ci/installer.sh";
JobCommons.build(installer);
