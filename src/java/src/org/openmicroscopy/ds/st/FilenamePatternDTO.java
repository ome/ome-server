/*
 * org.openmicroscopy.ds.st.FilenamePatternDTO
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
 * Created by hochheiserha via omejava on Thu Sep  8 14:15:01 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class FilenamePatternDTO
    extends AttributeDTO
    implements FilenamePattern
{
    public FilenamePatternDTO() { super(); }
    public FilenamePatternDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@FilenamePattern"; }
    public Class getDTOType() { return FilenamePattern.class; }

    public Integer getTheC()
    { return getIntegerElement("TheC"); }
    public void setTheC(Integer value)
    { setElement("TheC",value); }

    public Integer getTheT()
    { return getIntegerElement("TheT"); }
    public void setTheT(Integer value)
    { setElement("TheT",value); }

    public Integer getTheZ()
    { return getIntegerElement("TheZ"); }
    public void setTheZ(Integer value)
    { setElement("TheZ",value); }

    public String getBaseName()
    { return getStringElement("BaseName"); }
    public void setBaseName(String value)
    { setElement("BaseName",value); }

    public String getName()
    { return getStringElement("Name"); }
    public void setName(String value)
    { setElement("Name",value); }

    public String getRegEx()
    { return getStringElement("RegEx"); }
    public void setRegEx(String value)
    { setElement("RegEx",value); }

    public String getFormat()
    { return getStringElement("Format"); }
    public void setFormat(String value)
    { setElement("Format",value); }


}
