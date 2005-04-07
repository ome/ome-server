/*
 * org.openmicroscopy.ds.st.Repository
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
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Repository
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Local</code> */
    public Boolean isLocal();
    public void setLocal(Boolean value);

    /** Criteria field name: <code>ImageServerURL</code> */
    public String getImageServerURL();
    public void setImageServerURL(String value);

    /** Criteria field name: <code>Path</code> */
    public String getPath();
    public void setPath(String value);

    /** Criteria field name: <code>OTFList</code> */
    public List getOTFList();
    /** Criteria field name: <code>#OTFList</code> or <code>OTFListList</code> */
    public int countOTFList();

    /** Criteria field name: <code>OriginalFileList</code> */
    public List getOriginalFileList();
    /** Criteria field name: <code>#OriginalFileList</code> or <code>OriginalFileListList</code> */
    public int countOriginalFileList();

    /** Criteria field name: <code>PixelsList</code> */
    public List getPixelsList();
    /** Criteria field name: <code>#PixelsList</code> or <code>PixelsListList</code> */
    public int countPixelsList();

    /** Criteria field name: <code>PixelsPlaneList</code> */
    public List getPixelsPlaneList();
    /** Criteria field name: <code>#PixelsPlaneList</code> or <code>PixelsPlaneListList</code> */
    public int countPixelsPlaneList();

    /** Criteria field name: <code>ThumbnailList</code> */
    public List getThumbnailList();
    /** Criteria field name: <code>#ThumbnailList</code> or <code>ThumbnailListList</code> */
    public int countThumbnailList();

}
