# Copyright (c) 2016-2017 Varnish Software AS
# All rights reserved.
#
# Author: Dridi Boukelmoune <dridi.boukelmoune@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials
#    provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.

# varnish.m4 - Macros to define VMOD builds.            -*- Autoconf -*-
# serial 7 (varnish-5.1.2)
#
# This collection of macros helps create VMODs or tools interacting with
# Varnish Cache using the GNU build system (autotools). In order to work
# from a source checkout, recommended versions of autotools are 2.68 for
# autoconf, 1.12 for automake and 2.2.6 for libtool. For pkg-config, at
# least version 0.21 is required ; it should be available even on old
# platforms. Only pkg-config is needed when building from a dist archive.
#
# Macros whose name start with an underscore are private and may change at
# any time. Public macros starting with VARNISH_ are documented and will
# maintain backwards compatibility with older versions of Varnish Cache.

# _VARNISH_CHECK_LIB(LIB, FUNC)
# -----------------------------
AC_DEFUN([_VARNISH_CHECK_LIB], [
	save_LIBS="${LIBS}"
	LIBS=""
	AC_CHECK_LIB([$1], [$2])
	AC_SUBST(m4_toupper($1_LIBS), "$LIBS")
	LIBS="${save_LIBS}"
])

# _VARNISH_SEARCH_LIBS(VAR, FUNC, LIBS)
# -------------------------------------
AC_DEFUN([_VARNISH_SEARCH_LIBS], [
	save_LIBS="${LIBS}"
	LIBS=""
	AC_SEARCH_LIBS([$2], [$3])
	AC_SUBST(m4_toupper($1_LIBS), "$LIBS")
	LIBS="${save_LIBS}"
])

# _VARNISH_CHECK_EXPLICIT_BZERO()
# -------------------------------
AC_DEFUN([_VARNISH_CHECK_EXPLICIT_BZERO], [
	AC_CHECK_FUNCS([explicit_bzero])
])

# _VARNISH_PKG_CONFIG
# --------------------
AC_DEFUN([_VARNISH_PKG_CONFIG], [
	PKG_PROG_PKG_CONFIG([0.21])

	PKG_CHECK_MODULES([VARNISHAPI], [varnishapi])
	AC_SUBST([VARNISH_VERSION], [$($PKG_CONFIG --modversion varnishapi)])

	PKG_CHECK_VAR([VARNISHAPI_PREFIX], [varnishapi], [prefix])
	PKG_CHECK_VAR([VARNISHAPI_DATAROOTDIR], [varnishapi], [datarootdir])
	PKG_CHECK_VAR([VARNISHAPI_LIBDIR], [varnishapi], [libdir])
	PKG_CHECK_VAR([VARNISHAPI_BINDIR], [varnishapi], [bindir])
	PKG_CHECK_VAR([VARNISHAPI_SBINDIR], [varnishapi], [sbindir])
	PKG_CHECK_VAR([VARNISHAPI_VCLDIR], [varnishapi], [vcldir])
	PKG_CHECK_VAR([VARNISHAPI_VMODDIR], [varnishapi], [vmoddir])

	PKG_CHECK_VAR([VMODTOOL], [varnishapi], [vmodtool])

	AC_SUBST([VARNISH_LIBRARY_PATH],
		[$VARNISHAPI_LIBDIR:$VARNISHAPI_LIBDIR/varnish])

	AC_SUBST([VARNISH_TEST_PATH],
		[$VARNISHAPI_SBINDIR:$VARNISHAPI_BINDIR:$PATH])

	dnl Inherit Varnish's prefix if undefined
	dnl Also the libdir for multi-lib systems
	if test "$prefix" = NONE
	then
		ac_default_prefix=$VARNISHAPI_PREFIX
		libdir=$VARNISHAPI_LIBDIR
	fi

	dnl Define the VCL directory for automake
	vcldir=$($PKG_CONFIG --define-variable=datadir=$datadir \
		--variable=vcldir varnishapi)
	AC_SUBST([vcldir])

	dnl Define the VCL directory for this package
	AC_SUBST([pkgvcldir], [\${vcldir}/\${PACKAGE}])
])

# _VARNISH_CHECK_DEVEL
# --------------------
AC_DEFUN([_VARNISH_CHECK_DEVEL], [

	AC_REQUIRE([_VARNISH_PKG_CONFIG])
	AC_REQUIRE([_VARNISH_CHECK_EXPLICIT_BZERO])

	[_orig_cppflags=$CPPFLAGS]
	[CPPFLAGS=$VARNISHAPI_CFLAGS]

	AC_CHECK_HEADERS([vsha256.h cache/cache.h], [],
		[AC_MSG_ERROR([Missing Varnish development files.])])

	[CPPFLAGS=$_orig_cppflags]
])

# _VARNISH_CHECK_PYTHON
# ---------------------
AC_DEFUN([_VARNISH_CHECK_PYTHON], [

	AM_PATH_PYTHON([2.7], [], [
		AC_MSG_ERROR([Python >= 2.7 is required.])
	])

])

# _VARNISH_VMOD_CONFIG
# --------------------
AC_DEFUN([_VARNISH_VMOD_CONFIG], [

	AC_REQUIRE([_VARNISH_PKG_CONFIG])
	AC_REQUIRE([_VARNISH_CHECK_DEVEL])

	dnl Check the VMOD toolchain
	AC_REQUIRE([AC_LANG_C])
	AC_REQUIRE([AC_PROG_CC_C99])
	AC_REQUIRE([AC_PROG_CPP])
	AC_REQUIRE([AC_PROG_CPP_WERROR])

	_VARNISH_CHECK_PYTHON

	AS_IF([test -z "$RST2MAN"], [
		AC_MSG_ERROR([rst2man is needed to build VMOD manuals.])
	])

	dnl Expose the location of the std and directors VMODs
	AC_SUBST([VARNISHAPI_VMODDIR])

	dnl Expose Varnish's aclocal directory to automake
	AC_SUBST([VARNISHAPI_DATAROOTDIR])

	dnl Define the VMOD directory for libtool
	vmoddir=$($PKG_CONFIG --define-variable=libdir=$libdir \
		--variable=vmoddir varnishapi)
	AC_SUBST([vmoddir])

	dnl Define an automake silent execution for vmodtool
	[am__v_VMODTOOL_0='@echo "  VMODTOOL" $''@;']
	[am__v_VMODTOOL_1='']
	[am__v_VMODTOOL_='$(am__v_VMODTOOL_$(AM_DEFAULT_VERBOSITY))']
	[AM_V_VMODTOOL='$(am__v_VMODTOOL_$(V))']
	AC_SUBST([am__v_VMODTOOL_0])
	AC_SUBST([am__v_VMODTOOL_1])
	AC_SUBST([am__v_VMODTOOL_])
	AC_SUBST([AM_V_VMODTOOL])

	dnl Define VMODs LDFLAGS
	AC_SUBST([VMOD_LDFLAGS],
		"-module -export-dynamic -avoid-version -shared")

	dnl Substitute an alias for compatibility reasons
	AC_SUBST([VMOD_TEST_PATH], [$VARNISH_TEST_PATH])
])

# _VARNISH_VMOD(NAME)
# -------------------
AC_DEFUN([_VARNISH_VMOD], [

	AC_REQUIRE([_VARNISH_VMOD_CONFIG])

	VMOD_FILE="\$(abs_builddir)/.libs/libvmod_$1.so"
	AC_SUBST(m4_toupper(VMOD_$1_FILE), [$VMOD_FILE])

	VMOD_IMPORT="$1 from \\\"$VMOD_FILE\\\""
	AC_SUBST(m4_toupper(VMOD_$1), [$VMOD_IMPORT])

	dnl Define the VCL directory for automake
	AC_SUBST([vmod_$1_vcldir], [\${vcldir}/$1])

	VMOD_RULES="

vmod_$1.lo: vcc_$1_if.c vcc_$1_if.h

vcc_$1_if.h vmod_$1.rst vmod_$1.man.rst: vcc_$1_if.c

vcc_$1_if.c: vmod_$1.vcc
	\$(AM_V_VMODTOOL) \$(PYTHON) \$(VMODTOOL) -o vcc_$1_if \$(srcdir)/vmod_$1.vcc

vmod_$1.3: vmod_$1.man.rst
	\$(A""M_V_GEN) \$(RST2MAN) vmod_$1.man.rst vmod_$1.3

clean: clean-vmod-$1

distclean: clean-vmod-$1

clean-vmod-$1:
	rm -f vcc_$1_if.c vcc_$1_if.h
	rm -f vmod_$1.rst vmod_$1.man.rst vmod_$1.3

"

	AC_SUBST(m4_toupper(BUILD_VMOD_$1), [$VMOD_RULES])
	m4_ifdef([_AM_SUBST_NOTMAKE],
		[_AM_SUBST_NOTMAKE(m4_toupper(BUILD_VMOD_$1))])
])

# VARNISH_VMODS(NAMES)
# --------------------
# Since: Varnish 4.1.4
#
# Since Varnish 5.1.0:
# - vmod_*_vcldir added
#
# Set up the VMOD tool-chain to build the collection of NAMES modules. The
# definition of key variables is made available for use in Makefile rules
# to build the modules:
#
# - VMOD_LDFLAGS (the recommended flags to link VMODs)
# - VMOD_TEST_PATH (an alias for VARNISH_TEST_PATH)
# - VMODTOOL (to generate a VMOD's interface)
# - vmoddir (the install prefix for VMODs)
# - vmod_*_vcldir (the install prefix for the VMODs VCL files)
#
# Configuring your VMOD build with libtool can be as simple as:
#
#     AM_CFLAGS = $(VARNISHAPI_CFLAGS)
#     AM_LDFLAGS = $(VARNISHAPI_LIBS) $(VMOD_LDFLAGS)
#
#     vmod_LTLIBRARIES = libvmod_foo.la
#
#     [...]
#
# Turnkey build rules are generated for each module, they are provided as
# a convenience mechanism but offer no means of customizations. They make
# use of the VMODTOOL variable automatically.
#
# For example, if you define the following in configure.ac:
#
#     VARNISH_VMODS([foo bar])
#
# Two build rules will be available for use in Makefile.am for vmod-foo
# and vmod-bar:
#
#     vmod_LTLIBRARIES = libvmod_foo.la libvmod_bar.la
#
#     [...]
#
#     @BUILD_VMOD_FOO@
#     @BUILD_VMOD_BAR@
#
# These two set of make rules are independent and may be used in separate
# sub-directories. You still need to declare the generated VCC interfaces
# in your library's sources. The generated files can be declared this way:
#
#     nodist_libvmod_foo_la_SOURCES = vcc_foo_if.c vcc_foo_if.h
#     nodist_libvmod_bar_la_SOURCES = vcc_bar_if.c vcc_bar_if.h
#
# The generated rules also build the manual page, all you need to do is to
# declare the generated pages:
#
#     dist_man_MANS = vmod_foo.3 vmod_bar.3
#
# However, it requires RST2MAN to be defined beforehand in configure.ac
# and it is for now the VMOD's maintainer job to manage it. On the other
# hand python detection is done and the resulting PYTHON variable to use
# the VMODTOOL. Since nothing requires RST2MAN to be written in python, it
# is left outside of the scope. You may even define a phony RST2MAN to
# skip man page generation as it is often the case from a dist archive
# (usually /bin/true when the manual is distributed).
#
# Two notable variables are exposed from Varnish's pkg-config:
#
# - VARNISHAPI_VMODDIR (locate vmod-std and vmod-directors in your tests)
# - VARNISHAPI_DATAROOTDIR (for when aclocal is called from a Makefile)
#
# For example in your root Makefile.am:
#
#     ACLOCAL_AMFLAGS = -I m4 -I ${VARNISHAPI_DATAROOTDIR}/aclocal
#
# The VARNISH_VERSION variable will be set even if the VARNISH_PREREQ macro
# wasn't called. Although many things are set up to facilitate out-of-tree
# VMOD maintenance, initialization of autoconf, automake and libtool is
# still the maintainer's responsibility. It cannot be avoided.
#
# Once your VMOD is built, you can use varnishtest to run test cases. For
# that you can rely on automake's default test driver, and all you need
# is a minimal setup:
#
#     AM_TESTS_ENVIRONMENT = \
#         PATH="$(VARNISH_TEST_PATH):$(PATH)" \
#         LD_LIBRARY_PATH="$(VARNISH_LIBRARY_PATH)"
#     TEST_EXTENSIONS = .vtc
#     VTC_LOG_COMPILER = varnishtest -v
#     AM_VTC_LOG_FLAGS = -Dvmod_foo="$(VMOD_FOO)" -Dvmod_bar="$(VMOD_BAR)"
#
# Setting up the different paths is mostly relevant when you aren't building
# against the system installation of Varnish. In the case of the PATH, you
# may also need to preserve the original PATH if you run commands outside of
# the Varnish distribution in your test cases (as shown above).
#
# The $(VMOD_*) variables contain a proper import statement if the relevant
# VMOD was built in the same directory as the test runner. With the example
# above you could import VMODs this way in a test case:
#
#     varnish v1 -vcl+backend {
#         import std;
#         import ${vmod_bar};
#
#         [...]
#     } -start
#
# Once your test suite is set up, all you need is to do is declare your test
# cases and `make check` will work out of the box.
#
#     TESTS = <your VTC files>
#
# At this point almost everything is taken care of, and your autotools-based
# build is ready for prime time. However if you want your VMODs to build and
# run the test suite from a dist archive, don't forget to embed your VCC
# file and the test cases:
#
#     EXTRA_DIST = vmod_foo.vcc vmod_bar.vcc $(TESTS)
#
# If a VMOD is actually a combination of both a library and VCL sub-routines,
# automake directories are available for installation:
#
#     vmod_foo_vcl_DATA = some_addition.vcl
#
# This way the end-user's VCL only needs few lines of code to start using both
# VMODs and VCLs assuming Varnish's default vmod_path and vcl_path were not
# changed:
#
#     vcl 4.0;
#
#     import foo;
#     import bar;
#
#     include "foo/some_addition.vcl";
#
# Now, you can focus on writing this VMOD of yours.
#
AC_DEFUN([VARNISH_VMODS], [
	m4_foreach([_vmod_name],
		m4_split(m4_normalize([$1])),
		[_VARNISH_VMOD(_vmod_name)])
])

# VARNISH_PREREQ(MINIMUM-VERSION, [MAXIMUM-VERSION])
# --------------------------------------------------
# Since: Varnish 4.1.4
#
# Since Varnish 5.1.0:
# - VARNISH_TEST_PATH added
# - VARNISH_LIBRARY_PATH added
# - VARNISHAPI_LIBDIR added
# - VARNISHAPI_VCLDIR added
# - vcldir added
# - pkgvcldir added
#
# Verify that the version of Varnish Cache found by pkg-config is at least
# MINIMUM-VERSION. If MAXIMUM-VERSION is specified, verify that the version
# is strictly below MAXIMUM-VERSION.
#
# Once the requirements are met, the following variables can be used in
# Makefiles:
#
# - VARNISH_TEST_PATH (for the test suite environment)
# - VARNISH_LIBRARY_PATH (for both public and private libraries)
# - VARNISH_VERSION (also available in autoconf)
#
# The following variables are available in autoconf, read from the varnish
# pkg-config:
#
# - VARNISHAPI_CFLAGS
# - VARNISHAPI_LIBS
# - VARNISHAPI_PREFIX
# - VARNISHAPI_DATAROOTDIR
# - VARNISHAPI_LIBDIR
# - VARNISHAPI_BINDIR
# - VARNISHAPI_SBINDIR
# - VARNISHAPI_VCLDIR
# - VARNISHAPI_VMODDIR
# - VMODTOOL
#
# In addition, two directories are set up for installation in automake:
#
# - vcldir
# - pkgvcldir
#
# The vcldir is where Varnish will by default look up VCL files using relative
# paths not found in its sysconfdir (by default /etc/varnish). The pkgvcldir on
# the other hand is a recommended location for your package's VCL files, it
# defaults to "${vcldir}/${PACKAGE}".
#
# This provides a namespace facility for installed VCL files needing including
# other VCL files, which can be overridden if the package name is not desired.
#
AC_DEFUN([VARNISH_PREREQ], [
	AC_REQUIRE([_VARNISH_PKG_CONFIG])
	AC_REQUIRE([_VARNISH_CHECK_EXPLICIT_BZERO])
	AC_MSG_CHECKING([for Varnish])
	AC_MSG_RESULT([$VARNISH_VERSION])

	AS_VERSION_COMPARE([$VARNISH_VERSION], [$1], [
		AC_MSG_ERROR([Varnish version $1 or higher is required.])
	])

	test $# -gt 1 &&
	AS_VERSION_COMPARE([$2], [$VARNISH_VERSION], [
		AC_MSG_ERROR([Varnish version below $2 is required.])
	])
])
