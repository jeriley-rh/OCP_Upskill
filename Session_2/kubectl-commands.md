#Note

To generate YAML or JSON output of the commands you will add '--dry-run=client' to run the command locally and then '-o yaml' or '-o json' to get the YAML or JSON output of that command.

##Namespace

  `kubectl create namespace ocpupskill`

##Pod

###Run Pod in default namespace
  `kubectl run hello-openshift --image=openshift/hello-openshift`

###Run Pod with an exposed port
  `kubectl run hello-openshift --image=openshift/hello-openshift --port=8080`

###Run Pod with an exposed port in the ocpupskill namespace and restart if it fails
  `kubectl run hello-openshift --image=openshift/hello-openshift --port=8080 --restart=Always --namespace=ocpupskill`

###Run Pod and keep it in the foreground and don't restart it
  `kubectl run -it busybox --image=busybox --restart=Never`

##Deployment

###Create deployment and specify the image, port, replicas, and namespace

  `kubectl create deployment hello-openshift --image=openshift/hello-openshift --port=8080 --replicas=1 --namespace=ocpupskill`

###Create a deployment with a command
  `kubectl create deployment my-dep --image=busybox -- date`

##Jobs and CronJobs

###Create a job to output the date
  `kubectl create job my-job --image=busybox -- date`

###Create a job from a CronJob
  `kubectl create job test-job --from=cronjob/my-job`

###Create a CronJob
  `kubectl create cronjob my-job --image=busybox --schedule="*/1 * * * *" -- date`

##Service

###ClusterIP
  `kubectl create service clusterip hello-openshift --tcp=8080:8080`

###LoadBalancer
  `kubectl create service loadbalancer hello-openshift --tcp=8080:8080`

###NodePort
  `kubectl create service nodeport hello-openshift --tcp=8080:8080`

###Headless ClusterIP
  `kubectl create service clusterip hello-openshift --clusterip="None" --tcp=8080:8080`
