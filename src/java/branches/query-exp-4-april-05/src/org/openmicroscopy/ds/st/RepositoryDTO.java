/*
 * org.openmicroscopy.ds.st.RepositoryDTO
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
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.st.OriginalFile;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.st.PixelsPlane;
import org.openmicroscopy.ds.st.Thumbnail;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class RepositoryDTO
    extends AttributeDTO
    implements Repository
{
    public RepositoryDTO() { super(); }
    public RepositoryDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@Repository"; }
    public Class getDTOType() { return Repository.class; }

    public Boolean isLocal()
    { return getBooleanElement("Local"); }
    public void setLocal(Boolean value)
    { setElement("Local",value); }

    public String getImageServerURL()
    { return getStringElement("ImageServerURL"); }
    public void setImageServerURL(String value)
    { setElement("ImageServerURL",value); }

    public String getPath()
    { return getStringElement("Path"); }
    public void setPath(String value)
    { setElement("Path",value); }

    public List getOTFList()
    { return (List) parseListElement("OTFList",OTFDTO.class); }
    public int countOTFList()
    { return countListElement("OTFList"); }

    public List getOriginalFileList()
    { return (List) parseListElement("OriginalFileList",OriginalFileDTO.class); }
    public int countOriginalFileList()
    { return countListElement("OriginalFileList"); }

    public List getPixelsList()
    { return (List) parseListElement("PixelsList",PixelsDTO.class); }
    public int countPixelsList()
    { return countListElement("PixelsList"); }

    public List getPixelsPlaneList()
    { return (List) parseListElement("PixelsPlaneList",PixelsPlaneDTO.class); }
    public int countPixelsPlaneList()
    { return countListElement("PixelsPlaneList"); }

    public List getThumbnailList()
    { return (List) parseListElement("ThumbnailList",ThumbnailDTO.class); }
    public int countThumbnailList()
    { return countListElement("ThumbnailList"); }


}
