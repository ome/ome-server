/*
 * org.openmicroscopy.ds.st.Experimenter
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
 * Created by dcreager via omejava on Wed Feb  4 17:49:53 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Experiment;
import org.openmicroscopy.ds.st.ExperimenterGroup;
import org.openmicroscopy.ds.st.Group;
import java.util.List;
import java.util.Map;

public interface Experimenter
    extends Attribute
{
    public String getFirstName();
    public void setFirstName(String value);

    public String getLastName();
    public void setLastName(String value);

    public String getEmail();
    public void setEmail(String value);

    public String getInstitution();
    public void setInstitution(String value);

    public String getDataDirectory();
    public void setDataDirectory(String value);

    public Group getGroup();
    public void setGroup(Group value);

    public List getExperiments();

    public List getExperimenterGroups();

    public List getGroupsByContact();

    public List getGroupsByLeader();

}
