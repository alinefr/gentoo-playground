# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils
[ "${PV}" = 9999 ] && inherit git-r3 autotools

DESCRIPTION="Enlightenment Foundation Core Libraries"
HOMEPAGE="http://www.enlightenment.org/"
EGIT_REPO_URI="git://git.enlightenment.org/core/${PN}.git"
[ "${PV}" = 9999 ] || SRC_URI="http://download.enlightenment.org/rel/libs/${PN}/${P/_/-}.tar.bz2"

LICENSE="BSD-2 GPL-2 LGPL-2.1 ZLIB"
[ "${PV}" = 9999 ] || KEYWORDS="~amd64 ~x86"
SLOT="0"

IUSE="+X avahi cxx-bindings debug doc drm egl fbcon +fontconfig fribidi gif gles glib gnutls gstreamer harfbuzz ibus jp2k nls +opengl ssl physics +png pulseaudio scim sdl static-libs systemd test tiff tslib v4l2 wayland webp xim xine xpm pixman xpresent"

COMMON_DEP="
	dev-lang/luajit:2
	sys-apps/dbus
	sys-libs/zlib
	virtual/jpeg
	virtual/udev
	X? (
		x11-libs/libX11
		x11-libs/libXScrnSaver
		x11-libs/libXcomposite
		x11-libs/libXcursor
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXinerama
		x11-libs/libXp
		x11-libs/libXrandr
		x11-libs/libXrender
		x11-libs/libXtst
		xpresent? ( x11-libs/libXpresent )
		gles? (
			media-libs/mesa[egl,gles2]
			x11-libs/libXrender
		)
		opengl? (
			virtual/opengl
			x11-libs/libXrender
		)
	)
	avahi? ( net-dns/avahi )
	debug? ( dev-util/valgrind )
	fontconfig? ( media-libs/fontconfig )
	fribidi? ( dev-libs/fribidi )
	gif? ( media-libs/giflib )
	glib? ( dev-libs/glib )
	gnutls? ( net-libs/gnutls )
	!gnutls? ( ssl? ( dev-libs/openssl ) )
	gstreamer? (
		media-libs/gstreamer:1.0
		media-libs/gst-plugins-base:1.0
	)
	harfbuzz? ( media-libs/harfbuzz )
	ibus? ( app-i18n/ibus )
	jp2k? ( media-libs/openjpeg )
	nls? ( sys-devel/gettext )
	physics? ( sci-physics/bullet )
	png? ( media-libs/libpng:0= )
	pulseaudio? (
		media-sound/pulseaudio
		media-libs/libsndfile
	)
	scim?	( app-i18n/scim )
	sdl? (
		>=media-libs/libsdl2-2.0.0:0[opengl?,gles?]
	)
	systemd? ( sys-apps/systemd )
	tiff? ( media-libs/tiff:0 )
	tslib? ( x11-libs/tslib )
	wayland? (
		>=dev-libs/wayland-1.3.0:0
		>=x11-libs/libxkbcommon-0.3.1
		egl? ( media-libs/mesa[egl,gles2] )
	)
	webp? ( media-libs/libwebp )
	xine? ( >=media-libs/xine-lib-1.1.1 )
	xpm? ( x11-libs/libXpm )
	drm? (
		>=dev-libs/libinput-0.6
		>=x11-libs/libxkbcommon-0.3
	)
	"
RDEPEND="${COMMON_DEP}"
DEPEND="${COMMON_DEP}
	!!dev-libs/ecore
	!!dev-libs/edbus
	!!dev-libs/eet
	!!dev-libs/eeze
	!!dev-libs/efreet
	!!dev-libs/eina
	!!dev-libs/eio
	!!dev-libs/embryo
	!!dev-libs/eobj
	!!dev-libs/ephysics
	!!media-libs/edje
	!!media-libs/emotion
	!!media-libs/ethumb
	!!media-libs/evas
	doc? ( app-doc/doxygen )
	test? ( dev-libs/check )"

S="${WORKDIR}/${P/_/-}"

src_prepare() {
	#epatch "${FILESDIR}/${P}-gnutls34.patch"
	#epatch "${FILESDIR}/${P}-emile-buildfix.patch"

	[ ${PV} = 9999 ] && eautoreconf
}

src_configure() {
	local config=()

	# gnutls / openssl
	if use gnutls; then
		config+=( --with-crypto=gnutls )
		use ssl && \
			einfo "You enabled both USE=ssl and USE=gnutls, using gnutls"
	elif use ssl; then
		config+=( --with-crypto=openssl )
	else
		config+=( --with-crypto=none )
	fi

	# X
	config+=(
		$(use_with X x)
		$(use_with X x11 xlib)
	)
	if use opengl; then
		config+=( --with-opengl=full )
		use gles &&  \
			einfo "You enabled both USE=opengl and USE=gles, using opengl"
	elif use gles; then
		config+=( --with-opengl=es )
		if use sdl; then
			config+=( --with-opengl=none )
			ewarn "You enabled both USE=sdl and USE=gles which isn't currently supported."
			ewarn "Disabling gl for all backends."
		fi
	else
		config+=( --with-opengl=none )
	fi

	# wayland
	config+=(
		$(use_enable egl)
		$(use_enable wayland)
	)

	if use drm && use systemd; then
		config+=(
			--enable-drm
			--enable-gl-drm
			--enable-elput
		)
	else
		einfo "You cannot build DRM support without systemd support, disabling drm engine"
		config+=(
			--disable-drm
		)
	fi
	# bug 501074
	if use pixman; then
		config+=(
			--enable-pixman
			--enable-pixman-font
			--enable-pixman-rect
			--enable-pixman-line
			--enable-pixman-poly
			--enable-pixman-image
			--enable-pixman-image-scale-sample
		)
	else
		config+=(
			--disable-pixman
			--disable-pixman-font
			--disable-pixman-rect
			--disable-pixman-line
			--disable-pixman-poly
			--disable-pixman-image
			--disable-pixman-image-scale-sample
		)
	fi
	config+=(
		$(use_enable avahi)
		$(use_enable cxx-bindings cxx-bindings)
		$(use_enable doc)
		$(use_enable fbcon fb)
		$(use_enable fontconfig)
		$(use_enable fribidi)
		$(use_enable gstreamer gstreamer1)
		$(use_enable harfbuzz)
		$(use_enable ibus)
		$(use_enable nls)
		$(use_enable physics)
		$(use_enable pulseaudio)
		$(use_enable pulseaudio audio)
		$(use_enable scim)
		$(use_enable sdl)
		$(use_enable static-libs static)
		$(use_enable systemd)
		$(use_enable tslib)
		$(use_enable v4l2)
		$(use_enable xim)
		$(use_enable xine)
		$(use_enable xpresent)

		# image loders
		--enable-image-loader-bmp
		--enable-image-loader-eet
		--enable-image-loader-generic
		--enable-image-loader-ico
		--enable-image-loader-jpeg # required by ethumb
		--enable-image-loader-psd
		--enable-image-loader-pmaps
		--enable-image-loader-tga
		--enable-image-loader-wbmp
		$(use_enable gif image-loader-gif)
		$(use_enable jp2k image-loader-jp2k)
		$(use_enable png image-loader-png)
		$(use_enable tiff image-loader-tiff)
		$(use_enable webp image-loader-webp)
		$(use_enable xpm image-loader-xpm)

		--enable-cserve
		--enable-libmount
		--enable-threads
		--enable-xinput22

		--disable-gesture
		--disable-gstreamer # using gstreamer1
		--disable-lua-old
		--disable-multisense
		--disable-tizen
#		--disable-xinput2

		--with-profile=$(usex debug debug release)
		--with-glib=$(usex glib yes no)
		--with-tests=$(usex test regular none)

		--enable-i-really-know-what-i-am-doing-and-that-this-will-probably-break-things-and-i-will-fix-them-myself-and-send-patches-abb
	)

	econf "${config[@]}"
}

src_test() {
	MAKEOPTS+=" -j1"
	default
}

src_install() {
	MAKEOPTS+=" -j1"
	default
	prune_libtool_files
}
