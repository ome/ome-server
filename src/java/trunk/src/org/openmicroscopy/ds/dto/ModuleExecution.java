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
 * Created by dcreager via omejava on Wed Feb 11 16:06:46 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import java.util.List;
import java.util.Map;

public interface ModuleExecution
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>module</code> */
    public Module getModule();
    public void setModule(Module value);

    /** Criteria field name: <code>virtual_mex</code> */
    public boolean isVirtual();
    public void setVirtual(boolean value);

    /** Criteria field name: <code>dependence</code> */
    public String getDependence();
    public void setDependence(String value);

    /** Criteria field name: <code>dataset</code> */
    public Dataset getDataset();
    public void setDataset(Dataset value);

    /** Criteria field name: <code>image</code> */
    public Image getImage();
    public void setImage(Image value);

    /** Criteria field name: <code>iterator_tag</code> */
    public String getIteratorTag();
    public void setIteratorTag(String value);

    /** Criteria field name: <code>new_feature_tag</code> */
    public String getNewFeatureTag();
    public void setNewFeatureTag(String value);

    /** Criteria field name: <code>input_tag</code> */
    public String getInputTag();
    public void setInputTag(String value);

    /** Criteria field name: <code>timestamp</code> */
    public String getTimestamp();
    public void setTimestamp(String value);

    /** Criteria field name: <code>total_time</code> */
    public float getTotalTime();
    public void setTotalTime(float value);

    /** Criteria field name: <code>status</code> */
    public String getStatus();
    public void setStatus(String value);

    /** Criteria field name: <code>error_message</code> */
    public String getErrorMessage();
    public void setErrorMessage(String value);

    /** Criteria field name: <code>inputs</code> */
    public List getInputs();
    /** Criteria field name: <code>#inputs</code> */
    public int countInputs();

}
