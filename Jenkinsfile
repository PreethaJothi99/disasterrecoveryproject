pipeline {
  agent any
  parameters {
    // Set these when you click "Build with Parameters"
    string(name:'project_name',       defaultValue:'drproj')
    string(name:'primary_region',     defaultValue:'us-east-2')
    string(name:'secondary_region',   defaultValue:'us-west-2')

    string(name:'hosted_zone_name',   defaultValue:'disasterrecoveryproject.online.')
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

  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Export TF Vars') {
      steps {
        sh '''
          cat > .tfenv <<EOF
TF_VAR_project_name=${project_name}
TF_VAR_primary_region=${primary_region}
TF_VAR_secondary_region=${secondary_region}
TF_VAR_hosted_zone_name=${hosted_zone_name}
TF_VAR_app_record_name=${app_record_name}
TF_VAR_primary_vpc_cidr=${primary_vpc_cidr}
TF_VAR_secondary_vpc_cidr=${secondary_vpc_cidr}
TF_VAR_instance_type=${instance_type}
TF_VAR_key_pair_name=${key_pair_name}
TF_VAR_db_username=${db_username}
TF_VAR_db_password=${db_password}
TF_VAR_replication_prefix=${replication_prefix}
EOF
        '''
        script {
          readFile('.tfenv').split('\n').each { if (it?.trim()) { def (k,v)=it.tokenize('='); env[k]=v } }
        }
      }
    }

    stage('Init & Validate') {
      steps {
        sh '''
          cd dr-infra
          terraform --version
          terraform init -input=false
          terraform fmt -check
          terraform validate
        '''
      }
    }

    stage('Plan') {
      steps {
        sh '''
          cd dr-infra
          terraform plan -input=false -out=tfplan
        '''
      }
      post { always { archiveArtifacts artifacts: 'dr-infra/tfplan', fingerprint: true } }
    }

    stage('Approve Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps { input message: 'Apply infrastructure?', ok: 'Apply' }
    }

    stage('Apply') {
      when { expression { params.ACTION == 'apply' } }
      steps {
        sh '''
          cd dr-infra
          terraform apply -input=false tfplan
        '''
      }
    }
  }
}
