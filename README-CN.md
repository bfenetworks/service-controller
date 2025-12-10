# service-controller

中文 | [English](./README.md)

`service-controller` 是一个 Kubernetes 控制器，用于实现基于 Kubernetes Service 资源的 BFE (Beyond Front End) 7层服务自动发现与配置。该控制器持续监控集群中的 Service 资源变化，自动将符合条件的服务注册到 BFE 配置中，实现服务流量的无缝接入与管理。

## 特性

- **多架构支持**：同时支持 x86_64 和 ARM64 架构
- **轻量级基础镜像**：基于 Alpine 构建，体积小，安全性高
- **精细的服务过滤**：支持 namespace 过滤需要处理的 Kubernetes 服务
- **多产品线支持**：支持不同业务线的 BFE 集群配置隔离
- **多端口支持**：支持单个 Service 定义多个端口映射到 多个BFE实例池
- **完善的监控**：
  - Readiness 探针：确保控制器准备就绪后才接收流量
  - Liveness 探针：自动检测并恢复异常状态
- **操作审计**：
  - 操作结果记录为 ConfigMap，便于审计和回溯
  - 操作状态记录为 Kubernetes Event，便于集成现有监控系统
- **其它**：
  - 支持自定义重试间隔，适应不同的网络环境和负载情况

## 快速开始

### 前提条件

- Kubernetes 集群 (v1.18+)
- kubectl 配置正确
- [BFE API Server](https://github.com/bfenetworks/api-server)已部署并可访问

### 部署控制器

```bash
# 克隆仓库
git clone https://github.com/bfenetworks/service-controller.git
cd service-controller

# 应用部署清单
kubectl apply -f ./examples/service-controller-endpoints.yaml
```

### 验证部署

```bash
kubectl get deployment bfe-service-controller
kubectl get pods 

```

## 配置说明

### 控制器配置
请参考 [./examples/service-controller-endpoints.yaml](./examples/service-controller-endpoints.yaml).

注意点：
- 可以根据实际场景，修改image的源
- 请根据api server的地址，修改bfe-api-addr
- 请根据api server的token配置，修改bfe-api-token
  - 在API servr上，可通过如下方式获得Token `System View / User Manage / Token`
  
### Service 注解
通过在 Service 上添加特定标签，控制器会自动将其注册到 BFE

注意点：
- labels中增加 `bfe-product` 指明对应的BFE 产品线
- ports中的port name必须指定

请参考 [./examples/whoami_alb.yaml](./examples/whoami_alb.yaml)

下面是一个demo
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

## 监控与运维

### 健康检查

控制器提供标准的 Kubernetes 健康检查端点：

- **Readiness 检查**：`GET /ready` - 检查控制器是否准备好处理请求
- **Liveness 检查**：`GET /healthz` - 检查控制器是否健康运行

### 操作审计
控制器将关键操作记录在两个地方：
1. **Result ConfigMap**：包含最新一次成功应用的 BFE 配置
   ```bash
   kubectl get configmap whoami.result -o yaml
   ```

2. **Kubernetes Events**：记录重要状态变化


## 构建项目

### 构建要求

- Go 1.21+
- Docker

### 构建命令
```bash
# 构建二进制
sh build/build.sh

# 构建 Docker 镜像 (当前架构)
sh docker-build.sh release

```

注意:
- 为了顺利构建，可能需要配置 GOPROXY. eg:

```
GO111MODULE=on GOPROXY=https://goproxy.cn,direct go mod download
```

## 具体使用例子

### 前置条件

#### 配置 examples/service-controller-endpoints.yaml
- 服务地址: `http://172.18.1.244:8183`
- Token为: `Token xCFZgmV02dzD3lWTlRvN'`
- 监听的k8s namespace: `open-bfe-demo`
- k8s的集群名为: `szyf`
- 镜像地址. 请参考 [service-controller image](https://github.com/bfenetworks/service-controller/pkgs/container/service-controller)

注意:
- 请根据您的实际环境，修改上述配置的值。

### 配置 examples/whoami_alb.yaml
- 已经在api server上创建好产品线  `demo`

### 部署service controller

```
#部署service controller
$kubectl apply -f examples/service-controller-endpoints.yaml

#查看部署状态
$kubectl get pods
NAME                                     READY   STATUS                   RESTARTS       AGE
bfe-service-controller-64c6bf9f8d-bgkch   1/1     Running                  0              8m41s

#查看日志
$kubectl logs bfe-service-controller-64c6bf9f8d-bgkch
...
```

### 部署7层服务

```
#部署7层服务
$ kubectl apply -f examples/whoami_alb.yaml

#查看部署结果(在api server的website中能看到对应的实例池)
$kubectl get configmap whoami.result -n open-bfe-demo -o yaml
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

### 删除7层服务
```
#删除7层服务
$ kubectl delete -f examples/whoami_alb.yaml

#成功删除后，对应的result configmap也删除
$kubectl get configmap whoami.result -n open-bfe-demo -o yaml
Error from server (NotFound): configmaps "whoami.result" not found

```