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
 * Created by dcreager via omejava on Wed Feb 11 16:07:59 2004
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

    public boolean isLocal()
    { return getBooleanElement("Local"); }
    public void setLocal(boolean value)
    { setElement("Local",new Boolean(value)); }

    public String getPath()
    { return getStringElement("Path"); }
    public void setPath(String value)
    { setElement("Path",value); }

    public String getImageServerURL()
    { return getStringElement("ImageServerURL"); }
    public void setImageServerURL(String value)
    { setElement("ImageServerURL",value); }

    public List getOTFs()
    { return (List) getObjectElement("OTFs"); }
    public int countOTFs()
    { return countListElement("OTFs"); }

    public List getOriginalFiles()
    { return (List) getObjectElement("OriginalFiles"); }
    public int countOriginalFiles()
    { return countListElement("OriginalFiles"); }

    public List getPixelses()
    { return (List) getObjectElement("Pixelses"); }
    public int countPixelses()
    { return countListElement("Pixelses"); }

    public List getPixelsPlanes()
    { return (List) getObjectElement("PixelsPlanes"); }
    public int countPixelsPlanes()
    { return countListElement("PixelsPlanes"); }

    public List getThumbnails()
    { return (List) getObjectElement("Thumbnails"); }
    public int countThumbnails()
    { return countListElement("Thumbnails"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseListElement("OTFs",OTFDTO.class);
        parseListElement("OriginalFiles",OriginalFileDTO.class);
        parseListElement("Pixelses",PixelsDTO.class);
        parseListElement("PixelsPlanes",PixelsPlaneDTO.class);
        parseListElement("Thumbnails",ThumbnailDTO.class);
    }

}
