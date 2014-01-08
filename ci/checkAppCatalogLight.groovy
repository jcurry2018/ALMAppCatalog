import hudson.model.Result
import jenkins.model.Jenkins

if (Jenkins.instance.getItem('ext42-app-catalog-continuous').lastCompletedBuild.result != Result.SUCCESS){
  println "\n*** CAN'T AUTO-BUMP BECAUSE APP CATALOG IS RED!*** \n"
  return 1
}
