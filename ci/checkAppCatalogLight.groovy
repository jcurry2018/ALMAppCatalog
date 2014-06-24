import hudson.model.Result
import jenkins.model.Jenkins

def check_light = build.buildVariables["CHECK_LIGHT"]
if (check_light == "false") {
    print "\n* Not checking the App Catalog light! *\n\n"
} else if (build.project.lastCompletedBuild.result != Result.SUCCESS) {
    print "\n*** CAN'T AUTO-BUMP BECAUSE APP CATALOG IS RED! ***\n\n"
    return 1
}
