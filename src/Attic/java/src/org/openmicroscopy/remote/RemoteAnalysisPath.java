/*
 * org.openmicroscopy.remote.RemoteAnalysisPath
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
 *
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.util.List;
//import java.util.ArrayList;
import java.util.Iterator;

public class RemoteAnalysisPath
    extends RemoteOMEObject
    implements AnalysisPath
{
    static
    {
        addClass("OME::AnalysisPath",
                 RemoteAnalysisPath.class);
        addClass("OME::AnalysisPath::Map",
                 RemoteAnalysisPath.Node.class);
    }


    public RemoteAnalysisPath() { super(); }
    public RemoteAnalysisPath(String reference) { super(reference); }

    public int getPathLength()
    { return getIntElement("path_length"); }
    public void setPathLength(int pathLength)
    { setIntElement("path_length",pathLength); }

    public Chain getChain()
    { return (Chain)
            getRemoteElement(getClass("OME::AnalysisChain"),
                             "analysis_chain"); }
    public void setChain(Chain chain)
    { setRemoteElement("analysis_chain",chain); }

    public List getPathNodes()
    { return getRemoteListElement(getClass("OME::AnalysisPath::Map"),
                                  "path_nodes"); }
    public Iterator iteratePathNodes()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_path_nodes");
        i.setClass(getClass("OME::AnalysisPath::Map"));
        return i;
    }

    public static class Node
        extends RemoteOMEObject
        implements AnalysisPath.Node
    {
        public Node() { super(); }
        public Node(String reference) { super(reference); }

        public AnalysisPath getAnalysisPath()
        { return (AnalysisPath)
                getRemoteElement(getClass("OME::AnalysisPath"),
                                 "path"); }

        public int getPathOrder()
        { return getIntElement("path_order"); }
        public void setPathOrder(int pathOrder)
        { setIntElement("path_order",pathOrder); }


        public Chain.Node getChainNode()
        { return (Chain.Node)
                getRemoteElement(getClass("OME::AnalysisChain::Node"),
                                 "analysis_chain_node"); }
        public void setChainNode(Chain.Node chainNode)
        { setRemoteElement("analysis_chain_node",chainNode); }

    }
}
