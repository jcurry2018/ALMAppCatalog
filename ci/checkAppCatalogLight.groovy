import hudson.model.Result
import jenkins.model.Jenkins

def jobName = build.buildVariables["DOWNSTREAM_JOB_NAME"]
def job = Jenkins.instance.getItemByFullName(jobName)
if (!job) {
    println "\n*** CAN'T FIND JOB ${jobName}! ***\n\n"
    return 1
}

def check_light = build.buildVariables["CHECK_LIGHT"]
if (check_light == "false") {
    print "\n* Not checking the App Catalog light! *\n\n"
} else if (job.lastCompletedBuild?.result != Result.SUCCESS) {
    print "\n*** CAN'T AUTO-BUMP BECAUSE APP CATALOG IS RED! ***\n\n"
    return 1
}
