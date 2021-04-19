# Testing for secret/configmap errors.

Running on regular channel (1.18.16-gke.502).

We are looking for errors like

```
2021-04-02T21:53:35Z MountVolume.SetUp failed for volume "gke-metrics-agent-token-jc2fb" : failed to sync secret cache: timed out waiting for the condition
2021-04-02T21:53:35Z MountVolume.SetUp failed for volume "gke-metrics-agent-config-vol" : failed to sync 
```

On cluster startup there were a couple of cache errors for pdcsi-node-sa-token
(just `nestedpendingoperaion.go`), but that's all.

Our conclusion is that it the error is due to the tight timeout for syncing the
secret cache in
[watch_based_manager.go](https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/util/manager/watch_based_manager.go#L189).
It is not hard to generate the errors, even from kubectl on the command
line. Unless jobs are not starting at all, it seems to be safe to ignore errors
of this sort.

### One pod

Applying `single-pod.yaml` produced some `secret "test" not found` errors, but
nothing about a cache.

### Lots of pods
Running `lots-o-pods.sh` caused some timeouts in kubectl for hitting the api
server. 2 minutes into the second try with this, I started seeing the errors:

```
MountVolume.SetUp failed for volume "config" : failed to sync configmap cache: timed out waiting for the condition
MountVolume.SetUp failed for volume "secret" : failed to sync secret cache: timed out waiting for the condition
```

These were associated with pods 90 and 97. The api server timeouts happened
around pod 59 (as a result pods, secrets and configmap 60-62 didn't get
created). No cache sync errors were reported earlier than 90. There was also an
error for gke-metrics-agent trying to get a secret as well.

The pods all successfully started running with 10s, however.

```
  Normal   Scheduled    6m55s  default-scheduler                                Successfully assigned default/test-090 to gke-regular-default-pool-bc0a9cea-g352
  Warning  FailedMount  6m53s  kubelet, gke-regular-default-pool-bc0a9cea-g352  MountVolume.SetUp failed for volume "config" : failed to sync configmap cache: timed out waiting for the condition
  Warning  FailedMount  6m53s  kubelet, gke-regular-default-pool-bc0a9cea-g352  MountVolume.SetUp failed for volume "secret" : failed to sync secret cache: timed out waiting for the condition
  Normal   Pulling      6m43s  kubelet, gke-regular-default-pool-bc0a9cea-g352  Pulling image "busybox"
  Normal   Pulled       6m43s  kubelet, gke-regular-default-pool-bc0a9cea-g352  Successfully pulled image "busybox"
  Normal   Created      6m42s  kubelet, gke-regular-default-pool-bc0a9cea-g352  Created container test
  Normal   Started      6m39s  kubelet, gke-regular-default-pool-bc0a9cea-g352  Started container test
```
