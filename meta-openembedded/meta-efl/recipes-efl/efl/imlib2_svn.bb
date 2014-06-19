SUMMARY = "A graphic library for file loading, saving, rendering, and manipulation"
LICENSE = "MIT BSD"
LIC_FILES_CHKSUM = "file://COPYING;md5=344895f253c32f38e182dcaf30fe8a35"
# can also depend on tiff34, ungif or gif, z, bz2, id3tag
DEPENDS = "freetype libpng jpeg virtual/libx11 libxext"
PROVIDES = "virtual/imlib2"
PV = "1.4.5+svnr${SRCPV}"
SRCREV = "${EFL_SRCREV}"

PNBLACKLIST[imlib2] = "BROKEN: needs to be updated to use freetype2 pkg-config"

inherit efl binconfig
SRC_URI = "${E_SVN}/trunk;module=${SRCNAME};protocol=http;scmdata=keep"
S = "${WORKDIR}/${SRCNAME}"

PACKAGECONFIG ??= ""
PACKAGECONFIG[gif] = "--with-gif,--without-gif,giflib"
PACKAGECONFIG[tiff] = "--with-tiff,--without-tiff,tiff"
PACKAGECONFIG[bzip2] = "--with-bzip2,--without-bzip2,bzip2"
PACKAGECONFIG[id3] = "--with-id3,--without-id3,libid3tag"

EXTRA_OECONF = "--with-x \
                --x-includes=${STAGING_INCDIR} \
                --x-libraries=${STAGING_LIBDIR} "

# TODO: Use more fine granular version
#OE_LT_RPATH_ALLOW=":${libdir}/imlib2/loaders:${libdir}/imlib2/filters:"
OE_LT_RPATH_ALLOW = "any"
OE_LT_RPATH_ALLOW[export]="1"

PACKAGES =+ "imlib2-loaders-dbg imlib2-filters-dbg imlib2-loaders imlib2-filters"
FILES_${PN} = "${libdir}/lib*.so.* ${libdir}/imlib2/*/*.so"
FILES_${PN}-dbg = "${libdir}/.debug/ ${bindir}/.debug/ ${prefix}/src/debug/"
FILES_${PN}-dev += "${bindir}/imlib2-config ${libdir}/*.so ${includedir}"
FILES_${PN}-bin = "${bindir}"
FILES_imlib2-loaders = "${libdir}/imlib2/loaders/*.so"
FILES_imlib2-filters = "${libdir}/imlib2/filters/*.so"
FILES_imlib2-loaders-dbg += "${libdir}/imlib2/loaders/.debug"
FILES_imlib2-filters-dbg += "${libdir}/imlib2/filters/.debug"

# png.so jpeg.so id3.so are also provided by lightmediascanner
PRIVATE_LIBS_imlib2-loaders = "pnm.so lbm.so argb.so tiff.so zlib.so bmp.so tga.so gif.so xpm.so bz2.so"

PRIVATE_LIBS_imlib2-filters = "bumpmap.so colormod.so testfilter.so"
