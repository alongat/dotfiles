alias k='kubectl config use-context'
alias kca='kubectl get --all-namespaces'
alias kgp='kubectl get pods'

function cronjobjob() {
    local job=$1
    local ns=${2:-default}
    kubectl -n $ns create job --from=cronjob/$job
}

function kwatchpodlogs(){
  local pod=$1
  local ns=${2:-default}
  kubectl -n $ns logs -f $pod
}

function kwatchpod(){
  local pod=$1
  local ns=${2:-default}
  viddy "kubectl -n $ns get pods | grep $pod"
}
