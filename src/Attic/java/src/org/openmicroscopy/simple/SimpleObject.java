/*
 * org.openmicroscopy.simple.SimpleObject
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

package org.openmicroscopy.simple;

import org.openmicroscopy.OMEObject;
import org.openmicroscopy.Session;

public class SimpleObject
    implements OMEObject
{
    protected int id;

    public SimpleObject() {}

    public SimpleObject(int id)
    {
        this.id = id;
    }

    public int getID() { return id; }
    public void writeObject() {}
    public Session getSession()
    {
        throw new UnsupportedOperationException("There is no SimpleSession");
    }
}
