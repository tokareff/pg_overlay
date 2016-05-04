# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit wxwidgets-gtk3 user

EGIT_REPO_URI="git://repo.or.cz/${PN}.git"

DESCRIPTION="aMule, the all-platform eMule p2p client"
HOMEPAGE="http://www.amule.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="+daemon -debug -geoip +nls remote -stats +unicode -upnp +X +mmap"

DEPEND=">=dev-libs/crypto++-5
	sys-libs/binutils-libs:0=
	>=sys-libs/zlib-1.2.1
	dev-libs/boost
	dev-util/boost-build
	stats? ( >=media-libs/gd-2.0.26[jpeg] )
	geoip? ( dev-libs/geoip )
	upnp? ( >=net-libs/libupnp-1.6.6 )
	remote? ( >=media-libs/libpng-1.2.0
	unicode? ( >=media-libs/gd-2.0.26 ) )
	X? ( >=x11-libs/wxGTK-3.1.0:3.1[X] )
	!X? ( >=x11-libs/wxGTK-3.1.0:3.1 )"
RDEPEND="${DEPEND}"

pkg_setup() {
	if use stats && ! use X; then
		einfo "Note: You would need both the X and stats USE flags"
		einfo "to compile aMule Statistics GUI."
		einfo "I will now compile console versions only."
	fi
}

src_prepare() {

	sed -i s/gtk1/gtk3/g configure || die
	sed -i s/WX_GTKPORT1/WX_GTKPORT3/g configure || die
	sed -i s/gtk1/gtk3/g m4/wxwin.m4 || die
	sed -i s/WX_GTKPORT1/WX_GTKPORT3/g m4/wxwin.m4 || die
	sed -i s/wxGTK1/wxGTK3/g src/OtherFunctions.cpp || die

	default
}

src_configure() {
	local myconf

	WX_GTK_VER="3.1"

	if use X; then
		einfo "wxGTK with X support will be used"
		need-wxwidgets unicode
	else
		einfo "wxGTK without X support will be used"
		need-wxwidgets base-unicode
	fi

	if use X ; then
		myconf="${myconf}
			--enable-amule-gui"
		use stats && myconf="${myconf}
			--enable-wxcas
			--enable-alc"
	else
		myconf="
			--disable-monolithic
			--disable-amule-gui
			--disable-wxcas
			--disable-alc"
	fi

	econf \
		--with-denoise-level=0 \
		--with-wx-config=${WX_CONFIG} \
		--disable-amulecmd \
		--with-boost \
		$(use_enable debug) \
		$(use_enable !debug optimize) \
		$(use_enable daemon amule-daemon) \
		$(use_enable geoip) \
		$(use_enable nls) \
		$(use_enable remote webserver) \
		$(use_enable stats cas) \
		$(use_enable stats alcc) \
		$(use_enable upnp) \
		$(use_enable mmap mmap) \
		${myconf}
}

src_install() {
	default

	if use daemon; then
		newconfd "${FILESDIR}"/amuled.confd amuled
		newinitd "${FILESDIR}"/amuled.initd amuled
	fi
	if use remote; then
		newconfd "${FILESDIR}"/amuleweb.confd amuleweb
		newinitd "${FILESDIR}"/amuleweb.initd amuleweb
	fi
}
