/*
 * org.openmicroscopy.ds.dto.AnalysisNodeDTO
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
 * Created by hochheiserha via omejava on Mon May  2 15:18:38 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class AnalysisNodeDTO
    extends MappedDTO
    implements AnalysisNode
{
    public AnalysisNodeDTO() { super(); }
    public AnalysisNodeDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "AnalysisNode"; }
    public Class getDTOType() { return AnalysisNode.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public AnalysisChain getChain()
    { return (AnalysisChain) parseChildElement("analysis_chain",AnalysisChainDTO.class); }
    public void setChain(AnalysisChain value)
    { setElement("analysis_chain",value); }

    public Module getModule()
    { return (Module) parseChildElement("module",ModuleDTO.class); }
    public void setModule(Module value)
    { setElement("module",value); }

    public String getIteratorTag()
    { return getStringElement("iterator_tag"); }
    public void setIteratorTag(String value)
    { setElement("iterator_tag",value); }

    public String getNewFeatureTag()
    { return getStringElement("new_feature_tag"); }
    public void setNewFeatureTag(String value)
    { setElement("new_feature_tag",value); }

    public List getInputLinks()
    { return (List) parseListElement("input_links",AnalysisLinkDTO.class); }
    public int countInputLinks()
    { return countListElement("input_links"); }

    public List getOutputLinks()
    { return (List) parseListElement("output_links",AnalysisLinkDTO.class); }
    public int countOutputLinks()
    { return countListElement("output_links"); }


}
