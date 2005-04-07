/*
 * org.openmicroscopy.ds.dto.NodeExecutionDTO
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by hochheiserha via omejava on Thu Apr  7 10:49:34 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class NodeExecutionDTO
    extends MappedDTO
    implements NodeExecution
{
    public NodeExecutionDTO() { super(); }
    public NodeExecutionDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "NodeExecution"; }
    public Class getDTOType() { return NodeExecution.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public ChainExecution getChainExecution()
    { return (ChainExecution) parseChildElement("analysis_chain_execution",ChainExecutionDTO.class); }
    public void setChainExecution(ChainExecution value)
    { setElement("analysis_chain_execution",value); }

    public AnalysisNode getNode()
    { return (AnalysisNode) parseChildElement("analysis_chain_node",AnalysisNodeDTO.class); }
    public void setNode(AnalysisNode value)
    { setElement("analysis_chain_node",value); }

    public ModuleExecution getModuleExecution()
    { return (ModuleExecution) parseChildElement("module_execution",ModuleExecutionDTO.class); }
    public void setModuleExecution(ModuleExecution value)
    { setElement("module_execution",value); }


}
