alias g='gcloud config configurations activate'
alias gssh='gcloud beta compute ssh --ssh-key-file ~/.ssh/id_ed25519 --tunnel-through-iap'
alias gcpctx='gcloud config get-value project'

function gcpset() {
	gcloud config set project $1	
}

# purge cdn
# pcdn service-name-here "/some-path/*"
function pcdn() {
	local urlmap=$1
	local urlpath=$2
	local name=$(gcloud compute url-maps list --filter="name~$urlmap" --format='value(name)')
	echo "invalidating path $urlpath for $name"
	gcloud compute url-maps invalidate-cdn-cache $name --path "$urlpath"
}
