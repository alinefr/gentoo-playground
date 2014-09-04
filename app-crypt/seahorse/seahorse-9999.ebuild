# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GCONF_DEBUG="yes"
VALA_MIN_API_DEPEND="0.24"
VALA_MAX_API_DEPEND="0.26"

inherit gnome2
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live vala
fi

DESCRIPTION="A GNOME application for managing encryption keys"
HOMEPAGE="https://wiki.gnome.org/Apps/Seahorse"

LICENSE="GPL-2+ FDL-1.1+"
SLOT="0"
IUSE="avahi debug ldap"
if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
fi

COMMON_DEPEND="
	>=app-crypt/gcr-3.11.91:=
	>=dev-libs/glib-2.10:2
	>=x11-libs/gtk+-3.4:3
	>=app-crypt/libsecret-0.16
	>=net-libs/libsoup-2.33.92:2.4
	x11-misc/shared-mime-info

	net-misc/openssh
	>=app-crypt/gpgme-1
	|| (
		=app-crypt/gnupg-2.0*
		=app-crypt/gnupg-1.4* )

	avahi? ( >=net-dns/avahi-0.6:= )
	ldap? ( net-nds/openldap:= )
"
DEPEND="${COMMON_DEPEND}
	>=dev-util/intltool-0.35
	sys-devel/gettext
	virtual/pkgconfig
"
# Need seahorse-plugins git snapshot
RDEPEND="${COMMON_DEPEND}
	!<app-crypt/seahorse-plugins-2.91.0_pre20110114
"
if [[ ${PV} = 9999 ]]; then
	DEPEND="${DEPEND}
		$(vala_depend)
		app-crypt/gcr[vala]
		app-text/yelp-tools"
fi

src_prepare() {
	# FIXME: Do not mess with CFLAGS with USE="debug"
	sed -e '/CFLAGS="$CFLAGS -g/d' \
		-e '/CFLAGS="$CFLAGS -O0/d' \
		-i configure.ac || die "sed 1 failed"

	vala_src_prepare
	gnome2_src_prepare
}

src_configure() {
	local myconf=""
	if [[ ${PV} != 9999 ]]; then
		myconf="${myconf}
			ITSTOOL=$(type -P true)
			VALAC=$(type -P true)"
	fi
	gnome2_src_configure \
		--enable-pgp \
		--enable-ssh \
		--enable-pkcs11 \
		--enable-hkp \
		$(use_enable avahi sharing) \
		$(use_enable debug) \
		$(use_enable ldap) \
		${myconf}
}
