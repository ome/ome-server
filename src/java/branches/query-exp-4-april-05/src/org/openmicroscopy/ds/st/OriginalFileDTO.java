/*
 * org.openmicroscopy.ds.st.OriginalFileDTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:03 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Repository;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class OriginalFileDTO
    extends AttributeDTO
    implements OriginalFile
{
    public OriginalFileDTO() { super(); }
    public OriginalFileDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@OriginalFile"; }
    public Class getDTOType() { return OriginalFile.class; }

    public String getFormat()
    { return getStringElement("Format"); }
    public void setFormat(String value)
    { setElement("Format",value); }

    public Repository getRepository()
    { return (Repository) parseChildElement("Repository",RepositoryDTO.class); }
    public void setRepository(Repository value)
    { setElement("Repository",value); }

    public String getSHA1()
    { return getStringElement("SHA1"); }
    public void setSHA1(String value)
    { setElement("SHA1",value); }

    public String getPath()
    { return getStringElement("Path"); }
    public void setPath(String value)
    { setElement("Path",value); }

    public Long getFileID()
    { return getLongElement("FileID"); }
    public void setFileID(Long value)
    { setElement("FileID",value); }


}
