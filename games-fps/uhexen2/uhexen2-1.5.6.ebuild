# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils flag-o-matic toolchain-funcs games

DATA_PV="1.28"
HW_PV="0.15"
MY_PN="hexen2"
DEMO_PV="1.4.3"

DESCRIPTION="Hexen 2 port - Hammer of Thyrion"
HOMEPAGE="http://uhexen2.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_PN}source-${PV}.tgz
	mirror://sourceforge/u${MY_PN}/gamedata-all-${DATA_PV}.tgz
	hexenworld? ( mirror://sourceforge/u${MY_PN}/hexenworld-pakfiles-${HW_PV}.tgz )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="alsa asm cdaudio debug demo dynamic hexenworld gtk lights
midi opengl optimize-cflags oss sdlaudio sdlcd tools"

QA_EXECSTACK="${GAMES_BINDIR:1}/hexen2
	${GAMES_BINDIR:1}/glhexen2
	${GAMES_BINDIR:1}/hexen2-demo
	${GAMES_BINDIR:1}/glhexen2-demo
	${GAMES_BINDIR:1}/hwcl
	${GAMES_BINDIR:1}/glhwcl
	${GAMES_BINDIR:1}/hwcl-demo
	${GAMES_BINDIR:1}/glhwcl-demo"

UIDEPEND=">=media-libs/libsdl-1.2.7
	alsa? ( >=media-libs/alsa-lib-1.0.7 )
	midi? ( >=media-libs/sdl-mixer-1.2.5[timidity] )
	!midi? ( >=media-libs/sdl-mixer-1.2.5 )
	opengl? ( virtual/opengl )"

# Launcher depends from GTK+ libs
LNCHDEPEND="gtk? ( x11-libs/gtk+:2 )"

# xdelta is not needed since h2patch is built against bundled xdelta3
RDEPEND="!games-fps/uhexen2-cvs
	${UIDEPEND}
	${LNCHDEPEND}
	demo? ( >=games-fps/hexen2-demodata-${DEMO_PV} )
	lights? ( games-fps/hexen2-lights )"
DEPEND="${UIDEPEND}
	${LNCHDEPEND}
	x86? ( asm? ( >=dev-lang/nasm-0.98.38 ) )"

S="${WORKDIR}/hexen2source-${PV}"
dir="${GAMES_DATADIR}/${MY_PN}"

pkg_setup() {
	games_pkg_setup

	if ! use midi ; then
		ewarn "MIDI support disabled! MIDI music won't be played at all."
		ewarn "If you want to hear it, recompile this package"
		ewarn "with \"midi\" USE flag enabled."
	fi

	use alsa || ewarn "alsa is the recommended sound driver."
}

src_prepare() {
	#cd hexen2
	#epatch "${S}/00_Patches/external-music-file-support.diff"
	#cd ..

	# Whether to use the demo directory
	local demo
	use demo && demo="/demo"

	# Use default basedir - has 2 variations
	sed -i \
		-e "s:parms.basedir = cwd;:parms.basedir = \"${dir}${demo}\";:" \
		-e "s:parms.basedir = \".\";:parms.basedir = \"${dir}${demo}\";:" \
		engine/{hexen2,hexen2/server,hexenworld/{client,server}}/sys_unix.c \
		|| die "sed sys_unix.c failed"

	# Change default sndspeed from 22050 to 44100,
	# to improve the quality/reliability.
	sed -i \
		-e "s:desired_speed = 22050:desired_speed = 44100:" \
		engine/h2shared/snd_dma.c || die "sed snd_dma.c failed"

	# Give locations of patchdata and gamedata
	sed -i \
		-e "/DELTA_DIR/s:\".*\":\"${dir}/patchdat\":g" \
		-e "/cdrom_path/s:\".*\":\"${dir}/data1\":g" \
		h2patch/h2patch3.c launcher/apply_patch.c || die "sed patchdata failed"

	# Honour Portage CFLAGS also when debuggins is enabled
	use debug && append-flags "-g2"
	for u in `grep -lr '\-g \-Wall' *`; do
		sed -i \
			-e "s/^CFLAGS \:\= \-g \-Wall/CFLAGS \:\= ${CFLAGS}/" \
			${u} || die "sed ${u} failed"
	done

	if use demo ; then
		# Allow lightmaps in demo
		sed -i \
			-e "s:!override_pack:0:" \
			engine/hexen2/common.c || die "sed common.c demo failed"
	fi

	if use gtk ; then
		# Tweak the default games data dir for graphical launcher
		sed -i \
			-e "/int basedir_nonstd/s:= 0:= 1:" \
			-e "/game_basedir\[0\]/d" \
			launcher/config_file.c || die "sed config_file.c failed"
		# Tweak the default name for binary executables,if DEMO version is enabled
		if use demo ; then
			sed -i \
				-e "/BINARY_NAME/s:\"$:-demo\":" \
				launcher/games.h || die "sed games.h failed"
		fi
	fi

	rm -rf docs/{activision,COMPILE,COPYING,LICENSE,README.win32}
}

src_compile() {

	local h2bin="h2" hwbin="hw" link_gl_libs="no" opts
	local \
		h2bin="h2" hwbin="hw" \
		USE_ALSA="no" \
		USE_CDAUDIO="no" \
		LINK_GL_LIBS="no" \
		USE_MIDI="no" \
		OPT_EXTRA="no" \
		USE_OSS="no" \
		USE_SDLCD="no" \
		X86_ASM="no" \
		opts

	if use opengl ; then
		h2bin="${h2bin} gl${h2bin}"
		hwbin="${hwbin} gl${hwbin}"
		use dynamic && LINK_GL_LIBS="yes"
	fi

	use debug && opts="${opts} DEBUG=1"
	use demo && opts="${opts} DEMO=1"

	use alsa && USE_ALSA="yes"
	use cdaudio && USE_CDAUDIO="yes"
	use optimize-cflags && OPT_EXTRA="yes"
	use oss && USE_OSS="yes"
	use sdlcd && USE_SDLCD="yes"
	use midi && USE_MIDI="yes"
	use x86 && use asm && X86_ASM="yes"

	# Build h2patch
	cd "${S}/h2patch"
	einfo "Building graphical launcher"
	emake \
		AUTOTOOLS=1 \
		${opts} \
		CPUFLAGS="${CFLAGS}" \
		CC="$(tc-getCC)" \
		|| die "emake h2patch failed"

	if use gtk ; then
	# Build launcher
		cd "${S}/launcher"
		einfo "Building graphical launcher"
		emake \
			AUTOTOOLS=1 \
			${opts} \
			CPUFLAGS="${CFLAGS}" \
			CC="$(tc-getCC)" \
			|| die "emake launcher failed"
	fi

	if use tools ; then
		# Build Hexen2 utils
		cd "${S}/utils"
		einfo "Building utils"
		local utils_list="hcc qbsp light vis bspinfo genmodel qfiles dcc jsh2color texutils/bsp2wal texutils/lmp2pcx"
		for x in ${utils_list}
		do
			emake -C ${x} \
				${opts} \
				CPUFLAGS="${CFLAGS}" \
				CC="$(tc-getCC)" \
				|| die "emake ${x} failed"
		done
	fi

	if use hexenworld ; then
		if use tools; then
			# Hexenworld utils
			local hw_utils="hwmquery hwrcon"
			einfo "Building Hexenworld utils"
			cd "${S}/hw_utils"
			for x in ${hw_utils} ; do
				emake \
					${opts} \
					CPUFLAGS="${CFLAGS}" \
					CC="$(tc-getCC)" \
					-C ${x} \
					|| die "emake ${x} failed"
			done
		fi

		# Hexenworld
		einfo "Building Hexenworld server"
		cd "${S}"/engine/hexenworld
		# Hexenworld server
		emake \
			${opts} \
			CPUFLAGS="${CFLAGS}" \
			CC="$(tc-getCC)" \
			-C server \
			|| die "emake HexenWorld Server failed"

		# Hexenworld client
		einfo "Building Hexenworld client(s)"
		for m in ${hwbin} ; do
			emake -C client clean
			emake \
				${opts} \
				USE_ALSA=${USE_ALSA} \
				USE_OSS=${USE_OSS} \
				USE_CDAUDIO=${USE_CDAUDIO} \
				USE_MIDI=${USE_MIDI} \
				USE_SDLAUDIO=${USE_SDLAUDIO} \
				USE_SDLCD=${USE_SDLCD} \
				USE_X86_ASM=${X86_ASM} \
				OPT_EXTRA=${OPT_EXTRA} \
				LINK_GL_LIBS=${LINK_GL_LIBS} \
				USE_3DFXGAMMA=no \
				CPUFLAGS="${CFLAGS}" \
				CC="$(tc-getCC)" \
				${m} \
				-C client \
				|| die "emake Hexenworld Client (${m}) failed"
		done
	fi

	# Hexen 2 game executable
	cd "${S}/engine/${MY_PN}"

	einfo "Building UHexen2 game executable(s)"
	for m in ${h2bin} ; do
		emake clean
		emake \
			${opts} \
			USE_ALSA=${USE_ALSA} \
			USE_OSS=${USE_OSS} \
			USE_CDAUDIO=${USE_CDAUDIO} \
			USE_MIDI=${USE_MIDI} \
			USE_SDLAUDIO=${USE_SDLAUDIO} \
			USE_SDLCD=${USE_SDLCD} \
			USE_X86_ASM=${X86_ASM} \
			OPT_EXTRA=${OPT_EXTRA} \
			LINK_GL_LIBS=${LINK_GL_LIBS} \
			USE_3DFXGAMMA=no \
			CPUFLAGS="${CFLAGS}" \
			CC="$(tc-getCC)" \
			${m} \
			|| die "emake Hexen2 (${m}) failed"
	done

}

src_install() {
	local demo demo_title demo_suffix
	use demo && demo="-demo" && demo_title=" (Demo)" && demo_suffix="demo"

	newicon engine/resource/hexen2.png ${PN}.png || die

	make_desktop_entry "${MY_PN}${demo}" "Hexen 2${demo_title}" ${PN}
	newgamesbin "engine/${MY_PN}/${MY_PN}" "${MY_PN}${demo}" \
		|| die "newgamesbin ${MY_PN} failed"

	if use opengl ; then
		make_desktop_entry "gl${MY_PN}${demo}" "GLHexen 2${demo_title}" ${PN}
		newgamesbin "engine/${MY_PN}/gl${MY_PN}" "gl${MY_PN}${demo}" \
			|| die "newgamesbin gl${MY_PN} failed"
	fi

	if use hexenworld ; then
		if use tools; then
			# Hexenworld utils
			dobin hw_utils/hwmquery/hwmquery || die "dobin hwmquery failed"
			dobin hw_utils/hwrcon/{hwrcon,hwterm} || die "dobin hwrcon/hwterm failed"

			dodoc hw_utils/hwmquery/hwmquery.txt || die "dodoc hwmquery.txt failed"
			dodoc hw_utils/hwrcon/{hwrcon,hwterm}.txt \
			|| die "dodoc hwrcon/hwterm.txt failed"
		fi

		# Hexenworld Server
		newgamesbin engine/hexenworld/server/hwsv hwsv${demo} \
			|| die "newgamesbin hwsv failed"

		# HexenWorld client(s)
		newicon engine/resource/hexenworld.png hwcl.png || die

		make_desktop_entry \
			"hwcl${demo}" "Hexen 2${demo_title} Hexenworld Client" hwcl
		newgamesbin "engine/hexenworld/client/hwcl" "hwcl${demo}" \
			|| die "newgamesbin hwcl failed"

		if use opengl ; then
			make_desktop_entry \
				"glhwcl${demo}" "GLHexen 2${demo_title} Hexenworld Client" hwcl
			newgamesbin "engine/hexenworld/client/glhwcl" "glhwcl${demo}" \
				|| die "newgamesbin glhwcl failed"
		fi

		insinto "${dir}"/${demo_suffix}
		doins -r "${WORKDIR}"/hw || die "doins hexenworld pak failed"
	fi

	if use gtk ; then
		# GTK launcher
		local lnch_name="h2launcher"
		use demo && lnch_name="h2demo"
		newgamesbin launcher/${lnch_name} h2launcher \
			|| die "newgamesbin h2launcher failed"
		make_desktop_entry \
			"h2launcher" "Hexen 2${demo_title} Launcher" ${PN}
	fi

	# Forge a new useful document 8)
	#head -22 "00_Patches/external-music-file-support.diff" > \
	#"docs/external_music.README" || die "make readme failed"

	dodoc docs/* || die "dodoc failed"

	if ! use demo ; then
		# Install updated game data
		insinto "${dir}"
		doins -r "${WORKDIR}"/{data1,patchdat,portals,siege} || die
		# Patching should really be done by a future "hexen2-data" ebuild.
		# But this works for now.
		dobin "${S}"/h2patch/h2patch || die
		dodoc "${WORKDIR}"/*.txt || die
	fi

	if use tools ; then
		local utils_list="hcc/hcc qbsp/qbsp light/light vis/vis bspinfo/bspinfo"
		for x in ${util_list}; do
			dobin utils/${x} || die "dobin utils part 1 failed"

		done
		utils_list="genmodel/genmodel qfiles/qfiles dcc/dcc jsh2color/jsh2color"
		for x in ${util_list}; do
			dobin utils/${x} || die "dobin utils part 2 failed"

		done
		utils_list="texutils/bsp2wal texutils/lmp2pcx"
		for x in ${util_list}; do
			dobin utils/${x} || die "dobin utils part 3 failed"

		done
		docinto utils
		dodoc utils/README || die "dodoc README failed"
		newdoc utils/dcc/README README.dcc || die "newdoc dcc failed"
		dodoc utils/dcc/dcc.txt || die "dodoc dcc.txt failed"
		newdoc utils/hcc/README README.hcc || die "newdoc hcc failed"
		newdoc utils/jsh2color/README README.jsh2color \
			|| die "newdoc README.jsh2color failed"
		newdoc utils/jsh2color/ChangeLog ChangeLog.jsh2color \
			|| die "newdoc Changelog.jsh2color failed"
	fi

	prepgamesdirs
}

pkg_postinst() {
	games_pkg_postinst

	if use demo ; then
		einfo "uhexen2 has been compiled specifically to play the demo maps."
		einfo "Example command-line:"
		einfo "   hexen2-demo -width 1024 -height 768 -conwidth 640"
		einfo
	else
		elog "To play the demo, emerge with the 'demo' USE flag."
		elog
		elog "For the Hexen 2 original game..."
		elog "Put the following files into "${dir}"/data1 before playing:"
		elog "   pak0.pak pak1.pak"
		elog "Then to play:  hexen2"
		elog
		elog "For the 'Portal of Praevus' mission pack..."
		elog "Put the following file into "${dir}"/portals before playing:"
		elog "   pak3.pak"
		elog "Then to play:  hexen2 -portals"
		elog
		elog "To ensure the data files from the CD are patched, run as root:"
		elog "   h2patch, or patch data files from launcher"
		elog
		elog "Example command-line:"
		elog "   hexen2 -width 1024 -height 768 -conwidth 640"
		einfo
	fi
	if use gtk ; then
		einfo "You've also installed a nice graphical launcher. Simply run:"
		einfo
		einfo "   h2launcher"
		einfo
		einfo "to enjoy it :)"
		einfo
	fi
	if use tools ; then
		if use hexenworld; then
			einfo "You've also installed some Hexenworld utility:"
			einfo
			einfo " - hwmquery (console app to query HW master servers)"
			einfo " - hwrcon (remote interface to HW rcon command)"
			einfo " - hwterm (HW remote console terminal)"
			einfo
		fi
		einfo "You've also installed some Hexen2 utility"
		einfo "(useful for mod developing)"
		einfo
		einfo " - dhcc (old progs.dat compiler/decompiler)"
		einfo " - genmodel (3-D model grabber)"
		einfo " - hcc (HexenC compiler)"
		einfo " - jsh2color (light colouring utility)"
		einfo " - maputils (Map compiling tools: bspinfo, light, qbsp, vis)"
		einfo " - qfiles (build pak files and regenerate bsp models)"
		einfo " - bsp2wal (extract all textures from a bsp file)"
		einfo " - lmp2pcx (convert hexen2 texture data into pcx and tga)"
		einfo
		einfo "See relevant documentation for further informations"
		einfo
	fi
}
