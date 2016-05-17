#!/bin/bash

# TODO: add regenerate shared secret option

# In normal cases, you will only need to pass the HOST of your server.
#[ "no${HOST}" = "no" ] && echo "\$HOST environment variable required." && exit 1
HOST="tyr.so"
: ${PROFILE_NAME="Tyrchen VPN Profile"}
: ${PROFILE_IDENTIFIER=$(echo -n "${HOST}." | tac -s. | sed 's/\.$//g')}
: ${PROFILE_UUID=$(hostname)}
# These variable, especially CONN_UUID, are bind to per username,
# which currently, all users share the same secrets and configurations.
: ${CONN_NAME="Tyrchen IKEv2 VPN"}
: ${CONN_IDENTIFIER="${PROFILE_IDENTIFIER}.shared-configuration"}
: ${CONN_UUID=$(uuidgen)}
: ${CONN_HOST=${HOST}}
: ${CONN_REMOTE_IDENTIFIER=${HOST}}
CONN_SHARED_SECRET=$(grep "PSK" /usr/local/etc/ipsec.secrets | sed 's/.*"\(.*\)"/\1/g')

cat <<EOF
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Read more: https://wiki.strongswan.org/projects/strongswan/wiki/AppleIKEv2Profile -->
<plist version="1.0">
    <dict>
        <!-- Set the name to whatever you like, it is used in the profile list on the device -->
        <key>PayloadDisplayName</key>
        <string>${PROFILE_NAME}</string>
        <!-- This is a reverse-DNS style unique identifier used to detect duplicate profiles -->
        <key>PayloadIdentifier</key>
        <string>${PROFILE_IDENTIFIER}</string>
        <!-- A globally unique identifier, use uuidgen on Linux/Mac OS X to generate it -->
        <key>PayloadUUID</key>
        <string>${PROFILE_UUID}</string>
        <key>PayloadType</key>
        <string>Configuration</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
        <key>PayloadContent</key>
        <array>
            <!-- It is possible to add multiple VPN payloads with different identifiers/UUIDs and names -->
            <dict>
                <!-- This is an extension of the identifier given above -->
                <key>PayloadIdentifier</key>
                <string>${CONN_IDENTIFIER}</string>
                <!-- A globally unique identifier for this payload -->
                <key>PayloadUUID</key>
                <string>${CONN_UUID}</string>
                <key>PayloadType</key>
                <string>com.apple.vpn.managed</string>
                <key>PayloadVersion</key>
                <integer>1</integer>
                <!-- This is the name of the VPN connection as seen in the VPN application later -->
                <key>UserDefinedName</key>
                <string>${CONN_NAME}</string>
                <key>VPNType</key>
                <string>IKEv2</string>
                <key>IKEv2</key>
                <dict>
                    <!-- Hostname or IP address of the VPN server -->
                    <key>RemoteAddress</key>
                    <string>${CONN_HOST}</string>
                    <!-- Remote identity, can be a FQDN, a userFQDN, an IP or (theoretically) a certificate's subject DN. Can't be empty.
                     IMPORTANT: DNs are currently not handled correctly, they are always sent as identities of type FQDN -->
                    <key>RemoteIdentifier</key>
                    <string>${CONN_REMOTE_IDENTIFIER}</string>
                    <!-- Local IKE identity, same restrictions as above. If it is empty the client's IP address will be used -->
                    <key>LocalIdentifier</key>
                    <string></string>
                    <!--
                    OnDemand references:
                    http://www.v2ex.com/t/137653
                    https://developer.apple.com/library/mac/featuredarticles/iPhoneConfigurationProfileRef/Introduction/Introduction.html
                    Continue reading:
                    https://github.com/iphoting/ovpnmcgen.rb
                    -->
                    <key>OnDemandEnabled</key>
                    <integer>1</integer>
                    <key>OnDemandRules</key>
                    <array>
                        <dict>
                            <key>Action</key>
                            <string>Connect</string>
                        </dict>
                    </array>
                    <!-- The server is authenticated using a certificate -->
                    <key>AuthenticationMethod</key>
                    <string>SharedSecret</string>
                    <key>SharedSecret</key>
                    <string>${CONN_SHARED_SECRET}</string>
                    <!-- The client uses EAP to authenticate -->
                    <key>ExtendedAuthEnabled</key>
                    <integer>0</integer>
                </dict>
            </dict>
        </array>
    </dict>
</plist>
EOF
