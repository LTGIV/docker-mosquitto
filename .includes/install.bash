#!/usr/bin/env bash
: <<'!COMMENT'

Docker : Mosquitto with Authentication v201809022148
Louis T. Getterman IV - https://thad.getterman.org/about

Related:

Tying MQTT, WebSockets, and Nginx together with Docker
https://thad.getterman.org/2017/09/04/tying-mqtt-websockets-and-nginx-together-with-docker

!COMMENT

# Exit on any error
set -e

function setupDirs {

	mkdir -pv \
		/usr/share/doc/mosquitto/examples \
		/usr/lib/mosquitto-auth-plugin/ \
		;

} # END FUNCTION : setupDirs

function setupPrerequisites {

	apt-get -y update \
	&& \
	apt-get -y install \
		\
		atool \
		cmake \
		gcc \
		make \
		pkg-config \
		wget \
		\
		libcurl4-openssl-dev \
		libhiredis-dev \
		libldap2-dev \
		libmysqlclient-dev \
		libpq-dev \
		libsqlite3-dev \
		libssl-dev \
		libsasl2-dev \
		;

} # END FUNCTION : setupPrerequisites

function installMosquittoFromPPA {

	# Needed to add PPA
	apt-get -y install \
		software-properties-common \
		;

	# Install a (sometimes slightly outdated) Mosquitto from PPA
	# Note: you can use `apt-file update` then `apt-file list <package>` to view a package's file destinations.
	apt-add-repository -y ppa:mosquitto-dev/mosquitto-ppa \
	&& \
	apt-get -y update \
	&& \
	apt-get -y install \
		\
		libmosquitto-dev \
		mosquitto \
		mosquitto-clients \
		mosquitto-dev \
		;

	# Mimic Mosquitto's source installation
	if [ -f "/usr/share/doc/mosquitto/examples/mosquitto.conf.gz" ]; then

		atool \
			--extract-to /usr/share/doc/mosquitto/examples/mosquitto.conf.example \
			/usr/share/doc/mosquitto/examples/mosquitto.conf.gz \
		&& \
		rm -rfv $_ \
		;

	fi

} # END FUNCTION : installMosquittoFromPPA

function installLibWS {

	# Download libwebsockets
	downloadPrep "${url_libws}" libwebsockets libwebsockets

	mkdir -pv /usr/local/src/libwebsockets/build \
	&& \
	cd $_ \
	;

	cmake .. \
	&&
	make \
		-j`nproc` \
	&&
	make install \
	&& \
	ldconfig \
	;

} # END FUNCTION : installLibWS

function installMosquittoFromSource {

	installLibWS

	apt-get -y install \
		uuid-dev \
		;

	# Download Mosquitto
	downloadPrep "${url_mosquitto}" mos mqtt

	cd /usr/local/src/mqtt

	make \
		-j`nproc` \
		WITH_WEBSOCKETS=yes \
		;

	make install

	ldconfig

	# Mimic the PPA install's file location
	mv -iv \
		/etc/mosquitto/*.example \
		/usr/share/doc/mosquitto/examples/ \
		;

} # END FUNCTION : installMosquittoFromSource

function installMAP {

	# Compile and install Mongo C
	mkdir -pv /usr/local/src/mongo/cmake-build && cd $_
	cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .. \
				&& \
				make -j`nproc` \
				&& \
				make install \
				;

	# Compile and install Mosquitto Authentication Plugin
	mkdir -pv /usr/local/src/map && cd $_

	# Disable warnings resulting in errors (I couldn't get CFLAGS in config.mk to override this)
	cp -va Makefile Makefile.bak
	sed -i "s/\-Werror//" Makefile

	cp -va config.mk.in config.mk \
		&& \
		sed -i "s/^BACKEND_CDB .*/BACKEND_CDB ?= yes/" config.mk && \
		sed -i "s/^BACKEND_MYSQL .*/BACKEND_MYSQL ?= yes/" config.mk && \
		sed -i "s/^BACKEND_SQLITE .*/BACKEND_SQLITE ?= yes/" config.mk && \
		sed -i "s/^BACKEND_REDIS .*/BACKEND_REDIS ?= yes/" config.mk && \
		sed -i "s/^BACKEND_POSTGRES .*/BACKEND_POSTGRES ?= yes/" config.mk && \
		sed -i "s/^BACKEND_LDAP .*/BACKEND_LDAP ?= yes/" config.mk && \
		sed -i "s/^BACKEND_HTTP .*/BACKEND_HTTP ?= yes/" config.mk && \
		sed -i "s/^BACKEND_JWT .*/BACKEND_JWT ?= yes/" config.mk && \
		sed -i "s/^BACKEND_MONGO .*/BACKEND_MONGO ?= yes/" config.mk && \
		sed -i "s/^BACKEND_FILES .*/BACKEND_FILES ?= yes/" config.mk && \
		\
		sed -i "s/^MOSQUITTO_SRC .*/MOSQUITTO_SRC = \/usr\/include\/mqtt/" config.mk && \
		sed -i "s/^OPENSSLDIR .*/OPENSSLDIR = \/usr\/include\/openssl/" config.mk && \
		\
		make \
			-j`nproc` \
		&& \
		mv -v \
			/usr/local/src/map/auth*.so \
			/usr/lib/mosquitto-auth-plugin/auth-plugin.so \
		&& \
		mv -v \
			/usr/local/src/map/np \
			/usr/bin/ \
		;

	ldconfig

} # END FUNCTION : installMAP

function downloadPrep {

	cd /usr/local/src

	url="$1"
	wc="$2"
	name="$3"

	# Download
	wget -O "${name}" "${url}"

	# Extract
	atool --extract "${name}"

	# Clean
	rm -rfv "${name}"

	# Move
	mv -v "${wc}"* "${name}"

} # END FUNCTION : downloadPrep

function cleanup {

	echo "Image size before clean-up: $( du -smh / 2>/dev/null | awk '{print $1}' )"

	apt-get autoremove --purge --yes > /dev/null 2>&1

	rm -rfv \
		/usr/local/bin/install.bash \
		/usr/local/src/ \
		/var/lib/apt/lists/* \
		/tmp/* \
		>/dev/null 2>&1

	echo "Image size after clean-up: $( du -smh / 2>/dev/null | awk '{print $1}' )"

} # END FUNCTION : cleanup

function setupMosquittoConfig {

	# Clear everything out
	cd /etc/mosquitto/
	rm -rf ..?* .[!.]* *

	# Setup directories
	mkdir -pv \
		/etc/mosquitto/ca_certificates/ \
		/etc/mosquitto/certs/ \
		/etc/mosquitto/conf.d/ \
		;

	# Setup mosquitto.conf
	cat << EOF > /etc/mosquitto/mosquitto.conf
# Place your local configuration in /etc/mosquitto/conf.d/
#
# A full description of the configuration file is at
# /usr/share/doc/mosquitto/examples/mosquitto.conf.example

include_dir /etc/mosquitto/conf.d
EOF

	# Only owners and groups should access this
	chmod -Rv o-rwx /etc/mosquitto/

} # END FUNCTION : setupMosquittoConfig

#-------------------------------------------------------------------------------

# Setup
setupDirs;
setupPrerequisites;

# If not override, then Mosquitto source based on OS version - at the time of creation, Mosquitto's PPA didn't support Ubuntu 18.04
if [ -z "$mosquittoFrom" ]; then

	>&2 echo "Mosquitto from not set, selecting automatically."

	source /etc/os-release

	case "$VERSION_ID" in

		"16.04")
			mosquittoFrom="ppa";
			;;

		"18.04")
			mosquittoFrom="source";
			;;

	esac

fi # END IF : Mosquitto From

case "$mosquittoFrom" in

	"ppa")
		installMosquittoFromPPA;
		;;

	"source")
		installMosquittoFromSource;
		;;

	*)
		>&2 echo "Unknown Mosquitto desire."
		exit 1
		;;

esac

# Download Mongo DB
downloadPrep "${url_mongo}" mon mongo

# Download Mosquitto Auth Plugin
downloadPrep "${url_map}" mos map

# Compile and install Mosquitto Auth Plugin with all options (e.g. MySQL, Redis, etc.)
installMAP

# Setup /etc/mosquitto for easily following "Tying MQTT, WebSockets, and Nginx together with Docker":
# https://thad.getterman.org/2017/09/04/tying-mqtt-websockets-and-nginx-together-with-docker
setupMosquittoConfig

cd;

cleanup

ldconfig

exit 0
