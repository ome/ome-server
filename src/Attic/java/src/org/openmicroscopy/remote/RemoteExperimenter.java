/*
 * org.openmicroscopy.remote.RemoteExperimenter
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy.remote;

import org.openmicroscopy.Experimenter;

public class RemoteExperimenter
    extends RemoteObject
    implements Experimenter
{
    static { RemoteObject.addClass("OME::Experimenter",RemoteExperimenter.class); }

    public RemoteExperimenter() { super(); }
    public RemoteExperimenter(String reference) { super(reference); }

    public int getID()
    { return ((Integer) caller.dispatch(this,"id")).intValue(); }

    public String getOMEName()
    { return caller.dispatch(this,"ome_name").toString(); }
    public void setOMEName(String name)
    { caller.dispatch(this,"ome_name",name); }

    public String getFirstName()
    { return caller.dispatch(this,"firstname").toString(); }
    public void setFirstName(String name)
    { caller.dispatch(this,"firstname",name); }

    public String getLastName()
    { return caller.dispatch(this,"lastname").toString(); }
    public void setLastName(String name)
    { caller.dispatch(this,"lastname",name); }

    public String getEmail()
    { return caller.dispatch(this,"email").toString(); }
    public void setEmail(String name)
    { caller.dispatch(this,"email",name); }

    public String getDataDir()
    { return caller.dispatch(this,"data_dir").toString(); }
    public void setDataDir(String name)
    { caller.dispatch(this,"data_dir",name); }

}
