FROM ghcr.io/cynix/freebsd:small
ARG TARGETARCH

RUN pkg install -y FreeBSD-openssl nss-pam-ldapd samba419 && pkg clean -a -y && rm -rf /var/db/pkg/repos

COPY nsswitch.conf /etc/nsswitch.conf
COPY templates/* /templates/

# Create symlinks for config files whose paths are hardcoded.
#
# Move `/etc/ssl` to `/var/run/ssl` and symlink it back, so that
# we can run `certctl rehash` at startup to pick up any root CAs
# added by the user under `/usr/local/etc/ssl/certs` even if the
# container was started in read-only mode.
#
# Fix permission of `/usr/local/sbin` to allow non-root users to
# run daemons (e.g. `nslcd`).
RUN mkdir -m711 /var/run/config \
    && ln -sf /var/run/config/ldap.conf /usr/local/etc/openldap/ldap.conf \
    && ln -sf /var/run/config/nslcd.conf /usr/local/etc/nslcd.conf \
    && mv /etc/ssl /var/run/ && ln -sf /var/run/ssl /etc/ssl \
    && chmod 711 /usr/local/sbin \
    && rmdir /var/log/samba4 && ln -sf /tmp/samba4 /var/log/samba4

COPY bin/${TARGETARCH}/groundcontrol /usr/local/sbin/groundcontrol
COPY groundcontrol.toml /usr/local/etc/groundcontrol.toml
ENTRYPOINT ["/usr/local/sbin/groundcontrol", "/usr/local/etc/groundcontrol.toml"]
