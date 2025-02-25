FROM node:12-slim

# grab tini for signal processing and zombie killing
ENV TINI_VERSION 0.19.0

ENV http_proxy http://cs.pr-proxy.service.sd.diod.tech:3128/
ENV https_proxy http://cs.pr-proxy.service.sd.diod.tech:3128/

RUN set -x \
	&& apt-get update && apt-get install -y ca-certificates curl dnsutils iputils-ping \
		--no-install-recommends \
	&& apt-get install -y ssh-client \
	&& apt-get install -y gpg \
	&& curl -fSL "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini" -o /usr/local/bin/tini \
	&& curl -fSL "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini.asc" -o /usr/local/bin/tini.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver-options http-proxy=http://cs.pr-proxy.service.sd.diod.tech:3128 --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
	&& gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
	&& rm -r "$GNUPGHOME" /usr/local/bin/tini.asc \
	&& chmod +x /usr/local/bin/tini \
	&& tini -h 

EXPOSE 8081

# override some config defaults with values that will work better for docker
# ME_CONFIG_MONGODB_ENABLE_ADMIN="false" to not have error like
#  MongoError: not authorized on admin to execute command { listDatabases: 1, lsid: { id: UUID("5546bf2e-3981-404e-a5fd-d2fd97e93ae9") }, $db: "admin" }
ENV ME_CONFIG_EDITORTHEME="default" \
    ME_CONFIG_MONGODB_SERVER="mongodb" \
    ME_CONFIG_MONGODB_URL="mongodb://mongo:27017" \
    ME_CONFIG_MONGODB_ENABLE_ADMIN="false" \
    ME_CONFIG_BASICAUTH_USERNAME="" \
    ME_CONFIG_BASICAUTH_PASSWORD="" \
    ME_CONFIG_BASICAUTH_USERNAME_FILE="" \
    ME_CONFIG_BASICAUTH_PASSWORD_FILE="" \
    ME_CONFIG_MONGODB_ADMINUSERNAME_FILE="" \
    ME_CONFIG_MONGODB_ADMINPASSWORD_FILE="" \
    ME_CONFIG_MONGODB_AUTH_USERNAME_FILE="" \
    ME_CONFIG_MONGODB_AUTH_PASSWORD_FILE="" \
    ME_CONFIG_MONGODB_CA_FILE="" \
    VCAP_APP_HOST="0.0.0.0"

WORKDIR /app

COPY . /app

RUN cp config.default.js config.js

RUN set -x \
	&& apt-get update && apt-get install -y git --no-install-recommends \
        && git config --global url."https://github.com".insteadOf ssh://git@github.com \
        && git config --global url."https://".insteadOf git:// \
        && git config --global http.proxy http://cs.pr-proxy.service.sd.diod.tech:3128 \
        && git config --global https.proxy http://cs.pr-proxy.service.sd.diod.tech:3128 \
        && npm config set proxy http://cs.pr-proxy.service.sd.diod.tech:3128 \
        && npm config set https-proxy http://cs.pr-proxy.service.sd.diod.tech:3128 \
	&& npm install 

RUN npm run build

CMD ["tini", "--", "npm", "start"]
