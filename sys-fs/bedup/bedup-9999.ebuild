# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/bedup/bedup-9999.ebuild,v 1.6 2014/05/21 11:31:18 mgorny Exp $

EAPI=5

PYTHON_COMPAT=( python{3_3,3_4} pypy3 )
# pypy unsupported for now ;-(

#if LIVE
EGIT_REPO_URI="git://github.com/g2p/bedup.git
	https://github.com/g2p/bedup.git"
EGIT_BRANCH=wip/dedup-syscall
inherit git-r3
#endif

inherit distutils-r1

DESCRIPTION="Btrfs file de-duplication tool"
HOMEPAGE="https://github.com/g2p/bedup"
SRC_URI="https://github.com/g2p/${PN}/archive/v${PV}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# we need btrfs-progs with includes installed.
DEPEND="$(python_gen_cond_dep 'dev-python/cffi:=[${PYTHON_USEDEP}]' 'python*')
	>=sys-fs/btrfs-progs-0.20_rc1_p358"
RDEPEND="${DEPEND}
	dev-python/mako[${PYTHON_USEDEP}]
	dev-python/alembic[${PYTHON_USEDEP}]
	dev-python/contextlib2[${PYTHON_USEDEP}]
	dev-python/pyxdg[${PYTHON_USEDEP}]
	>=dev-python/sqlalchemy-0.8.2[sqlite,${PYTHON_USEDEP}]"

#if LIVE
SRC_URI=
KEYWORDS=
#endif

#src_prepare() {
#	default
#	epatch "${FILESDIR}/SQLAlchemy-0.9-compat.patch"
#}