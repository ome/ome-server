/*
 * org.openmicroscopy.ds.st.Category3DTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:06 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.CategoryGroup3;
import org.openmicroscopy.ds.st.CategoryRef3;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class Category3DTO
    extends AttributeDTO
    implements Category3
{
    public Category3DTO() { super(); }
    public Category3DTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Category3"; }
    public Class getDTOType() { return Category3.class; }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public CategoryGroup3 getCategoryGroup3()
    { return (CategoryGroup3) parseChildElement("CategoryGroup3",CategoryGroup3DTO.class); }
    public void setCategoryGroup3(CategoryGroup3 value)
    { setElement("CategoryGroup3",value); }

    public List getCategoryRef3List()
    { return (List) parseListElement("CategoryRef3List",CategoryRef3DTO.class); }
    public int countCategoryRef3List()
    { return countListElement("CategoryRef3List"); }


}
