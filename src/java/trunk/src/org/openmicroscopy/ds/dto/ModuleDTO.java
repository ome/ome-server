/*
 * org.openmicroscopy.ds.dto.ModuleDTO
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

public class ModuleDTO
    extends MappedDTO
    implements Module
{
    public ModuleDTO() { super(); }
    public ModuleDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "Module"; }
    public Class getDTOType() { return Module.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String value)
    { setElement("name",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public String getModuleType()
    { return getStringElement("module_type"); }
    public void setModuleType(String value)
    { setElement("module_type",value); }

    public String getLocation()
    { return getStringElement("location"); }
    public void setLocation(String value)
    { setElement("location",value); }

    public ModuleCategory getCategory()
    { return (ModuleCategory) getObjectElement("category"); }
    public void setCategory(ModuleCategory value)
    { setElement("category",value); }

    public String getDefaultIterator()
    { return getStringElement("default_iterator"); }
    public void setDefaultIterator(String value)
    { setElement("default_iterator",value); }

    public String getNewFeatureTag()
    { return getStringElement("new_feature_tag"); }
    public void setNewFeatureTag(String value)
    { setElement("new_feature_tag",value); }

    public List getFormalInputs()
    { return (List) getObjectElement("inputs"); }
    public int countFormalInputs()
    { return countListElement("inputs"); }

    public List getFormalOutputs()
    { return (List) getObjectElement("outputs"); }
    public int countFormalOutputs()
    { return countListElement("outputs"); }

    public List getExecutions()
    { return (List) getObjectElement("executions"); }
    public int countExecutions()
    { return countListElement("executions"); }

    public String getExecutionInstructions()
    { return getStringElement("execution_instructions"); }
    public void setExecutionInstructions(String value)
    { setElement("execution_instructions",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("category",ModuleCategoryDTO.class);
        parseListElement("inputs",FormalInputDTO.class);
        parseListElement("outputs",FormalOutputDTO.class);
        parseListElement("executions",ModuleExecutionDTO.class);
    }

}
