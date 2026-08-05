# Zabbix Helm Chart

# Introduction

This Helm chart installs components for Kubernetes cluster monitoring by Zabbix.

The architecture diagram is presented below:

![Architecture diagram](images/architecture.png)

Source (YouTube): [`Monitoring Kubernetes with Zabbix`](https://youtu.be/2dPFvJrK9Mw)

## kube-state-metrics

[**kube-state-metrics (KSM)**](https://github.com/kubernetes/kube-state-metrics) is a simple service that listens to the Kubernetes API server and generates metrics about the state of objects in the cluster.

If kube-state-metrics is already installed in the cluster, it can be used instead of the one deployed by this chart. Set the `kube-state-metrics.enabled` parameter to `false` and specify the endpoint name in the macro `{$KUBE.STATE.ENDPOINT.NAME}` in the "Kubernetes cluster state by HTTP" template according to your environment. If the kube-state-metrics configuration deviates from the default values, some metrics may not be available.

**Note**

kube-state-metrics with OpenShift installation requires one modification at the ReplicaSet level. This block must be removed or changed:

```bash
  securityContext:
    runAsUser: 65534
    runAsGroup: 65534
    fsGroup: 65534
```

## Zabbix agent

The **Zabbix agent** is deployed in passive mode (by default) as a DaemonSet on all cluster nodes to monitor individual node host resources using the "Linux by Zabbix agent" template.

Depending on the Kubernetes distribution used, it may be necessary to adjust the taint in the `zabbixAgent.tolerations` parameter if monitoring of control plane nodes is required.

If monitoring of nodes with the "Linux by Zabbix agent" template is not required, it can be disabled by setting the `zabbixAgent.enabled` parameter to `false`, which will prevent the DaemonSet from being deployed.

## Zabbix proxy

The **Zabbix proxy** is installed in the cluster in active mode (by default) as a Deployment with a single replica. It collects data from the Kubernetes API, kube-state-metrics endpoint, and Zabbix agents. All collected data is buffered locally and then transferred to the external **Zabbix server** to which the proxy belongs and is used for monitoring.

If a Zabbix proxy is already installed in the cluster, it can be used instead of the one deployed by this chart. Set the `zabbixProxy.enabled` parameter to `false` and add the proxy to the Zabbix server that is used for monitoring.

**Note**

The Kubernetes API, kube-state-metrics endpoint, and Zabbix agents (if deployed) must be reachable by the proxy.

# Tested versions

- Kubernetes cluster 1.26
- Helm 3.0+
- Zabbix server 7.2+
- kube-state-metrics 2.2.0, 2.9.2

# Installation

Install the [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/) and [helm](https://helm.sh/docs/) tools following the instructions.

Add the repository:

```bash
helm repo add zabbix-chart-7.2  https://cdn.zabbix.com/zabbix/integrations/kubernetes-helm/7.2
```

Export the default values of the chart ``helm-zabbix`` to the file ``$HOME/zabbix_values.yaml``:

```bash
helm show values zabbix-chart-7.2/zabbix-helm-chrt > $HOME/zabbix_values.yaml
```
Change the `zabbixProxy.env.ZBX_SERVER_HOST` environment variable in the file `$HOME/zabbix_values.yaml` to the address of the Zabbix server that is used for monitoring and is reachable by the Zabbix proxy. Other values can be changed according to your environment if needed.

List the namespaces of the cluster:

```bash
kubectl get namespaces
```

Create the namespace ``monitoring`` if it does not exist in the cluster:

```bash
kubectl create namespace monitoring
```

Deploy the chart in the Kubernetes cluster (update the YAML file paths if necessary):

```bash
helm install zabbix zabbix-chart-7.2/zabbix-helm-chrt --dependency-update -f $HOME/zabbix_values.yaml -n monitoring
```

Get the token automatically created for the service account:

```bash
kubectl get secret zabbix-service-account -n monitoring -o jsonpath={.data.token} | base64 -d
```
## Post-installation steps

Set up the [`Kubernetes templates`](https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/app/kubernetes_http?at=release%2F7.2) according to the instructions.

## Other commands

View the services:

```bash
kubectl get svc -n monitoring
```

View the pods:

```bash
kubectl get pods -n monitoring
```

View information about pods:

```bash
kubectl describe pods/POD_NAME -n monitoring
```

View all the containers in a pod:

```bash
kubectl get pods POD_NAME -n monitoring -o jsonpath='{.spec.containers[*].name}*'
```

View the container logs of pods:

```bash
kubectl logs -f pods/POD_NAME -n monitoring
```

Access the command prompt of the pod container:

```bash
kubectl exec -it pods/POD_NAME -n monitoring -- sh
```

# Uninstallation

To uninstall/delete the ``zabbix`` deployment:

```bash
helm uninstall zabbix -n monitoring
```

# License
The project is distributed under [AGPL-3.0-only](LICENSE).

# Configuration

The following table lists the main configurable parameters of the chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | | Replaces the name of the chart in the Chart.yaml |
| fullnameOverride | string | | Replaces the generated name |
| kube-state-metrics.enabled | bool | `true`| If true, deploys the kube-state-metrics deployment |
| rbac.create |	bool |	`true` |	Specifies whether the RBAC resources should be created |
| rbac.additionalRulesForClusterRole |	list |	`[]` |	Specifies additional rules for clusterRole |
| serviceAccount.create	| bool	| `true` | Specifies whether a service account should be created |
| serviceAccount.name |	string| `zabbix-service-account` |	Name of the service account to use. If not set, the name is generated using the fullname template |
| zabbixProxy.enabled | bool | `false` | Enables use of Zabbix proxy |
| zabbixProxy.containerSecurityContext | object | `{}` |  Security Context for Zabbix proxy |
| zabbixProxy.resources | object | `{}` | Set resource requests/limits for Zabbix proxy |
| zabbixProxy.image.repository | string | `"zabbix/zabbix-proxy-sqlite3"` | Zabbix proxy Docker image name |
| zabbixProxy.image.tag | string | `"alpine-7.2.10"` | Tag of Docker image for Zabbix proxy |
| zabbixProxy.image.pullPolicy | string | `"IfNotPresent"` | Pull policy for Docker image |
| zabbixProxy.image.pullSecrets | list | `[]` | List of dockerconfig secrets names to use when pulling images. Secrets must be manually created in the namespace. |
| zabbixProxy.env.ZBX_PROXYMODE | int | `0` | This variable allows switching Zabbix proxy mode. By default, the value is 0 - active proxy. Allowed values are 0 - active proxy and 1 - passive proxy. |
| zabbixProxy.env.ZBX_HOSTNAME | string | `"zabbix-proxy"` | Zabbix proxy hostname |
| zabbixProxy.env.ZBX_SERVER_HOST | string | `"127.0.0.1"` | Zabbix server host. If you need to change the port number, add a colon `:` followed by the port number to the end of the value. |
| zabbixProxy.env.ZBX_DEBUGLEVEL | int | `3` |  This variable is used to specify debug level. By default, the value is 3 |
| zabbixProxy.env.ZBX_JAVAGATEWAY_ENABLE | bool | `false` | This variable enables communication with Zabbix Java gateway to collect Java-related checks. By default, the value is false. If zabbixJavaGateway enable value is true. |
| zabbixProxy.env.ZBX_STARTJAVAPOLLERS | int | `0` | This variable specifies the amount of pre-forked instances of Java pollers. By default, the value is 0. If zabbixJavaGateway enable value is 5. |
| zabbixProxy.env.ZBX_CACHESIZE | string | `"128M"` | Cache size |
| zabbixProxy.env.ZBX_PROXYCONFIGFREQUENCY | string | `10` | How often the proxy retrieves configuration data from the Zabbix server, in seconds. Active proxy parameter. Ignored for passive proxies. |
| zabbixProxy.livenessProbe.enabled | string | `"true"` | Enable livenessProbe on Zabbix proxy containers |
| zabbixProxy.livenessProbe.tcpSocket.port | string | `"zabbix-proxy"` | Name of port for livenessProbe |
| zabbixProxy.livenessProbe.initialDelaySeconds | int | `10` | Initial delay seconds for livenessProbe |
| zabbixProxy.livenessProbe.timeoutSeconds | int | `3` | Timeout seconds for livenessProbe |
| zabbixProxy.livenessProbe.failureThreshold | int | `3` | Failure threshold for livenessProbe |
| zabbixProxy.livenessProbe.periodSeconds | int | `10` | Period seconds for livenessProbe |
| zabbixProxy.livenessProbe.successThreshold | int | `1` | Success threshold for livenessProbe |
| zabbixProxy.readinessProbe.enabled | string | `"false"` | Enable readinessProbe on Zabbix proxy containers |
| zabbixProxy.readinessProbe.tcpSocket.port | string | `"zabbix-proxy"` | Name of port for readinessProbe |
| zabbixProxy.readinessProbe.initialDelaySeconds | int | `10` | Initial delay seconds for readinessProbe |
| zabbixProxy.readinessProbe.timeoutSeconds | int | `3` | Timeout seconds for readinessProbe |
| zabbixProxy.readinessProbe.failureThreshold | int | `3` | Failure threshold for readinessProbe |
| zabbixProxy.readinessProbe.periodSeconds | int | `10` | Period seconds for readinessProbe |
| zabbixProxy.readinessProbe.successThreshold | int | `1` | Success threshold for readinessProbe |
| zabbixProxy.startupProbe.enabled | string | `"true"` | Enable startupProbe on Zabbix proxy containers |
| zabbixProxy.startupProbe.tcpSocket.port | string | `"zabbix-proxy"` | Name of port for startupProbe |
| zabbixProxy.startupProbe.initialDelaySeconds | int | `30` | Initial delay seconds for startupProbe |
| zabbixProxy.startupProbe.timeoutSeconds | int | `3` | Timeout seconds for startupProbe |
| zabbixProxy.startupProbe.failureThreshold | int | `5` | Failure threshold for startupProbe |
| zabbixProxy.startupProbe.periodSeconds | int | `10` | Period seconds for startupProbe |
| zabbixProxy.startupProbe.successThreshold | int | `1` | Success threshold for startupProbe |
| zabbixProxy.service.port | int | `10051` | Port to expose service |
| zabbixProxy.service.annotations | object | `{}` |  Zabbix proxy data Service label annotations |
| zabbixProxy.service.labels | object | `{}` | Zabbix proxy data Service labels |
| zabbixProxy.service.targetPort | int | `10051` | Port of application pod |
| zabbixProxy.service.type | string | `"ClusterIP"` | Type of service for Zabbix proxy |
| zabbixProxy.service.externalIPs | list | `[]` | External IPs for Zabbix proxy |
| zabbixProxy.service.loadBalancerIP | string | `""` | Only use if service.type is "LoadBalancer" |
| zabbixProxy.service.loadBalancerSourceRanges | list | `[]` | Only use if service.type is "LoadBalancer" |
| zabbixProxy.nodeSelector | object | `{}` | Node selector configurations |
| zabbixProxy.tolerations | object | `{}` | Tolerations configurations for Zabbix proxy |
| zabbixProxy.affinity | object | `{}` | Affinity configurations for Zabbix proxy |
| zabbixProxy.persistentVolume.enabled |  bool | `false` | If true, Zabbix proxy will create/use a Persistent Volume Claim |
| zabbixProxy.persistentVolume.accessModes | list | `- ReadWriteOnce` | Zabbix proxy data Persistent Volume access modes |
| zabbixProxy.persistentVolume.annotations | object | `{}` | Zabbix proxy data Persistent Volume Claim annotations |
| zabbixProxy.persistentVolume.existingClaim | string | `''` | Zabbix proxy data Persistent Volume existing claim name |
| zabbixProxy.persistentVolume.mountPath | string | `/data` | Zabbix proxy data Persistent Volume mount root path |
| zabbixProxy.persistentVolume.size | string | `2Gi` | Zabbix proxy data Persistent Volume size |
| zabbixProxy.persistentVolume.storageClass | string | `"-"` | Zabbix proxy data Persistent Volume Storage Class |
| zabbixProxy.persistentVolume.volumeBindingMode | string | `''` | Zabbix proxy data Persistent Volume Binding Mode |
| zabbixProxy.persistentVolume.subPath | string | `''` | Subdirectory of Zabbix proxy data Persistent Volume to mount |
| zabbixAgent.enabled | bool | `true` | Enables use of Zabbix agent |
| zabbixAgent.resources | object | `{}` |  Set resource requests/limits for Zabbix agents |
| zabbixAgent.volumes_host | bool | `true` | Whether a preconfigured set of volumes should be mounted (`/`, `/etc`, `/sys`, `/proc`, `/var/run`) |
| zabbixAgent.volumes | list | `[]`  | Add additional volumes to be mounted |
| zabbixAgent.volumeMounts | list | `[]` | Add additional volumes to be mounted |
| zabbixAgent.image.repository | string | `"zabbix/zabbix-agent2"` | Zabbix agent Docker image name |
| zabbixAgent.image.tag | string | `"alpine-7.2.10"` | Tag of Docker image for Zabbix agent |
| zabbixAgent.image.pullPolicy | string | `"IfNotPresent"` | Pull policy for Docker image |
| zabbixAgent.image.pullSecrets | list | `[]` | List of dockerconfig secrets names to use when pulling images. Secrets must be manually created in the namespace. |
| zabbixAgent.env.ZBX_SERVER_HOST | string | `"0.0.0.0/0"` | Zabbix server host |
| zabbixAgent.env.ZBX_SERVER_PORT | int | `10051` | Zabbix server port |
| zabbixAgent.env.ZBX_PASSIVE_ALLOW | bool | `true` | This variable is boolean (true or false) and enables or disables the feature of passive checks. By default, the value is true |
| zabbixAgent.env.ZBX_ACTIVE_ALLOW | bool | `false` | This variable is boolean (true or false) and enables or disables the feature of active checks |
| zabbixAgent.env.ZBX_DEBUGLEVEL | int | `3` |  This variable is used to specify debug level. By default, the value is 3 |
| zabbixAgent.env.ZBX_TIMEOUT | int | 4 |  This variable is used to specify timeout for processing checks. By default, the value is 4 |
| zabbixAgent.livenessProbe.enabled | string | `"true"` | Enable livenessProbe on Zabbix agent containers |
| zabbixAgent.livenessProbe.tcpSocket.port | string | `"zabbix-agent"` | Name of port for livenessProbe |
| zabbixAgent.livenessProbe.initialDelaySeconds | int | `10` | Initial delay seconds for livenessProbe |
| zabbixAgent.livenessProbe.timeoutSeconds | int | `3` | Timeout seconds for livenessProbe |
| zabbixAgent.livenessProbe.failureThreshold | int | `3` | Failure threshold for livenessProbe |
| zabbixAgent.livenessProbe.periodSeconds | int | `10` | Period seconds for livenessProbe |
| zabbixAgent.livenessProbe.successThreshold | int | `1` | Success threshold for livenessProbe |
| zabbixAgent.readinessProbe.enabled | string | `"false"` | Enable readinessProbe on Zabbix agent containers |
| zabbixAgent.readinessProbe.tcpSocket.port | string | `"zabbix-agent"` | Name of port for readinessProbe |
| zabbixAgent.readinessProbe.initialDelaySeconds | int | `10` | Initial delay seconds for readinessProbe |
| zabbixAgent.readinessProbe.timeoutSeconds | int | `3` | Timeout seconds for readinessProbe |
| zabbixAgent.readinessProbe.failureThreshold | int | `3` | Failure threshold for readinessProbe |
| zabbixAgent.readinessProbe.periodSeconds | int | `10` | Period seconds for readinessProbe |
| zabbixAgent.readinessProbe.successThreshold | int | `1` | Success threshold for readinessProbe |
| zabbixAgent.startupProbe.enabled | string | `"true"` | Enable startupProbe on Zabbix agent containers |
| zabbixAgent.startupProbe.tcpSocket.port | string | `"zabbix-agent"` | Name of port for startupProbe |
| zabbixAgent.startupProbe.initialDelaySeconds | int | `30` | Initial delay seconds for startupProbe |
| zabbixAgent.startupProbe.timeoutSeconds | int | `3` | Timeout seconds for startupProbe |
| zabbixAgent.startupProbe.failureThreshold | int | `5` | Failure threshold for startupProbe |
| zabbixAgent.startupProbe.periodSeconds | int | `10` | Period seconds for startupProbe |
| zabbixAgent.startupProbe.successThreshold | int | `1` | Success threshold for startupProbe |
| zabbixAgent.service.type | string | `"ClusterIP"` | Type of service for Zabbix agent |
| zabbixAgent.service.port | int | `10050` | Port to expose service |
| zabbixAgent.service.annotations | object | ` agent.zabbix/monitor: "true"` |  Zabbix agent data Service label annotations |
| zabbixAgent.service.labels | object | `{}` | Zabbix agent data Service labels |
| zabbixAgent.service.targetPort | int | `10050` | Port of application pod |
| zabbixAgent.service.externalIPs | list | `[]` | External IPs for Zabbix agent |
| zabbixAgent.serviceAccount.create	| bool	| `true` | Specifies whether a service account should be created |
| zabbixAgent.serviceAccount.name |	string| `zabbix-agent-service-account` |	The name of the service account to use. If not set, the name is generated using the fullname template |
| zabbixAgent.nodeSelector | object | `kubernetes.io/os: linux` | nodeSelector configurations |
| zabbixAgent.tolerations | list | ` - effect: NoSchedule key: node-role.kubernetes.io/control-plane`| Allows scheduling Zabbix agents on tainted nodes |
| zabbixAgent.rbac.create |	bool |	`true` |	Specifies whether the RBAC resources should be created |
| zabbixAgent.rbac.pspEnabled |	bool |	`true` |	If true, create & use Pod Security Policy resources |
| zabbixJavaGateway.enabled | bool | `false` | Enables use of Zabbix Java gateway |
| zabbixJavaGateway.resources | object | `{}` |  Set resource requests/limits for Zabbix Java gateway |
| zabbixJavaGateway.containerSecurityContext | object | `{}` |  Security Context for a Container for Zabbix Java gateway |
| zabbixJavaGateway.image.repository | string | `"zabbix/zabbix-java-gateway"` | Zabbix Java gateway Docker image name |
| zabbixJavaGateway.image.tag | string | `"alpine-7.2.10"` | Tag of Docker image for Zabbix Java gateway |
| zabbixJavaGateway.image.pullPolicy | string | `"IfNotPresent"` | Pull policy for Docker image |
| zabbixJavaGateway.image.pullSecrets | list | `[]` | List of dockerconfig secrets names to use when pulling images. Secrets must be manually created in the namespace. |
| zabbixJavaGateway.env.ZBX_START_POLLERS | int | `5` | This variable specifies the amount of pollers. By default, the value is 5 |
| zabbixJavaGateway.env.ZBX_TIMEOUT | int | `3`|  This variable is used to specify timeout for processing checks. By default, the value is 3 |
| zabbixJavaGateway.env.ZBX_DEBUGLEVEL | string | `"info"` |  This variable is used to specify debug level. By default, the value is info |
| zabbixJavaGateway.livenessProbe.enabled | string | `"true"` | Enable livenessProbe on Zabbix Java gateway containers |
| zabbixJavaGateway.livenessProbe.tcpSocket.port | string | `"zabbix-jmx"` | Name of port for livenessProbe |
| zabbixJavaGateway.livenessProbe.initialDelaySeconds | int | `10` | Initial delay seconds for livenessProbe |
| zabbixJavaGateway.livenessProbe.timeoutSeconds | int | `3` | Timeout seconds for livenessProbe |
| zabbixJavaGateway.livenessProbe.failureThreshold | int | `3` | Failure threshold for livenessProbe |
| zabbixJavaGateway.livenessProbe.periodSeconds | int | `10` | Period seconds for livenessProbe |
| zabbixJavaGateway.livenessProbe.successThreshold | int | `1` | Success threshold for livenessProbe |
| zabbixJavaGateway.readinessProbe.enabled | string | `"false"` | Enable readinessProbe on Zabbix Java gateway containers |
| zabbixJavaGateway.readinessProbe.tcpSocket.port | string | `"zabbix-jmx"` | Name of port for readinessProbe |
| zabbixJavaGateway.readinessProbe.initialDelaySeconds | int | `10` | Initial delay seconds for readinessProbe |
| zabbixJavaGateway.readinessProbe.timeoutSeconds | int | `3` | Timeout seconds for readinessProbe |
| zabbixJavaGateway.readinessProbe.failureThreshold | int | `3` | Failure threshold for readinessProbe |
| zabbixJavaGateway.readinessProbe.periodSeconds | int | `10` | Period seconds for readinessProbe |
| zabbixJavaGateway.readinessProbe.successThreshold | int | `1` | Success threshold for readinessProbe |
| zabbixJavaGateway.startupProbe.enabled | string | `"true"` | Enable startupProbe on Zabbix Java gateway containers |
| zabbixJavaGateway.startupProbe.tcpSocket.port | string | `"zabbix-jmx"` | Name of port for startupProbe |
| zabbixJavaGateway.startupProbe.initialDelaySeconds | int | `30` | Initial delay seconds for startupProbe |
| zabbixJavaGateway.startupProbe.timeoutSeconds | int | `3` | Timeout seconds for startupProbe |
| zabbixJavaGateway.startupProbe.failureThreshold | int | `5` | Failure threshold for startupProbe |
| zabbixJavaGateway.startupProbe.periodSeconds | int | `10` | Period seconds for startupProbe |
| zabbixJavaGateway.startupProbe.successThreshold | int | `1` | Success threshold for startupProbe |
| zabbixJavaGateway.service.annotations | object | `{}` |  Zabbix Java gateway data Service label annotations |
| zabbixJavaGateway.service.labels | object | `{}` | Zabbix Java gateway data Service labels |
| zabbixJavaGateway.service.type | string | `"ClusterIP"` | Type of service for Zabbix Java gateway |
| zabbixJavaGateway.service.port | int | `10052` | Port to expose service |
| zabbixJavaGateway.service.externalIPs | list | `[]` | External IPs for Zabbix Java gateway |
| zabbixJavaGateway.service.loadBalancerIP | string | `""` | Zabbix Java gateway service Load Balancer IP |
| zabbixJavaGateway.service.loadBalancerSourceRanges | list | `[]` | Zabbix Java gateway service Load Balancer sources |
| zabbixJavaGateway.service.loadBalancerClass | string | `""` | Zabbix Java gateway service Load Balancer Class |

### `agent.volumes_host`

The following directories will be mounted from the host inside the pod:

Host | Pod
---- | ----
`/` | `/hostfs`
`/sys` | `/hostfs/sys`
`/proc` | `/hostfs/proc`
