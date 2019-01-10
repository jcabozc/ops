## 1. Installation

```shell
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh


kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller


helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12\
--stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
kubectl -n kube-system get pods|grep tiller

helm version
```
*if error：*
*在各个结点上安装：*
```shell
yum -y install socat
```
