NAMESPACE ?= bootc
hadolint_available := $(shell hadolint --help > /dev/null 2>&1; echo $$?)
hadolint_command := hadolint
hadolint_container := ghcr.io/hadolint/hadolint:latest

export BUNDLE_PATH = $(PWD)/.bundle/gems
export BUNDLE_BIN = $(PWD)/.bundle/bin
export GEMFILE = $(PWD)/Gemfile
export DOCKER_BUILDKIT ?= 1

VERSION ?= $(shell awk -F= '$$0 ~ "^ARG version" { print $$2; exit }' puppetserver/Dockerfile)

lint:
ifeq ($(hadolint_available),0)
	@$(hadolint_command) puppetserver/Dockerfile
else
	@docker pull $(hadolint_container)
	@docker run --rm -v $(PWD)/puppetserver/Dockerfile:/Dockerfile \
		-i $(hadolint_container) $(hadolint_command) Dockerfile
endif

build:
	docker buildx build \
		${DOCKER_BUILD_FLAGS} \
		--load \
		--pull \
		--build-arg version=$(VERSION) \
		--file puppetserver/Dockerfile \
		--tag $(NAMESPACE)/puppetserver:$(VERSION) $(PWD)

test:
	@bundle install --path $$BUNDLE_PATH --gemfile $$GEMFILE --with test
	@bundle update
	@PUPPET_TEST_DOCKER_IMAGE=$(NAMESPACE)/puppetserver:$(VERSION) \
		bundle exec --gemfile $$GEMFILE \
		rspec --options puppetserver/.rspec spec

push-image:
	@docker push $(NAMESPACE)/puppetserver:$(VERSION)

push-readme:
	@docker pull sheogorath/readme-to-dockerhub
	@docker run --rm \
		-v $(PWD)/puppetserver/README.md:/data/README.md \
		-e DOCKERHUB_USERNAME="$(DOCKERHUB_USERNAME)" \
		-e DOCKERHUB_PASSWORD="$(DOCKERHUB_PASSWORD)" \
		-e DOCKERHUB_REPO_PREFIX=$(NAMESPACE) \
		-e DOCKERHUB_REPO_NAME=puppetserver \
		sheogorath/readme-to-dockerhub

publish: push-image push-readme

.PHONY: lint build test publish push-image push-readme
