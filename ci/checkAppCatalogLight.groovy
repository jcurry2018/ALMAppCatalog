import hudson.model.Result
import jenkins.model.Jenkins

def check_light = build.buildVariables["CHECK_LIGHT"]
if (check_light == "false") {
    print "\n* Not checking the App Catalog light! *\n\n"
} else if (Jenkins.instance.getItem('ext42-app-catalog-continuous').lastCompletedBuild.result != Result.SUCCESS) {
    print "\n*** CAN'T AUTO-BUMP BECAUSE APP CATALOG IS RED! ***\n\n"
    return 1
}
