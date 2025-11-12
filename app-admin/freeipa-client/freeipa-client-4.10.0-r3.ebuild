# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )

inherit autotools bash-completion-r1 python-single-r1 systemd

DESCRIPTION="FreeIPA management client"
HOMEPAGE="https://www.freeipa.org/"
SRC_URI="https://releases.pagure.org/freeipa/freeipa-${PV}.tar.gz"

S="${WORKDIR}/freeipa-${PV}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="nls +xmlrpc"

DEPEND="
	nls? ( sys-devel/gettext )
	xmlrpc? ( dev-libs/xmlrpc-c )
	app-crypt/mit-krb5
	dev-libs/ding-libs
	dev-libs/openssl:=
	dev-libs/popt
	dev-libs/cyrus-sasl
	dev-libs/jansson

	dev-python/cffi
	>=dev-python/cryptography-38.0.1
	dev-python/dnspython
	dev-python/gssapi
	dev-python/netaddr
	dev-python/pyasn1
	dev-python/pyasn1-modules
	dev-python/six
	dev-python/qrcode

	net-misc/curl[kerberos,ssl]
	net-nds/openldap
"
RDEPEND="
	${DEPEND}
	${PYTHON_DEPS}
	app-crypt/certmonger[xmlrpc?]
	dev-python/dbus-python
	dev-python/netifaces
	dev-python/python-augeas
	dev-python/python-ldap[sasl,ssl]
	sys-auth/authselect
	sys-auth/sssd[python,samba]
	virtual/libintl
"
BDEPEND="
	virtual/pkgconfig
"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

PATCHES=(
	"${FILESDIR}/${P}-gentoo_openrc-platform.patch"
	"${FILESDIR}/${P}-cryptography.patch"
)

src_prepare() {
	default
	# Don't rely on systemd.pc
	sed -i -e '/PKG_CHECK_EXISTS(\[systemd\]/d' configure.ac || die
	# Fix bashcomp installation
	sed -i \
		-e "s:bashcompdir = \$(sysconfdir)/bash_completion.d:bashcompdir = $(get_bashcompdir):g" \
		contrib/completion/Makefile.am || die
	eautoreconf
}

pkg_setup() {
	python-single-r1_pkg_setup
}

src_configure() {
	local myconf=(
		--localstatedir=/var
		--disable-server
		--with-systemdtmpfilesdir="${EPREFIX}/usr/lib/tmpfiles.d"
		--with-systemdsystemunitdir="$(systemd_get_systemunitdir)"
		--with-ipaplatform="gentoo_openrc"
		--without-ipatests
		$(use_enable nls)
		$(use_with xmlrpc ipa-join-xml)
	)
	econf "${myconf[@]}"
}

src_install() {
	emake DESTDIR="${D}" install
	python_optimize
	keepdir /var/lib/ipa-client/{pki,sysrestore}
	keepdir /run/ipa
	keepdir /etc/krb5.conf.d/
}
