require clutter-gst.inc

PV = "0.3.0+svn${SRCDATE}"
PR = "r3"

SRC_URI = "svn://svn.o-hand.com/repos/clutter/trunk;module=${PN};proto=http \
           file://autofoo.patch;patch=1"

S = "${WORKDIR}/${PN}"


