/*
 * org.openmicroscopy.remote.RemoteChainExecution
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

public class RemoteChainExecution
    extends RemoteOMEObject
    implements ChainExecution
{
    static
    {
        addClass("OME::AnalysisChainExecution",
                 RemoteChainExecution.class);
        addClass("OME::AnalysisChainExecution::NodeExecution",
                 RemoteChainExecution.Node.class);
    }


    public RemoteChainExecution() { super(); }
    public RemoteChainExecution(String reference) { super(reference); }

    public String getTimestamp()
    { return getStringElement("timestamp"); }
    public void setTimestamp(String timestamp)
    { setStringElement("timestamp",timestamp); }

    public Chain getChain()
    { return (Chain) getRemoteElement(getClass("OME::AnalysisChain"),
                                      "analysis_chain"); }
    public void setChain(Chain chain)
    { setRemoteElement("analysis_chain",chain); }

    public Dataset getDataset()
    { return (Dataset) getRemoteElement(getClass("OME::Dataset"),
                                        "dataset"); }
    public void setDataset(Dataset dataset)
    { setRemoteElement("dataset",dataset); }

    public Attribute getExperimenter()
    { return getAttributeElement("experimenter"); }
    public void setExperimenter(Attribute experimenter)
    { setAttributeElement("experimenter",experimenter); }

    public List getNodes()
    { return getRemoteListElement(getClass("OME::AnalysisChainExecution::NodeExecution"),
                                  "node_executions"); }
    public Iterator iterateNodes()
    {
        RemoteIterator i = (RemoteIterator)
            getRemoteElement(getClass("OME::Factory::Iterator"),
                             "iterate_node_executions");
        i.setClass(getClass("OME::AnalysisChainExecution::NodeExecution"));
        return i;
    }

    public static class Node
        extends RemoteOMEObject
        implements ChainExecution.Node
    {
        public Node() { super(); }
        public Node(String reference) { super(reference); }

        public ChainExecution getChainExecution()
        { return (ChainExecution)
                getRemoteElement(getClass("OME::AnalysisChainExecution"),
                                 "analysis_execution"); }

        public Chain.Node getChainNode()
        { return (Chain.Node)
                getRemoteElement(getClass("OME::AnalysisChain::Node"),
                                 "analysis_chain_node"); }
        public void setChainNode(Chain.Node chainNode)
        { setRemoteElement("analysis_chain_node",chainNode); }

        public ModuleExecution getModuleExecution()
        { return (ModuleExecution)
                getRemoteElement(getClass("OME::ModuleExecution"),
                                 "module_execution"); }
        public void setModuleExecution(ModuleExecution moduleExecution)
        { setRemoteElement("module_execution",moduleExecution); }

    }
}
