#!/bin/sh

# $Id: Setup.sh,v 1.13 2008/01/30 20:02:10 cph Exp $
#
# Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
#     1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004,
#     2005, 2006, 2007, 2008 Massachusetts Institute of Technology
#
# This file is part of MIT/GNU Scheme.
#
# MIT/GNU Scheme is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# MIT/GNU Scheme is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MIT/GNU Scheme; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301, USA.

# Program to set up MIT/GNU Scheme microcode from CVS for distribution.
# Requires `gcc' and `scheme'.

set -e

if [ ! -f config.h.in ]; then
    echo "autoheader"
    autoheader
fi
if [ ! -x configure ]; then
    echo "autoconf"
    autoconf
fi
( cd cmpauxmd && make "${@}" )
if [ ! -f Makefile.in ]; then
    makegen/makeinit.sh "${@}"
fi
