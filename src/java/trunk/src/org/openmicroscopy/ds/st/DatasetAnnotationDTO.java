/*
 * org.openmicroscopy.ds.st.DatasetAnnotationDTO
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
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class DatasetAnnotationDTO
    extends AttributeDTO
    implements DatasetAnnotation
{
    public DatasetAnnotationDTO() { super(); }
    public DatasetAnnotationDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@DatasetAnnotation"; }
    public Class getDTOType() { return DatasetAnnotation.class; }

    public Long getTimestamp()
    { return getLongElement("Timestamp"); }
    public void setTimestamp(Long value)
    { setElement("Timestamp",value); }

    public String getContent()
    { return getStringElement("Content"); }
    public void setContent(String value)
    { setElement("Content",value); }

    public Experimenter getExperimenter()
    { return (Experimenter) getObjectElement("Experimenter"); }
    public void setExperimenter(Experimenter value)
    { setElement("Experimenter",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Experimenter",ExperimenterDTO.class);
    }

}
