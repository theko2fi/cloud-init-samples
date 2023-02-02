#!/usr/bin/env sh

set -ex

METHOD="${1:-${METHOD:-cloud}}"
ENDPOINT="${8:-${ENDPOINT:-localhost}}"


publicIpFromInterface() {
  echo "Couldn't find a valid ipv4 address, using the first IP found on the interfaces as the endpoint."
  DEFAULT_INTERFACE="$(ip -4 route list match default | grep -Eo "dev .*" | awk '{print $2}')"
  ENDPOINT=$(ip -4 addr sh dev "$DEFAULT_INTERFACE" | grep -w inet | head -n1 | awk '{print $2}' | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b')
  export ENDPOINT="${ENDPOINT}"
  echo "${ENDPOINT}"
  #echo "Using ${ENDPOINT} as the endpoint"
}

publicIpFromMetadata() {
  if curl -s http://169.254.169.254/metadata/v1/vendor-data | grep DigitalOcean >/dev/null; then
    ENDPOINT="$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)"
  elif test "$(curl -s http://169.254.169.254/latest/meta-data/services/domain)" = "amazonaws.com"; then
    ENDPOINT="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
  elif host -t A -W 10 metadata.google.internal 127.0.0.53 >/dev/null; then
    ENDPOINT="$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip")"
  elif test "$(curl -s -H Metadata:true --noproxy '*' 'http://169.254.169.254/metadata/instance/compute/provider/?api-version=2021-02-01&format=text')" = "Microsoft.Compute"; then
    ENDPOINT="$(curl -H Metadata:true --noproxy '*' 'http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress/?api-version=2021-02-01&format=text')"
  fi

  if echo "${ENDPOINT}" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"; then
    export ENDPOINT="${ENDPOINT}"
    echo "${ENDPOINT}"
  else
    publicIpFromInterface
  fi
}

if test "$METHOD" = "cloud"; then
  publicIpFromMetadata
fi
