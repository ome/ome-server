/*
 * org.openmicroscopy.ds.dto.UserStateDTO
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
 * Created by dcreager via omejava on Tue Feb 24 17:23:09 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterDTO;
import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class UserStateDTO
    extends MappedDTO
    implements UserState
{
    public UserStateDTO() { super(); }
    public UserStateDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "UserState"; }
    public Class getDTOType() { return UserState.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public Experimenter getExperimenter()
    { return (Experimenter) getObjectElement("experimenter"); }
    public void setExperimenter(Experimenter value)
    { setElement("experimenter",value); }

    public String getHost()
    { return getStringElement("host"); }
    public void setHost(String value)
    { setElement("host",value); }

    public Project getProject()
    { return (Project) getObjectElement("project"); }
    public void setProject(Project value)
    { setElement("project",value); }

    public Dataset getDataset()
    { return (Dataset) getObjectElement("dataset"); }
    public void setDataset(Dataset value)
    { setElement("dataset",value); }

    public ModuleExecution getModuleExecution()
    { return (ModuleExecution) getObjectElement("module_execution"); }
    public void setModuleExecution(ModuleExecution value)
    { setElement("module_execution",value); }

    public String getImageView()
    { return getStringElement("image_view"); }
    public void setImageView(String value)
    { setElement("image_view",value); }

    public String getFeatureView()
    { return getStringElement("feature_view"); }
    public void setFeatureView(String value)
    { setElement("feature_view",value); }

    public String getLastAccess()
    { return getStringElement("last_access"); }
    public void setLastAccess(String value)
    { setElement("last_access",value); }

    public String getStarted()
    { return getStringElement("started"); }
    public void setStarted(String value)
    { setElement("started",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("experimenter",ExperimenterDTO.class);
        parseChildElement("project",ProjectDTO.class);
        parseChildElement("dataset",DatasetDTO.class);
        parseChildElement("module_execution",ModuleExecutionDTO.class);
    }

}
