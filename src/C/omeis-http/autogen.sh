#!/bin/sh
#
#  Copyright (C) 2003 Open Microscopy Environment
#      Massachusetts Institute of Technology,
#      National Institutes of Health,
#      University of Dundee
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# This is here purely for Gentoo users like myself that have weird Automake
# compatability wrappers. -- 1.6 should be sufficient, you may need to tweak
# it for your particular system. -- Chris Allan <callan@blackcat.ca>
export WANT_AUTOMAKE="1.6"

(automake --version) < /dev/null > /dev/null 2>&1 || {
	echo;
	echo "You must have automake installed to compile OMEIS";
	echo;
	exit;
}

(autoconf --version) < /dev/null > /dev/null 2>&1 || {
	echo;
	echo "You must have autoconf installed to compile OMEIS";
	echo;
	exit;
}

echo "Generating configuration files for OMEIS, please wait...."
echo;

aclocal $ACLOCAL_FLAGS || exit;
autoheader || exit;
automake --add-missing --copy;
autoconf || exit;
automake || exit;
./configure $@
