#!/bin/sh
#
# OMEtouch.sh
# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Brian S. Hughes
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

# Script to insure that directories needed by Apache to run OME exist.
#
# Run this script once immediately after OME is installed, but before
# the OME database is created by bootstrapOME.pl, to create
# OME's Apache directories.
#
# On RedHat Linux, place this script in /etc/cron.daily. This will insure
# that when cron runs tmpwatch, old files in these directories will get
# cleaned up, but the directories themselves will remain.
#
# For other OS.s that automatically clean /var/tmp, put this script in the
# appropriate daily cron directory.

if [ -d /var/tmp/OME ]
then
    touch /var/tmp/OME
else
    mkdir /var/tmp/OME
fi

if [ -d /var/tmp/OME/lock ]
then
    touch /var/tmp/OME/lock
else
    mkdir /var/tmp/OME/lock
fi

if [ -d /var/tmp/OME/sessions ]
then
    touch /var/tmp/OME/sessions
else
    mkdir /var/tmp/OME/sessions
fi

# FIXME:  apche needs access, and should probably be owned by the apache user.
# Command-line sessions (owwned by the user executing them) can't acess this then
# Do they need to?
chmod -R 0777 /var/tmp/OME


