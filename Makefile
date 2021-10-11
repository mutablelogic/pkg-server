# Paths to packages
GO=$(shell which go)
SED=$(shell which sed)

# Modules
SERVER_MODULE = "github.com/mutablelogic/go-server"
SQLITE3_MODULE = "github.com/mutablelogic/go-sqlite"
MQTT_MODULE = "github.com/mutablelogic/go-mosquitto"
MEDIA_MODULE = "github.com/mutablelogic/go-media"

# Paths to locations, etc
BUILD_DIR = "build"
BUILD_VERSION = $(shell git describe --tags)
BUILD_ARCH = $(shell $(GO) env GOARCH)
BUILD_PLATFORM = $(shell $(GO) env GOOS)

# Add linker flags
BUILD_LD_FLAGS += -X $(SERVER_MODULE)/pkg/version.GitSource=${SERVER_MODULE}
BUILD_LD_FLAGS += -X $(SERVER_MODULE)/pkg/version.GitTag=${BUILD_VERSION}
BUILD_LD_FLAGS += -X $(SERVER_MODULE)/pkg/version.GitBranch=$(shell git name-rev HEAD --name-only --always)
BUILD_LD_FLAGS += -X $(SERVER_MODULE)/pkg/version.GitHash=$(shell git rev-parse HEAD)
BUILD_LD_FLAGS += -X $(SERVER_MODULE)/pkg/version.GoBuildTime=$(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
BUILD_FLAGS = -ldflags "-s -w $(BUILD_LD_FLAGS)" 

# make all will create all debian packages
all: clean nfpm server \
	go-server-httpserver-deb \
	go-server-template-deb \
	go-server-ldapauth-deb \
	go-server-sqlite3-deb \
	go-server-ddregister-deb \
	go-server-mdns-deb \
	go-server-media-deb

# "make server" will just compile the server binary
server: dependencies
	@echo Build server
	@${GO} get ${SERVER_MODULE}
	@${GO} get github.com/djthorpe/go-errors
	@${GO} get github.com/djthorpe/go-marshaler
	@${GO} get github.com/hashicorp/go-multierror
	@${GO} get gopkg.in/yaml.v3
	@${GO} build -o ${BUILD_DIR}/server ${BUILD_FLAGS} ${SERVER_MODULE}/cmd/server

# "make plugin-httpserver" will compile the httpserver plugin
plugin-httpserver: dependencies
	@echo Build plugin-httpserver
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/httpserver.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/httpserver

# "make plugin-log" will compile the log plugin
plugin-log: dependencies
	@echo Build plugin-log
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/log.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/log

# "make plugin-env" will compile the env plugin
plugin-env: dependencies
	@echo Build plugin-env
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/env.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/env

# "make plugin-static" will compile the static plugin
plugin-static: dependencies
	@echo Build plugin-static
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/static.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/static

# "make plugin-basicauth" will compile the basicauth plugin
plugin-basicauth: dependencies
	@echo Build plugin-basicauth
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/basicauth.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/basicauth

# "make plugin-ldapauth" will compile the ldapauth plugin
plugin-ldapauth: dependencies
	@echo Build plugin-ldapauth
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/ldapauth.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/ldapauth

# "make plugin-template" will compile the template plugin and renderers
plugin-template: dependencies
	@echo Build plugin-template
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/template.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/template
	@echo Build plugin-renderer
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/renderer.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/renderer
	@echo Build plugin-dir-renderer
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/dir-renderer.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/dir-renderer
	@echo Build plugin-text-renderer
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/text-renderer.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/text-renderer
	@echo Build plugin-markdown-renderer
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/markdown-renderer.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/markdown-renderer
	@echo Build plugin-zip-renderer
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/zip-renderer.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/zip-renderer

# "make plugin-ddregister" will compile the ddregister plugin
plugin-ddregister: dependencies
	@echo Build plugin-ddregister
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/ddregister.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/ddregister

# "make plugin-mdns" will compile the mdns plugin
plugin-mdns: dependencies
	@echo Build plugin-mdns
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/mdns.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/mdns

# "make plugin-sqlite3" will compile the sqlite3 plugin
plugin-sqlite3: dependencies
	@echo Build plugin-sqlite3
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/sqlite3.plugin ${BUILD_FLAGS} ${SQLITE3_MODULE}/plugin/sqlite3
	@echo Build plugin-indexer
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/indexer.plugin ${BUILD_FLAGS} ${SQLITE3_MODULE}/plugin/indexer

# "make plugin-mqtt" will compile the mqtt plugin
plugin-mqtt: dependencies
	@echo Build plugin-mqtt
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/mqtt.plugin ${BUILD_FLAGS} ${MQTT_MODULE}/plugin/mqtt

# "make plugin-media" will compile the media plugin
plugin-media: dependencies
	@echo Build plugin-media
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/media.plugin ${BUILD_FLAGS} ${MEDIA_MODULE}/plugin/media

# "make go-server-httpserver-deb" will package the go-server-httpserver.deb
go-server-httpserver-deb: plugin-httpserver plugin-log plugin-env plugin-static plugin-basicauth
	@echo Package go-server-httpserver deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-httpserver/nfpm.yaml > $(BUILD_DIR)/go-server-httpserver-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-httpserver-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-ldapauth-deb" will package the go-server-ldapauth.deb
go-server-ldapauth-deb: plugin-ldapauth
	@echo Package go-server-ldapauth deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-ldapauth/nfpm.yaml > $(BUILD_DIR)/go-server-ldapauth-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-ldapauth-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-template-deb" will package the go-server-template.deb
go-server-template-deb: plugin-template
	@echo Package go-server-template deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-template/nfpm.yaml > $(BUILD_DIR)/go-server-template-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-template-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-sqlite3-deb" will package the go-server-sqlite3.deb
go-server-sqlite3-deb: plugin-sqlite3
	@echo Package go-server-sqlite3 deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-sqlite3/nfpm.yaml > $(BUILD_DIR)/go-server-sqlite3-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-sqlite3-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-mqtt-deb" will package the go-server-mqtt.deb
go-server-mqtt-deb: plugin-mqtt
	@echo Package go-server-mqtt deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-mqtt/nfpm.yaml > $(BUILD_DIR)/go-server-mqtt-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-mqtt-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-ddregister-deb" will package the go-server-ddregister.deb
go-server-ddregister-deb: plugin-ddregister
	@echo Package go-server-ddregister deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-ddregister/nfpm.yaml > $(BUILD_DIR)/go-server-ddregister-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-ddregister-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-mdns-deb" will package the go-server-mdns.deb
go-server-mdns-deb: plugin-mdns
	@echo Package go-server-mdns deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-mdns/nfpm.yaml > $(BUILD_DIR)/go-server-mdns-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-mdns-nfpm.yaml --packager deb --target $(BUILD_DIR)

# "make go-server-media-deb" will package the go-server-media.deb
go-server-media-deb: plugin-media
	@echo Package go-server-media deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-media/nfpm.yaml > $(BUILD_DIR)/go-server-media-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-media-nfpm.yaml --packager deb --target $(BUILD_DIR)

# make nfpm will build the deb packager
nfpm: FORCE
	@echo Installing nfpm
	@${GO} mod tidy -compat=1.17
	@${GO} install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.3.1	

dependencies: mkdir
ifeq (,${GO})
        $(error "Missing go binary")
endif
ifeq (,${SED})
        $(error "Missing sed binary")
endif

mkdir:
	@echo Mkdir
	@install -d ${BUILD_DIR}

clean:
	@echo Clean
	@rm -fr $(BUILD_DIR)
	@${GO} mod tidy -compat=1.17

FORCE:
