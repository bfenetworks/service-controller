# service-controller

English | [中文](./README-CN.md)

`service-controller` is a Kubernetes controller designed to enable automatic discovery and configuration of BFE (Beyond Front End) Layer 7 services based on Kubernetes Service resources. The controller continuously monitors changes to Service resources in the cluster and automatically registers eligible services into BFE configurations, enabling seamless traffic integration and management.

## Features

- **Multi-architecture support**: Compatible with both x86_64 and ARM64 architectures.
- **Lightweight base image**: Built on Alpine for minimal size and enhanced security.
- **Granular service filtering**: Supports namespace-based filtering of Kubernetes Services to process.
- **Multi-product-line support**: Enables isolated BFE cluster configurations for different business lines.
- **Multi-port support**: Allows a single Service defined multiple ports map to multiple BFE instance pools.
- **Comprehensive monitoring**:
  - **Readiness probe**: Ensures the controller only receives traffic after it is fully ready.
  - **Liveness probe**: Automatically detects and recovers from abnormal states.
- **Operation auditing**:
  - Operation results are recorded as ConfigMaps for easy auditing and traceability.
  - Operation statuses are logged as Kubernetes Events for seamless integration with existing monitoring systems.
- **Other**:
  - Customizable retry intervals to adapt to varying network conditions and workloads.

## Quick Start

### Prerequisites

- Kubernetes cluster (v1.18+)
- Properly configured `kubectl`
- [BFE API Server](https://github.com/bfenetworks/api-server) deployed and accessible

### Deploy the Controller

```bash
# Clone the repository
git clone https://github.com/bfenetworks/service-controller.git
cd service-controller

# Apply the deployment manifest
kubectl apply -f ./examples/service-controller-endpoints.yaml
```

### Verify Deployment

```bash
kubectl get deployment bfe-service-controller
kubectl get pods
```

## Configuration Guide

### Controller Configuration  
Refer to [./examples/service-controller-endpoints.yaml](./examples/service-controller-endpoints.yaml).

Notes:
- Modify the container image source according to your environment.
- Update `bfe-api-addr` to match your API server address.
- Set `bfe-api-token` based on your API server token configuration.
  - Get token by `System View / User Manage / Token` from API servr.

### Service Label  
The controller automatically registers Services annotated with specific labels into BFE.

Notes:
- Add the label `bfe-product` to specify the corresponding BFE product line.
- The `name` field in each port definition must be explicitly set.

See [./examples/whoami_alb.yaml](./examples/whoami_alb.yaml) for reference.

Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: open-bfe-demo
  labels:
    bfe-product: demo
spec:
  ports:
    - name: http
      port: 8080
      targetPort: 80
  selector:
    app.kubernetes.io/name: whoami
```

## Monitoring & Operations

### Health Checks

The controller exposes standard Kubernetes health check endpoints:

- **Readiness Check**: `GET /ready` – verifies if the controller is ready to handle requests.
- **Liveness Check**: `GET /healthz` – checks whether the controller is running healthily.

### Operation Auditing

Key operations are recorded in two locations:

1. **Result ConfigMap**: Contains the most recently applied successful BFE configuration.
   ```bash
   kubectl get configmap whoami.result -n open-bfe-demo -o yaml
   ```

2. **Kubernetes Events**: Logs significant status changes.

## Building the Project

### Build Requirements

- Go 1.21+
- Docker

### Build Commands

```bash
# Build binary
sh build/build.sh

# Build Docker image (for current architecture)
sh docker-build.sh release

```
Note:
- It may need to set GOPROXY to build. eg:
```
GO111MODULE=on GOPROXY=https://goproxy.cn,direct go mod download
```

## Usage Example

### Prerequisites

#### Setup examples/service-controller-endpoints.yaml
- API Server URL: `http://172.18.1.244:8183`
- Token: `Token xCFZgmV02dzD3lWTlRvN'`
- Monitored namespace: `open-bfe-demo`
- Kubernetes cluster name: `szyf`
- image has been set properly. Please refer to [service-controller image](https://github.com/bfenetworks/service-controller/pkgs/container/service-controller)

#### Setup for examples/whoami_alb.yaml
- Product `demo` has been created in the API Server.

### Deploy the Service Controller

```bash
# Deploy service controller
$ kubectl apply -f examples/service-controller-endpoints.yaml

# Check deployment status
$ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
bfe-service-controller-64c6bf9f8d-bgkch   1/1     Running   0          8m41s

# View logs
$ kubectl logs bfe-service-controller-64c6bf9f8d-bgkch
...
```

### Deploy a Layer 7 Service

```bash
# Deploy Layer 7 service
$ kubectl apply -f examples/whoami_alb.yaml

# Verify deployment result (the corresponding instance pool should appear in the API Server web UI)
$ kubectl get configmap whoami.result -n open-bfe-demo -o yaml
apiVersion: v1
data:
  result: Succ
  timestamp: "2025-12-01 08:38:24.786"
kind: ConfigMap
metadata:
  creationTimestamp: "2025-12-01T08:38:23Z"
  labels:
    extra-msg: update
    bfe-cm-result: "yes"
    bfe-result-type: service
  name: whoami.result
  namespace: open-bfe-demo
  resourceVersion: "65652526"
  uid: 8b09c258-c87b-4e17-afc3-ed5f57a4dde9
```

### Delete the Layer 7 Service

```bash
# Delete Layer 7 service
$ kubectl delete -f examples/whoami_alb.yaml

# After successful deletion, the corresponding result ConfigMap is also removed
$ kubectl get configmap whoami.result -n open-bfe-demo -o yaml
Error from server (NotFound): configmaps "whoami.result" not found
```
