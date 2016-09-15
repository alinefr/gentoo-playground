# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit libretro-core

DESCRIPTION="Port of Final Burn Alpha to Libretro"
HOMEPAGE="https://github.com/libretro/fbalpha"
SRC_URI=""

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/libretro/fbalpha.git"
	KEYWORDS=""
else
	KEYWORDS="amd64 x86 arm"
fi

LICENSE="FBA"
SLOT="0"
IUSE="+profile_accuracy profile_balanced profile_performance"

REQUIRED_USE="^^ ( profile_accuracy profile_balanced profile_performance )"

DEPEND=""
RDEPEND="${DEPEND}
		games-emulation/libretro-info"

src_prepare() {
	# Prevent -O3 from being appended to FLAGS
	sed -e 's/-O3 //g' \
		-i makefile* || die sed failed
	default
}

src_compile() {
	myemakeargs=(
		$(usex profile_accuracy "profile=accuracy" "")
		$(usex profile_balanced "profile=balanced" "")
		$(usex profile_performance "profile=performance" "")
	)
	emake "${myemakeargs[@]}" -f makefile.libretro || die "emake failed"
}
