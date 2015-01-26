import jenkins.model.Jenkins

def appSdkSrcVersion = build.buildVariables.APPSDK_SRC_VERSION
def env = build.characteristicEnvVars

def jsDep = new hudson.FilePath(build.workspace, 'js_dependencies.json').readToString()
def prevSdkVersionMatcher = jsDep =~ /appsdk-src:tgz:\D*(\d+)/
def prevSdkBuildNumber = prevSdkVersionMatcher[0][1] as int
def buildName = build.buildVariables.UPSTREAM_JOB_NAME ?: 'bridge/appsdk-alm-bridge'
def upstreamProject = Jenkins.instance.getItemByFullName(buildName)
def newBuildNumberMatcher = appSdkSrcVersion =~ /-(\d+)-/
def newBuildNumber = newBuildNumberMatcher[0][1] as int

StringBuilder commitMsg = new StringBuilder() << "${env.JOB_NAME} ${env.BUILD_NUMBER} bumping sdk to ${appSdkSrcVersion}" << "\n\n"

if(prevSdkBuildNumber < newBuildNumber){
    (prevSdkBuildNumber + 1..newBuildNumber).each { buildNumber ->
 	    def buildInList = upstreamProject.getBuildByNumber(buildNumber)

        if(buildInList) {
            buildInList.changeSet.each { change ->
                commitMsg << "sdk commit: RallySoftware/appsdk@${change.commitId}\n"
                commitMsg << "author: ${change.authorName}\n"
                commitMsg << "message: ${change.msg}\n\n"
            }
        }
    }
}

def appsdkBump = new hudson.FilePath(build.workspace, 'appsdk.bump')
appsdkBump.write(commitMsg as String, null)
