#!/usr/bin/env bash
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -x
set -o errexit
set -o nounset
set -o pipefail

TAG="$1"
BIN_PATH="$2"
OS="$3"
ARCH="$4"

# Fix source date in order to have reproducible builds
export SOURCE_DATE_EPOCH="1635525388"

# Set build time variables including version details
VERSION_LDFLAGS=$(./hack/version.sh)

CGO_ENABLED=0 GOOS=$OS GOARCH=$ARCH \
	go build -trimpath -ldflags "-s -w -buildid=''" -o $BIN_PATH/manager sigs.k8s.io/cluster-api

CGO_ENABLED=0 GOOS=$OS GOARCH=$ARCH \
	go build -trimpath -ldflags "-s -w -buildid=''" -o $BIN_PATH/kubeadm-bootstrap-manager sigs.k8s.io/cluster-api/bootstrap/kubeadm

CGO_ENABLED=0 GOOS=$OS GOARCH=$ARCH \
	go build -trimpath -ldflags "-s -w -buildid=''" -o $BIN_PATH/kubeadm-control-plane-manager sigs.k8s.io/cluster-api/controlplane/kubeadm

CGO_ENABLED=0 GOOS=$OS GOARCH=$ARCH \
	go build -trimpath -ldflags "-s -w -buildid='' $VERSION_LDFLAGS" -o $BIN_PATH/clusterctl sigs.k8s.io/cluster-api/cmd/clusterctl

(cd test/infrastructure/docker && go mod vendor && CGO_ENABLED=0 GOOS=$OS GOARCH=$ARCH \
	go build -trimpath -ldflags "-s -w -buildid=''" -o $BIN_PATH/cluster-api-provider-docker-manager sigs.k8s.io/cluster-api/test/infrastructure/docker)
