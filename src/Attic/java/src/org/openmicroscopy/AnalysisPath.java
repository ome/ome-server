/*
 * org.openmicroscopy.AnalysisPath
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

public interface AnalysisPath
    extends OMEObject
{
    public int getPathLength();
    public void setPathLength(int length);

    public Chain getChain();
    public void setChain(Chain chain);

    public List getPathNodes();
    public Iterator iteratePathNodes();

    public interface Node
        extends OMEObject
    {
        public int getPathOrder();
        public void setPathOrder(int order);

        public AnalysisPath getAnalysisPath();

        public Chain.Node getChainNode();
        public void setChainNode(Chain.Node node);
    }
}
