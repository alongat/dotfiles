function wrap_with_single_quotes () {
  sed "s/'/'\\''/g; s/.*/'&'/" | paste -sd "," -
}

function prd-query-accounts () {
	accounts_list=$1
	bq-query-accounts stackpulse-production $accounts_list
}

function bq-query-accounts () {
	project=$1
	accounts_list=$2
	quoted_accounts_list=$(echo $accounts_list | wrap_with_single_quotes)
	query=$(cat << EOF
	SELECT o.name as organization_name, a.short_name as account_short_name, a.name as account_name, a.id as account_id, o.id as organization_id FROM $project.bi.dim_accounts a, $project.bi.dim_orgs o WHERE a.id IN ($quoted_accounts_list) AND o.id = a.organization_id
EOF
)
	bq query --format=prettyjson --use_legacy_sql=false $query 2> /dev/null
}


alias gcpdev='gcpset stackpulse-development ; k dev'
alias gcpstg='gcpset stackpulse-staging ; k stg'
alias gcpprd='gcpset stackpulse-production ; k prd'
alias gcpprdsteps='gcpset stackpulse-steps ; k prdsteps'
alias gcpprdeu='gcpset torqio-eu-production ; k prdeu'
alias gcpprdsteps='gcpset torqio-eu-steps ; k prdeusteps'
alias gcpdemo='gcpset stackpulse-demo'

# alias spdemo="gcloud container clusters get-credentials sp-demo --region us-east1-b --project stackpulse-demo ; gcloud config set project stackpulse-demo"
# us
# alias spprdsteps="gcloud container clusters get-credentials sp-playbooks --region us-central1 --project stackpulse-playbooks ; gcloud config set project stackpulse-playbooks"
# alias spprdsteps2="gcloud container clusters get-credentials sp-playbooks2 --region us-central1 --project stackpulse-playbooks ; gcloud config set project stackpulse-playbooks"
# alias spstgsteps="gcloud container clusters get-credentials steps --region europe-west1 --project torqio-stg-steps ; gcloud config set project torqio-stg-steps"
# alias spprd="gcloud container clusters get-credentials sp-production --region us-central1 --project stackpulse-production ; gcloud config set project stackpulse-production"
# # europe
# alias spprdeu="gcloud container clusters get-credentials torq-production --region europe-west3 --project torqio-eu-production ; gcloud config set project torqio-eu-production"
# alias spprdeusteps="gcloud container clusters get-credentials torqio-steps --region europe-west3 --project torqio-eu-steps ; gcloud config set project torqio-eu-steps"
# # dev
# alias spstg="gcloud container clusters get-credentials sp-staging --region europe-west1 --project stackpulse-staging ; gcloud config set project stackpulse-staging"
# alias spdev="gcloud container clusters get-credentials sp-development --region europe-west1 --project stackpulse-development ; gcloud config set project stackpulse-development"
