/*
 * org.openmicroscopy.ds.st.CategoryGroupDTO
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
 * Created by dcreager via omejava on Tue Mar 16 15:54:10 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Category;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class CategoryGroupDTO
    extends AttributeDTO
    implements CategoryGroup
{
    public CategoryGroupDTO() { super(); }
    public CategoryGroupDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@CategoryGroup"; }
    public Class getDTOType() { return CategoryGroup.class; }

    public String getDescription()
    { return getStringElement("Description"); }
    public void setDescription(String value)
    { setElement("Description",value); }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public List getCategories()
    { return (List) getObjectElement("Categories"); }
    public int countCategories()
    { return countListElement("Categories"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseListElement("Categories",CategoryDTO.class);
    }

}
