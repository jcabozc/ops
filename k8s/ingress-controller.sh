#install ingress controller
git clone https://github.com/nginxinc/kubernetes-ingress/
cd kubernetes-ingress/deployments/helm-chart
helm install --name my-release .
kubectl get svc


helm ls --all my-release
helm del --purge my-release
helm status 

