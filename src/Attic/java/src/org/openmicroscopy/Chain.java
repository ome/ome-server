/*
 * org.openmicroscopy.Chain
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

import java.util.List;
import java.util.Iterator;

public interface Chain
    extends OMEObject
{
    public Attribute getOwner();
    public void setOwner(Attribute owner);

    public String getName();
    public void setName(String name);

    public String getDescription();
    public void setDescription(String name);

    public boolean getLocked();
    public void setLocked(boolean locked);

    public List getNodes();
    public Iterator iterateNodes();

    public List getLinks();
    public Iterator iterateLinks();

    public List getPaths();
    public Iterator iteratePaths();
    
    public interface Node
        extends OMEObject
    {
        public Chain getChain();

        public Module getModule(); 
        public void setModule(Module module);

        public String getIteratorTag();
        public void setIteratorTag(String iteratorTag);

        public String getNewFeatureTag();
        public void setNewFeatureTag(String newFeatureTag);

        public List getInputLinks();
        public Iterator iterateInputLinks();

        public List getOutputLinks();
        public Iterator iterateOutputLinks();
    }


    public interface Link
        extends OMEObject
    {
        public Chain getChain();

        public Node getFromNode(); 
        public void setFromNode(Node fromNode);

        public Module.FormalOutput getFromOutput();
        public void setFromOutput(Module.FormalOutput fromOutput);

        public Node getToNode();
        public void setToNode(Node toNode);

        public Module.FormalInput getToInput();
        public void setToInput(Module.FormalInput toInput);
    }
}
