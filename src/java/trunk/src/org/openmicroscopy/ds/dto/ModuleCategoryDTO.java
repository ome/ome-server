/*
 * org.openmicroscopy.ds.dto.ModuleCategoryDTO
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
 * Created by dcreager via omejava on Thu Feb 12 14:34:47 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class ModuleCategoryDTO
    extends MappedDTO
    implements ModuleCategory
{
    public ModuleCategoryDTO() { super(); }
    public ModuleCategoryDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "ModuleCategory"; }
    public Class getDTOType() { return ModuleCategory.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String value)
    { setElement("name",value); }

    public ModuleCategory getParentCategory()
    { return (ModuleCategory) getObjectElement("parent_category"); }
    public void setParentCategory(ModuleCategory value)
    { setElement("parent_category",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public List getChildCategories()
    { return (List) getObjectElement("children"); }
    public int countChildCategories()
    { return countListElement("children"); }

    public List getModules()
    { return (List) getObjectElement("modules"); }
    public int countModules()
    { return countListElement("modules"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("parent_category",ModuleCategoryDTO.class);
        parseListElement("children",ModuleCategoryDTO.class);
        parseListElement("modules",ModuleDTO.class);
    }

}
