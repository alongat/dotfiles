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
alias gcpprdsteps='gcpset stackpulse-playbooks ; k prd-steps'
alias gcpprdeu='gcpset torqio-eu-production ; k prdeu'
alias gcpprdeusteps='gcpset torqio-eu-steps ; k prdeu-steps'
alias gcpdemo='gcpset stackpulse-demo'

