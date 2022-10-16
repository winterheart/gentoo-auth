# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools tmpfiles systemd

DESCRIPTION="Certificate status monitor and PKI enrollment client"
HOMEPAGE="https://pagure.io/certmonger"
SRC_URI="https://pagure.io/certmonger/archive/${P}/${PN}-${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="gmp nls xmlrpc"

DEPEND="
	gmp? ( dev-libs/gmp:=  )
	xmlrpc? ( dev-libs/xmlrpc-c:=[curl] )
	app-crypt/mit-krb5
	dev-libs/jansson:=
	dev-libs/libxml2
	dev-libs/openssl:=
	dev-libs/nss
	dev-libs/popt
	net-misc/curl[ssl]
	net-dns/libidn2:=
	net-nds/openldap
	sys-apps/dbus
	sys-apps/util-linux
	sys-libs/talloc
	sys-libs/tevent
"
RDEPEND="${DEPEND}
	nls? ( virtual/libintl )
"
BDEPEND="
	nls? ( sys-devel/gettext )
	virtual/pkgconfig
"

S="${WORKDIR}/${PN}-${P}"

src_prepare() {
	default
	# Respect LDFLAGS
	sed -i -e "/LDFLAGS =/d" src/Makefile.am || die "sed failed"
	eautoreconf
}

src_configure() {
	local myconf=(
		--with-file-store-dir=/var/lib/certmonger
		--enable-tmpfiles
		--with-tmpdir=/run/certmonger
		--enable-pie
		--enable-now
		--enable-systemd
		$(use_with gmp)
		$(use_with xmlrpc)
	)
	econf "${myconf[@]}"
}

src_install() {
	emake DESTDIR="${D}" install
	newinitd "${FILESDIR}/${PN}.init" ${PN}
	newconfd "${FILESDIR}/${PN}.conf" ${PN}
	systemd_dounit systemd/certmonger.service
	keepdir /var/lib/certmonger/{cas,local,requests}
}

pkg_postinst() {
	tmpfiles_process certmonger.conf
}
