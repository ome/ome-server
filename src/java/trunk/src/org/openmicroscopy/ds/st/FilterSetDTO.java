/*
 * org.openmicroscopy.ds.st.FilterSetDTO
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
 * Created by dcreager via omejava on Wed Feb 18 17:57:29 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Filter;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class FilterSetDTO
    extends AttributeDTO
    implements FilterSet
{
    public FilterSetDTO() { super(); }
    public FilterSetDTO(Map elements) { super(elements); }

    public String getManufacturer()
    { return getStringElement("Manufacturer"); }
    public void setManufacturer(String value)
    { setElement("Manufacturer",value); }

    public String getModel()
    { return getStringElement("Model"); }
    public void setModel(String value)
    { setElement("Model",value); }

    public String getLotNumber()
    { return getStringElement("LotNumber"); }
    public void setLotNumber(String value)
    { setElement("LotNumber",value); }

    public Filter getFilter()
    { return (Filter) getObjectElement("Filter"); }
    public void setFilter(Filter value)
    { setElement("Filter",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Filter",FilterDTO.class);
    }

}
