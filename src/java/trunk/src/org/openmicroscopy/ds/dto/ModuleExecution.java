/*
 * org.openmicroscopy.ds.dto.ModuleExecution
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
 * Created by dcreager via omejava on Wed Feb  4 19:12:24 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import java.util.List;
import java.util.Map;

public interface ModuleExecution
{
    public int getID();
    public void setID(int value);

    public Module getModule();
    public void setModule(Module value);

    public boolean isVirtual();
    public void setVirtual(boolean value);

    public String getDependence();
    public void setDependence(String value);

    public Dataset getDataset();
    public void setDataset(Dataset value);

    public Image getImage();
    public void setImage(Image value);

    public String getIteratorTag();
    public void setIteratorTag(String value);

    public String getNewFeatureTag();
    public void setNewFeatureTag(String value);

    public String getInputTag();
    public void setInputTag(String value);

    public String getTimestamp();
    public void setTimestamp(String value);

    public float getTotalTime();
    public void setTotalTime(float value);

    public String getStatus();
    public void setStatus(String value);

    public String getErrorMessage();
    public void setErrorMessage(String value);

    public List getInputs();

}
