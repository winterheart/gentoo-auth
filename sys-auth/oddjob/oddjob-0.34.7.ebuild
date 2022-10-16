# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools systemd

DESCRIPTION="Service that receives requests to do things over the D-Bus"
HOMEPAGE="https://pagure.io/oddjob"
SRC_URI="https://releases.pagure.org/${PN}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	sys-apps/dbus
	sys-libs/libselinux
	dev-libs/libxml2
	sys-libs/pam
"
RDEPEND="${DEPEND}
	sys-apps/util-linux
"
BDEPEND="
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}/${P}-systemdfiles.patch"
)

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=(
		--with-selinux-acls
		--with-selinux-labels
		--without-python
		--enable-now
		--enable-pie
		--disable-sysvinit
		--with-systemdsystemunitdir="$(systemd_get_systemunitdir)"
		--libdir=/$(get_libdir)
	)
	econf "${myconf[@]}"
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc doc/oddjob.html
	newinitd "${FILESDIR}/oddjobd.init" oddjobd
	newconfd "${FILESDIR}/oddjobd.conf" oddjobd
	find "${D}" -name '*.la' -delete || die
}
