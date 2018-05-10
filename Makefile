.DEFAULT_GOAL := comply
GO_SOURCES := $(shell find . -name '*.go')
THEME_SOURCES := $(shell find themes)
VERSION := $(shell git describe --tags --always --dirty="-dev")
LDFLAGS := -ldflags='-X "cli.Version=$(VERSION)"'

assets: $(THEME_SOURCES)
	go-bindata-assetfs -pkg theme -prefix themes themes/...
	mv bindata_assetfs.go internal/theme/themes_bindata.go

comply: assets $(GO_SOURCES)
	go build github.com/strongdm/comply/cmd/comply

dist: clean
	mkdir dist
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/comply-$(VERSION)-darwin-amd64 github.com/strongdm/comply/cmd/comply
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build $(LDFLAGS) -o dist/comply-$(VERSION)-linux-amd64 github.com/strongdm/comply/cmd/comply

clean:
	rm -rf dist
	rm -f comply

install: assets $(GO_SOURCES)
	go install github.com/strongdm/comply/cmd/comply

export-example:
	cp example/narratives/* themes/comply-soc2/narratives
	cp example/procedures/* themes/comply-soc2/procedures
	cp example/policies/* themes/comply-soc2/policies
	cp example/standards/* themes/comply-soc2/standards
	cp example/templates/* themes/comply-soc2/templates

docker:
	cd build && docker build -t strongdm/pandoc .
	docker tag jagregory/pandoc:latest strongdm/pandoc:latest
	docker push strongdm/pandoc

cleanse:
	git checkout --orphan newbranch
	git add -A
	git commit -m "Initial commit"
	git branch -D master
	git branch -m master
	git push -f origin master
	git gc --aggressive --prune=all

release: dist gh-release
	github-release release \
	--security-token $$GH_LOGIN \
	--user strongdm \
	--repo comply \
	--tag $(VERSION) \
	--name $(VERSION)

	github-release upload \
	--security-token $$GH_LOGIN \
	--user strongdm \
	--repo comply \
	--tag $(VERSION) \
	--name comply-$(VERSION)-darwin-amd64 \
	--file dist/comply-$(VERSION)-darwin-amd64

	github-release upload \
	--security-token $$GH_LOGIN \
	--user strongdm \
	--repo comply \
	--tag $(VERSION) \
	--name comply-$(VERSION)-linux-amd64 \
	--file dist/comply-$(VERSION)-linux-amd64

gh-release:
	go get -u github.com/aktau/github-release