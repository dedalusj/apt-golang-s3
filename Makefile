PACKAGE_NAME=apt-golang-s3
BINARY_NAME=s3

VERSION=`git describe --abbrev=0 --tags`
VERSION_SLUG=$(shell echo $(VERSION) | tr -d v)
BUILD=`date +%FT%T%z`

LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.Build=$(BUILD)"

# debian packaging vars
VERSION_DEBIAN=$(shell echo $(VERSION) | cut -d '_' -f1 | tr -d v)
DEBIAN_PATH=./usr/lib/apt/methods
DEBIAN_LOGROTATE_PATH=./etc/logrotate.d
ROOT_DEBIAN_PATH=./debian
TEMP_DEBIAN_PATH=${ROOT_DEBIAN_PATH}/${PACKAGE_NAME}-${VERSION}

.PHONY: fmt
fmt:
	@go fmt ./...

.PHONY: tidy
tidy:
	go mod tidy

.PHONY: test
test:
	go test -v -race ./...

.PHONY: cover
cover:
	@go test -v ./... -coverprofile=coverage.out -count=1

.PHONY: cover-html
cover-html:
	@go test -v ./... -coverprofile=coverage.out
	@go tool cover -html=coverage.out
	@rm coverage.out

.PHONY: build
build: test
	@go build $(LDFLAGS) -o $(BINARY_NAME)

.PHONY: dev
dev: build
	./$(BINARY_NAME)

.PHONY: build_linux64
build_linux64:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o ./$(BINARY_NAME) -v

.PHONY: build_debian
build_debian: build_linux64
	cd ${ROOT_DEBIAN_PATH}; mkdir ${PACKAGE_NAME}-${VERSION}
	cd ${TEMP_DEBIAN_PATH}; cp -r ../DEBIAN/ ./DEBIAN
	cd ${TEMP_DEBIAN_PATH}; mkdir -p ${DEBIAN_PATH} ${DEBIAN_LOGROTATE_PATH}
	cp ./${BINARY_NAME} ${TEMP_DEBIAN_PATH}/${DEBIAN_PATH}/${BINARY_NAME}
	cp ${ROOT_DEBIAN_PATH}/logrotate-apt-s3.conf ${TEMP_DEBIAN_PATH}/${DEBIAN_LOGROTATE_PATH}/apt-s3
	cd ${TEMP_DEBIAN_PATH}/DEBIAN; sed -i "s/0.0.0/${VERSION_DEBIAN}/g" control
	cd ${ROOT_DEBIAN_PATH}; dpkg-deb --root-owner-group --build ${PACKAGE_NAME}-${VERSION}
	mv ${ROOT_DEBIAN_PATH}/${PACKAGE_NAME}-${VERSION}.deb ./${PACKAGE_NAME}-${VERSION}.deb
	rm -rf ${TEMP_DEBIAN_PATH}

.PHONY: show-ver-tag
show-ver-tag:
	@echo "${VERSION}"

.PHONY: show-ver-no-rev
show-ver-no-rev:
	@echo "${VERSION}" | cut -f1 -d"_" | tr -d v
