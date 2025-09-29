pipeline {
  agent any

  parameters {
    string(name:'project_name',       defaultValue:'drproj')
    string(name:'primary_region',     defaultValue:'us-east-2')
    string(name:'secondary_region',   defaultValue:'us-west-2')

    string(name:'hosted_zone_name',   defaultValue:'disasterrecoveryproject.online') // no trailing dot
    string(name:'app_record_name',    defaultValue:'app.disasterrecoveryproject.online')

    string(name:'primary_vpc_cidr',   defaultValue:'10.10.0.0/16')
    string(name:'secondary_vpc_cidr', defaultValue:'10.20.0.0/16')

    string(name:'instance_type',      defaultValue:'t3.micro')
    string(name:'key_pair_name',      defaultValue:'')

    string(name:'db_username',        defaultValue:'adminuser')
    credentials(name:'db_password',   defaultValue:'', description:'RDS DB password',
                credentialType:'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl')

    string(name:'replication_prefix', defaultValue:'')
    choice(name:'ACTION', choices:['plan','apply'], description:'Terraform action')
  }

  environment { TF_IN_AUTOMATION = 'true' }

  options { timestamps(); ansiColor('xterm'); disableConcurrentBuilds() }

  stages {
    stage('Checkout') {
      steps {
        // If this job is "Pipeline from SCM", checkout scm works. Otherwise configure GitSCM here.
        checkout scm
      }
    }

    stage('Write tfvars (from parameters)') {
      steps {
        withCredentials([string(credentialsId: 'db_password', variable: 'DB_PASSWORD')]) {
          sh '''
            set -e
            cat > jenkins.auto.tfvars <<EOF
project_name        = "${project_name}"
primary_region      = "${primary_region}"
secondary_region    = "${secondary_region}"
hosted_zone_name    = "${hosted_zone_name}"
app_record_name     = "${app_record_name}"
primary_vpc_cidr    = "${primary_vpc_cidr}"
secondary_vpc_cidr  = "${secondary_vpc_cidr}"
instance_type       = "${instance_type}"
key_pair_name       = "${key_pair_name}"
db_username         = "${db_username}"
db_password         = "${DB_PASSWORD}"
replication_prefix  = "${replication_prefix}"
EOF
          '''
        }
      }
    }

    stage('Init & Validate') {
      steps {
        sh '''
          set -e
          terraform --version
          terraform init -input=false
          terraform fmt -chec
