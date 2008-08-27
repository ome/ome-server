/*
 * org.openmicroscopy.ds.st.CategoryDTO
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
 * Created by hochheiserha via omejava on Mon May  2 15:12:25 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.CategoryGroup;
import org.openmicroscopy.ds.st.Classification;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class CategoryDTO
    extends AttributeDTO
    implements Category
{
    public CategoryDTO() { super(); }
    public CategoryDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Category"; }
    public Class getDTOType() { return Category.class; }

    public String getDescription()
    { return getStringElement("Description"); }
    public void setDescription(String value)
    { setElement("Description",value); }

    public CategoryGroup getCategoryGroup()
    { return (CategoryGroup) parseChildElement("CategoryGroup",CategoryGroupDTO.class); }
    public void setCategoryGroup(CategoryGroup value)
    { setElement("CategoryGroup",value); }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public List getClassificationList()
    { return (List) parseListElement("ClassificationList",ClassificationDTO.class); }
    public int countClassificationList()
    { return countListElement("ClassificationList"); }


}
