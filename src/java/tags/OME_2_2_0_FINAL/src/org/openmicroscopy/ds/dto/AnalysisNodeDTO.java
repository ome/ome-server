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
 * Created by dcreager via omejava on Tue Feb 24 17:23:09 2004
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
    { return (AnalysisChain) getObjectElement("analysis_chain"); }
    public void setChain(AnalysisChain value)
    { setElement("analysis_chain",value); }

    public Module getModule()
    { return (Module) getObjectElement("module"); }
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
    { return (List) getObjectElement("input_links"); }
    public int countInputLinks()
    { return countListElement("input_links"); }

    public List getOutputLinks()
    { return (List) getObjectElement("output_links"); }
    public int countOutputLinks()
    { return countListElement("output_links"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("analysis_chain",AnalysisChainDTO.class);
        parseChildElement("module",ModuleDTO.class);
        parseListElement("input_links",AnalysisLinkDTO.class);
        parseListElement("output_links",AnalysisLinkDTO.class);
    }

}