/*
 * org.openmicroscopy.Factory
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

package org.openmicroscopy;

import java.util.Map;
import java.util.List;
import java.util.Iterator;

public interface Factory
{
    public OMEObject newObject(String className, Map data);
    public OMEObject loadObject(String className, int id);
    public boolean objectExists(String className, Map criteria);
    public OMEObject findObject(String className, Map criteria);
    public List findObjects(String className, Map criteria);
    public Iterator iterateObjects(String className, Map criteria);
    public OMEObject findObjectLike(String className, Map criteria);
    public List findObjectsLike(String className, Map criteria);
    public Iterator iterateObjectsLike(String className, Map criteria);
    public Attribute newAttribute(String typeName,
                                  OMEObject target,
                                  ModuleExecution analysis,
                                  Map data);
    public Attribute loadAttribute(String typeName, int id);
    public List findAttributes(String typeName, OMEObject target);
}
