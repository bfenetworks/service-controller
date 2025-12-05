# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [v1.0.0] - 2025-12-05

### Added

* Add initial implementation of service-controller: automatically discover and register Kubernetes Service resources into BFE Layer-7 service configuration. 
* Support multi-architecture builds (x86_64 and ARM64). 
* Provide lightweight base image (Alpine) to minimize size and improve container security. 
* Enable namespace-based filtering: allow controller to monitor only Services in certain namespaces.
* Support multi-port Services: a single Kubernetes Service can map multiple ports to separate BFE instance pools.
* Support health-checks (readiness and liveness probes) to ensure controller readiness and allow auto recovery. 
* Support operation auditing: controller records configuration application results into ConfigMaps and logs operation statuses as Kubernetes Events for traceability. 
* Provide quick start guide in README. 
* Provide an example deployment manifest (`examples/service-controller-endpoints.yaml`) for easy quick start.
* Provide example YAML (`examples/whoami_alb.yaml`) showing how to define a Service with required annotations/labels for BFE integration.
