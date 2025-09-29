pipeline {
  agent any

  parameters {
    string(name:'project_name',       defaultValue:'drproj')
    string(name:'primary_region',     defaultValue:'us-east-2')
    string(name:'secondary_region',   defaultValue:'us-west-2')

    // Enter WITHOUT a trailing dot; we will add it automatically below
    string(name:'hosted_zone_name',   defaultValue:'disasterrecoveryproject.online')
    string(name:'app_record_name',    defaultValue:'app.disasterrecoveryproject.online')

    string(name:'primary_vpc_cidr',   defaultValue:'10.10.0.0/16')
    string(name:'secondary_vpc_cidr', defaultValue:'10.20.0.0/16')

    string(name:'instance_type',      defaultValue:'t3.micro')
    string(name:'key_pair_name',      defaultValue:'')

    string(name:'db_username',        defaultValue:'adminuser')
    string(name:'alert_email',        defaultValue:'you@example.com')

    string(name:'replication_prefix', defaultValue:'')
    choice(name:'ACTION', choices:['plan','apply'], description:'Terraform action')
  }

  options { timestamps(); disableConcurrentBuilds() }


  environment { TF_IN_AUTOMATION = 'true' }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Write tfvars (from parameters)') {
      steps {
        withCredentials([string(credentialsId: 'db_password', variable: 'DB_PASSWORD')]) {
          sh '''
            set -e

            # Ensure hosted_zone_name has a trailing dot (Route 53 expects it)
            HZ="${hosted_zone_name}"
            case "$HZ" in
              *.) ;;        # already has dot
              *) HZ="${HZ}.";;
            esac

            cat > jenkins.auto.tfvars <<EOF
project_name        = "${project_name}"
primary_region      = "${primary_region}"
secondary_region    = "${secondary_region}"
hosted_zone_name    = "${HZ}"
app_record_name     = "${app_record_name}"
primary_vpc_cidr    = "${primary_vpc_cidr}"
secondary_vpc_cidr  = "${secondary_vpc_cidr}"
instance_type       = "${instance_type}"
key_pair_name       = "${key_pair_name}"
db_username         = "${db_username}"
db_password         = "${DB_PASSWORD}"
alert_email         = "${alert_email}"
replication_prefix  = "${replication_prefix}"
EOF
            echo "Wrote jenkins.auto.tfvars:"
            cat jenkins.auto.tfvars | sed 's/db_password.*/db_password = ****/'
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
          terraform fmt -check
          terraform validate
        '''
      }
    }

    stage('Plan') {
      steps {
        sh 'terraform plan -input=false -out=tfplan'
      }
      post { always { archiveArtifacts artifacts: 'tfplan', fingerprint: true } }
    }

    stage('Approve Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps { input message: 'Apply infrastructure?', ok: 'Apply' }
    }

    stage('Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh 'terraform apply -input=false tfplan'
      }
    }
  }
}
