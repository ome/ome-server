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
{
    public String getOwner();
    public void setOwner(String owner);

    public String getName();
    public void setName(String name);

    public boolean getLocked();
    public void setLocked(boolean locked);


    public int getNumNodes();
    public Node getNode(int index);
    public Iterator getNodeIterator();
    public List getNodes();

    public Node addNode(Module module,
                        String iteratorTag,
                        String newFeatureTag);


    public int getNumLinks();
    public Link getLink(int index);
    public Iterator getLinkIterator();
    public List getLinks();

    public Link addLink(Node                fromNode,
                        Module.FormalOutput fromOutput,
                        Node                toNode,
                        Module.FormalInput  toInput);

    
    public interface Node
    {
        public Chain getChain();

        public Module getModule(); 
        public void setModule(Module module);

        public String getIteratorTag();
        public void setIteratorTag(String iteratorTag);

        public String getNewFeatureTag();
        public void setNewFeatureTag(String newFeatureTag);
    }


    public interface Link
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
