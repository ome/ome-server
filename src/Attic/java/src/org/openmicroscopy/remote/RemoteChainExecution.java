/*
 * org.openmicroscopy.remote.RemoteChainExecution
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

import org.openmicroscopy.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

public class RemoteChainExecution
    extends RemoteOMEObject
    implements ChainExecution
{
    static { RemoteObject.addClass("OME::ChainExecution",
                                   RemoteChainExecution.class); }

    public RemoteChainExecution() { super(); }
    public RemoteChainExecution(String reference) { super(reference); }

    public String getTimestamp()
    { return getStringElement("timestamp"); }
    public void setTimestamp(String timestamp)
    { setStringElement("timestamp",timestamp); }

    public Chain getChain()
    { return (Chain) getRemoteElement(RemoteChain.class,"analysis_view"); }
    public void setChain(Chain chain)
    { setRemoteElement("analysis_view",chain); }

    public Dataset getDataset()
    { return (Dataset) getRemoteElement(RemoteDataset.class,"dataset"); }
    public void setDataset(Dataset dataset)
    { setRemoteElement("dataset",dataset); }

    public Attribute getExperimenter()
    { return getAttributeElement("experimenter"); }
    public void setExperimenter(Attribute experimenter)
    { setAttributeElement("experimenter",experimenter); }

    public List getNodes()
    { return getRemoteListElement(Node.class,"node_executions"); }
    public Iterator iterateNodes()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(RemoteIterator.class,
                             "iterate_node_executions");
        i.setClass(Node.class);
        return i;
    }

    public static class Node
        extends RemoteOMEObject
        implements ChainExecution.Node
    {
        static { RemoteObject.addClass("OME::AnalysisExecution::NodeExecution",
                                       RemoteChainExecution.Node.class); }

        public Node() { super(); }
        public Node(String reference) { super(reference); }

        public ChainExecution getChainExecution()
        { return (ChainExecution)
              getRemoteElement(RemoteChainExecution.class,"analysis_execution"); }

        public Chain.Node getChainNode()
        { return (Chain.Node)
              getRemoteElement(RemoteChain.Node.class,"analysis_view_node"); }
        public void setChainNode(Chain.Node chainNode)
        { setRemoteElement("analysis_view_node",chainNode); }

        public Analysis getAnalysis()
        { return (Analysis)
              getRemoteElement(RemoteAnalysis.class,"analysis"); }
        public void setAnalysis(Analysis analysis)
        { setRemoteElement("analysis",analysis); }

    }
}
