# Paths to packages
GO=$(shell which go)
SED=$(shell which sed)

# Modules
SERVER_MODULE = "github.com/mutablelogic/go-server"
SQLITE3_MODULE = "github.com/mutablelogic/go-sqlite"
MQTT_MODULE = "github.com/mutablelogic/go-mosquitto"

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
all: clean dependencies nfpm go-server-httpserver-deb go-server-sqlite3-deb go-server-mqtt-deb 

# make server will just compile the server binary
server: dependencies mkdir
	@echo Build server
	@${GO} get ${SERVER_MODULE}
	@${GO} get github.com/djthorpe/go-errors
	@${GO} get github.com/djthorpe/go-marshaler
	@${GO} get github.com/hashicorp/go-multierror
	@${GO} get gopkg.in/yaml.v3
	@${GO} build -o ${BUILD_DIR}/server ${BUILD_FLAGS} ${SERVER_MODULE}/cmd/server

# make plugin-httpserver will compile the httpserver plugin
plugin-httpserver: dependencies mkdir server
	@echo Build plugin-httpserver
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/httpserver.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/httpserver

# make plugin-log will compile the log plugin
plugin-log: dependencies mkdir server
	@echo Build plugin-log
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/log.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/log

# make plugin-env will compile the env plugin
plugin-env: dependencies mkdir server
	@echo Build plugin-env
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/env.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/env

# make plugin-static will compile the static plugin
plugin-static: dependencies mkdir server
	@echo Build plugin-static
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/static.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/static

# make plugin-basicauth will compile the basicauth plugin
plugin-basicauth: dependencies mkdir server
	@echo Build plugin-basicauth
	@${GO} get github.com/GehirnInc/crypt/apr1_crypt
	@${GO} get golang.org/x/crypto/bcrypt
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/basicauth.plugin ${BUILD_FLAGS} ${SERVER_MODULE}/plugin/basicauth

# "make plugin-sqlite3" will compile the sqlite3 plugin
plugin-sqlite3: dependencies mkdir server
	@echo Build plugin-sqlite3
	@${GO} get ${SQLITE3_MODULE}
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/sqlite3.plugin ${BUILD_FLAGS} ${SQLITE3_MODULE}/plugin/sqlite3

# "make plugin-mqtt" will compile the mqtt plugin
plugin-mqtt: dependencies mkdir server
	@echo Build plugin-mqtt
	@${GO} get ${MQTT_MODULE}
	@${GO} build -buildmode=plugin -o ${BUILD_DIR}/mqtt.plugin ${BUILD_FLAGS} ${MQTT_MODULE}/plugin/mqtt

# "make go-server-httpserver-deb" will package the go-server-httpserver.deb
go-server-httpserver-deb: plugin-httpserver plugin-log plugin-env plugin-static plugin-basicauth
	@echo Package go-server-httpserver deb
	@${SED} \
		-e 's/^version:.*$$/version: $(BUILD_VERSION)/'  \
		-e 's/^arch:.*$$/arch: $(BUILD_ARCH)/' \
		-e 's/^platform:.*$$/platform: $(BUILD_PLATFORM)/' \
		nfpm/go-server-httpserver/nfpm.yaml > $(BUILD_DIR)/go-server-httpserver-nfpm.yaml
	@nfpm pkg -f $(BUILD_DIR)/go-server-httpserver-nfpm.yaml --packager deb --target $(BUILD_DIR)

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

# make nfpm will build the deb packager
nfpm:
	@echo Installing nfpm
	@${GO} mod tidy
	@${GO} install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.3.1	

dependencies:
ifeq (,${GO})
        $(error "Missing go binary")
endif
ifeq (,${SED})
        $(error "Missing sed binary")
endif

mkdir:
	@install -d ${BUILD_DIR}

clean:
	@rm -fr $(BUILD_DIR)
