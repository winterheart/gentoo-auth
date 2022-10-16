# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools bash-completion-r1

DESCRIPTION="Select authentication and indentity profile to use on the system"
HOMEPAGE="https://github.com/authselect/authselect"
SRC_URI="https://github.com/authselect/authselect/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="nls"

DEPEND="
	nls? ( virtual/libintl )
	dev-libs/popt
	sys-libs/libselinux
"
RDEPEND="
	${DEPEND}
	sys-auth/oddjob
"
BDEPEND="
	nls? ( sys-devel/gettext )
	app-text/asciidoc
	app-text/po4a
	virtual/pkgconfig
"

src_prepare() {
	default
	# Fix man pages installation script
	sed -i -e "s:/usr/bin/::g" -e "s:PATH:PATHNAME:g" \
		scripts/manpages-install.sh.in || die
	eautoreconf
}

src_configure() {
	local myconf=(
		--localstatedir=/var
		$(use_enable nls)
	)
	econf "${myconf[@]}"
}

src_install() {
	emake DESTDIR="${D}" install
	find "${D}" -name '*.la' -delete || die
	rm "${D}/etc/bash_completion.d/authselect-completion.sh" || die
	newbashcomp src/cli/authselect-completion.sh authselect
	keepdir /var/lib/authselect/backups /etc/authselect
}
