/*
 * org.openmicroscopy.ds.dto.UserState
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
 * Created by hochheiserha via omejava on Mon May  2 15:18:38 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterDTO;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface UserState
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>experimenter</code> */
    public Experimenter getExperimenter();
    public void setExperimenter(Experimenter value);

    /** Criteria field name: <code>host</code> */
    public String getHost();
    public void setHost(String value);

    /** Criteria field name: <code>project</code> */
    public Project getProject();
    public void setProject(Project value);

    /** Criteria field name: <code>dataset</code> */
    public Dataset getDataset();
    public void setDataset(Dataset value);

    /** Criteria field name: <code>module_execution</code> */
    public ModuleExecution getModuleExecution();
    public void setModuleExecution(ModuleExecution value);

    /** Criteria field name: <code>image_view</code> */
    public String getImageView();
    public void setImageView(String value);

    /** Criteria field name: <code>feature_view</code> */
    public String getFeatureView();
    public void setFeatureView(String value);

    /** Criteria field name: <code>last_access</code> */
    public String getLastAccess();
    public void setLastAccess(String value);

    /** Criteria field name: <code>started</code> */
    public String getStarted();
    public void setStarted(String value);

}
