# if [ ! -e ~/torqio ] && [ $(command -v gh) ];; then
# ~/.dotfiles/torq/clonerepo.sh
# fi

if [[ $(wc -l <~/.kube/config) -gt 0 ]] && [[ $(cat ~/.kube/config | grep prdeu | wc -l) -ge 1 ]]; then
  # credentials
  gcloud container clusters get-credentials sp-development --region europe-west1 --project stackpulse-development
  gcloud container clusters get-credentials sp-staging --region europe-west1 --project stackpulse-staging
  gcloud container clusters get-credentials sp-production --region us-central1 --project stackpulse-production
  gcloud container clusters get-credentials steps-staging --region europe-west1 --project torqio-stg-steps
  gcloud container clusters get-credentials sp-playbooks --region us-central1 --project stackpulse-playbooks
  gcloud container clusters get-credentials steps-production-us-central1 --region us-central1 --project stackpulse-playbooks
  gcloud container clusters get-credentials torqio-steps --region europe-west3 --project torqio-eu-steps
  gcloud container clusters get-credentials torq-production --region europe-west3 --project torqio-eu-production
  # rename
  kubectl config rename-context gke_stackpulse-demo_us-central1_demo-cluster demo
  kubectl config rename-context gke_stackpulse-development_europe-west1_sp-development dev
  kubectl config rename-context gke_stackpulse-staging_europe-west1_sp-staging stg
  kubectl config rename-context gke_stackpulse-production_us-central1_sp-production prd
  kubectl config rename-context gke_torqio-eu-production_europe-west3_torq-production prdeu
  kubectl config rename-context gke_torqio-eu-steps_europe-west3_torqio-steps prdeu-steps
  kubectl config rename-context gke_torqio-stg-steps_europe-west1_steps stg-steps
  kubectl config rename-context gke_stackpulse-playbooks_us-central1_sp-playbooks prd-steps
fi
