VOTER_IMG=voter
BALLOT_IMG=ballot
ECSVR_IMG=ecserver
TEST_IMG=service-test-suite
EC_IMG=election-commission
ifndef IMAGE_TAG
  IMAGE_TAG=latest
endif
CLUSTER_IP := $(shell ping -W2 -n -q -c1 current-cluster-roost.io  2> /dev/null | awk -F '[()]' '/PING/ { print $$2}')
DOCKER_HOST_ARG=
ifdef DOCKER_HOST
	DOCKER_HOST_ARG= -H ${DOCKER_HOST}
endif

# HOSTNAME := $(shell hostname)
.PHONY: all
all: dockerise helm-deploy

.PHONY: test
test: test-ballot test-voter test-ecserver

.PHONY: test-ballot
test-ballot:
	echo "Test Ballot"
	docker run --network="host" --rm -it -v ${PWD}/ballot/test:/scripts \
   zbio/artillery-custom \
   run -e unit /scripts/test.yaml

.PHONY: test-voter
test-voter:
	echo "Test Voter"
	mkdir -p /var/tmp/test
	mkdir -p /var/tmp/test/cypress
	mkdir -p /var/tmp/test/cypress/integration
	echo '{"reporter": "junit","reporterOptions": {"mochaFile": "results/my-test-output-[hash].xml"}}' > /var/tmp/test/cypress.json
	cp ${PWD}/service-test-suite/voter/voter.spec.js /var/tmp/test/cypress/integration
	docker run --network="host"  -v /var/tmp/test:/e2e -w /e2e cypress/included:6.2.1 --browser firefox

.PHONY: test-ecserver
test-ecserver:
	echo "Test ECserver"
	docker run --network="host" --rm -it -v ${PWD}/ecserver/test:/scripts \
   zbio/artillery-custom \
   run -e unit /scripts/test.yaml

.PHONY: pre-dockerise
pre-dockerise:
	docker pull golang:1.19.3-alpine3.16
	docker pull alpine:3.16
	docker pull node:14.21.1-alpine3.16
	docker pull nginx:stable-alpine

.PHONY: dockerise
dockerise: pre-dockerise build-voter build-ballot build-ecserver build-ec build-test

.PHONY: build-ballot
build-ballot:
	docker ${DOCKER_HOST_ARG} build -t ${BALLOT_IMG}:${IMAGE_TAG} -f ballot/Dockerfile ballot

.PHONY: build-voter
build-voter:
	docker ${DOCKER_HOST_ARG} build -t ${VOTER_IMG}:${IMAGE_TAG} -f voter/Dockerfile voter

.PHONY: build-ecserver
build-ecserver:
	docker ${DOCKER_HOST_ARG} build -t ${ECSVR_IMG}:${IMAGE_TAG} -f ecserver/Dockerfile ecserver

.PHONY: build-test
build-test:
	docker ${DOCKER_HOST_ARG} build -t ${TEST_IMG}:${IMAGE_TAG} -f service-test-suite/Dockerfile service-test-suite

.PHONY: build-ec
build-ec:
	docker ${DOCKER_HOST_ARG} build -t ${EC_IMG}:${IMAGE_TAG} -f election-commission/Dockerfile election-commission
		
.PHONY: push
push:
	docker tag ${BALLOT_IMG}:${IMAGE_TAG} zbio/${BALLOT_IMG}:${IMAGE_TAG}
	docker push zbio/${BALLOT_IMG}:${IMAGE_TAG}
	docker tag ${VOTER_IMG}:${IMAGE_TAG} zbio/${VOTER_IMG}:${IMAGE_TAG}
	docker push zbio/${VOTER_IMG}:${IMAGE_TAG}
	docker tag ${ECSVR_IMG}:${IMAGE_TAG} zbio/${ECSVR_IMG}:${IMAGE_TAG}
	docker push zbio/${ECSVR_IMG}:${IMAGE_TAG}
	docker tag ${EC_IMG}:${IMAGE_TAG} zbio/${EC_IMG}:${IMAGE_TAG}
	docker push zbio/${EC_IMG}:${IMAGE_TAG}
	docker tag ${TEST_IMG}:${IMAGE_TAG} zbio/${TEST_IMG}:${IMAGE_TAG}
	docker push zbio/${TEST_IMG}:${IMAGE_TAG}

.PHONY: deploy
deploy:
	kubectl apply -f ecserver/ecserver.yaml
	kubectl apply -f ballot/ballot.yaml
	kubectl apply -f voter/voter.yaml
	kubectl apply -f service-test-suite/test-suite.yaml
	kubectl apply -f election-commission/ec.yaml
	kubectl apply -f ingress.yaml
	
.PHONY: helm-deploy
helm-deploy: 
ifeq ($(strip $(CLUSTER_IP)),)
	@echo "UNKNOWN_CLUSTER_IP: failed to resolve current-cluster-roost.io to an valid IP"
	@exit 1;
endif
		helm install vote helm-vote --set clusterIP=$(CLUSTER_IP)
		
.PHONY: generate
generate:
	helm template helm-vote --output-dir generated-files

.PHONY: helm-undeploy
helm-undeploy:
		-helm uninstall vote

.PHONY: clean
clean: helm-undeploy
	-kubectl delete -f service-test-suite/test-suite.yaml
	-kubectl delete -f voter/voter.yaml
	-kubectl delete -f ballot/ballot.yaml
	-kubectl delete -f ecserver/ecserver.yaml
	-kubectl delete -f election-commission/ec.yaml
	-kubectl delete -f generated-files
	-rm -rf generated-files  
