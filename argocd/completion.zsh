if which argocd > /dev/null 2>&1
then
	source <(kubectl argo rollouts completion zsh)
fi
