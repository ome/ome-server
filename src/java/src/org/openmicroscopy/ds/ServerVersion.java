/*
 * org.openmicroscopy.ds.ServerVersion
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */


/*------------------------------------------------------------------------------
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds;

/**
 * <p>Encapsulates a server version returned from the remote API.
 * Client applications can use this class to ensure that the server
 * that is being connected to is of the appropriate version.</p>
 *
 * <p>Code to perform this check usually looks like the following:</p>
 *
 * <pre>RemoteCaller rc = // however you retrieve your caller;
 * ServerVersion current = rc.getServerVersion();
 * ServerVersion want = new ServerVersion(2,2,1);  // to request v2.2.1
 *
 * if (current == null)
 *   // server did not return a version; assume it's an old server
 * else if (current.isAtLeast(want))
 *   // this server is at least the version you want
 * else
 *   // this server is older than what was requested</pre>
 *
 * @see RemoteCaller#getServerVersion
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2.1 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2.1
 */

public class ServerVersion
{
    private int major, minor, patch;

    /**
     * Creates a new instance of the <code>ServerVersion</code> class.
     */
    public ServerVersion(int major, int minor, int patch)
    {
        super();
        this.major = major;
        this.minor = minor;
        this.patch = patch;
    }

    /**
     * Returns this version's major version portion
     */
    public int getMajorVersion() { return major; }

    /**
     * Returns this version's minor version portion
     */
    public int getMinorVersion() { return minor; }

    /**
     * Returns this version's patch version portion
     */
    public int getPatchVersion() { return patch; }

    /**
     * <p>Checks that this version is backwards-compatible with the
     * <code>version</code> parameter.  In order to be backwards
     * compatible, the mahor versions must match, and the
     * "minor.patch" value of this version must be greater than or
     * equal to <code>version</code>'s.</p>
     *
     * <p>For example:</p>
     *
     * <ul>
     * <li>2.2.1 &gt;= 2.0.0</li>
     * <li>2.2.1 &gt;= 2.1.5</li>
     * <li>2.2.1 &gt;= 2.2.0</li>
     * <li>2.2.1 <i>is not</i> &gt;= 2.2.5</li>
     * <li>2.2.1 <i>is not</i> &gt;= 2.3.0</li>
     * <li>2.2.1 <i>is not</i> &gt;= 3.0.0</li>
     * </ul>
     */
    public boolean isAtLeast(ServerVersion version)
    {
        /* The major version numbers must be equal */
        if (this.major != version.major)
            return false;

        /* The minor version number must be at least the one
         * specified */
        if (this.minor < version.minor)
            return false;

        /* We only need to check the patch version if the minor
         * versions are equal */
        if (this.minor > version.minor)
            return true;

        /* The patch version number must be at least the one
         * specified */
        if (this.patch < version.patch)
            return false;

        return true;
    }

    /**
     * Returns a {@link String} representation of this version
     */
    public String toString()
    {
        return major+"."+minor+"."+patch;
    }
}
