pipeline{
  agent {
    label 'agent'
  }
  tools{
    maven 'mavenslave'
  }
  stages {
    stage ('checkout'){
      steps{
          git branch: 'develop', credentialsId: 'GitHub', url: 'https://github.com/BloodyChaton/chaine-ci.git'
        }
    }
    stage ('validate'){
      steps{
        sh "mvn validate"
      }
    }
    stage ('deploy'){
      steps{
        sh "mvn deploy -DskipTests"
      }
    }

        stage ('release'){
      steps{
        sh "mvn release:clean"
        sh "mvn release:prepare"
        sh "mvn release:perform"
      }
    }
  }
}
