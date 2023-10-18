alias k='kubectl config use-context'
alias kca='kubectl get --all-namespaces'
alias kgp='kubectl get pods'

function cronjobjob() {
    local job=$1
    local ns=${2:-default}
    kubectl -n $ns create job --from=cronjob/$job
}

alias spdemo="gcloud container clusters get-credentials sp-demo --region us-east1-b --project stackpulse-demo ; gcloud config set project stackpulse-demo"

# us
alias spprdsteps="gcloud container clusters get-credentials sp-playbooks --region us-central1 --project stackpulse-playbooks ; gcloud config set project stackpulse-playbooks"
alias spprdsteps2="gcloud container clusters get-credentials sp-playbooks2 --region us-central1 --project stackpulse-playbooks ; gcloud config set project stackpulse-playbooks"
alias spstgsteps="gcloud container clusters get-credentials steps --region europe-west1 --project torqio-stg-steps ; gcloud config set project torqio-stg-steps"
alias spprd="gcloud container clusters get-credentials sp-production --region us-central1 --project stackpulse-production ; gcloud config set project stackpulse-production"

# europe
alias spprdeu="gcloud container clusters get-credentials torq-production --region europe-west3 --project torqio-eu-production ; gcloud config set project torqio-eu-production"
alias spprdeusteps="gcloud container clusters get-credentials torqio-steps --region europe-west3 --project torqio-eu-steps ; gcloud config set project torqio-eu-steps"

# dev
alias spstg="gcloud container clusters get-credentials sp-staging --region europe-west1 --project stackpulse-staging ; gcloud config set project stackpulse-staging"
alias spdev="gcloud container clusters get-credentials sp-development --region europe-west1 --project stackpulse-development ; gcloud config set project stackpulse-development"