/*
 * org.openmicroscopy.ds.dto.AnalysisChain
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
 * Created by dcreager via omejava on Wed Feb 18 17:57:24 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterDTO;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface AnalysisChain
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>owner</code> */
    public Experimenter getOwner();
    public void setOwner(Experimenter value);

    /** Criteria field name: <code>name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>description</code> */
    public String getDescription();
    public void setDescription(String value);

    /** Criteria field name: <code>locked</code> */
    public Boolean isLocked();
    public void setLocked(Boolean value);

    /** Criteria field name: <code>nodes</code> */
    public List getNodes();
    /** Criteria field name: <code>#nodes</code> */
    public int countNodes();

    /** Criteria field name: <code>links</code> */
    public List getLinks();
    /** Criteria field name: <code>#links</code> */
    public int countLinks();

    /** Criteria field name: <code>paths</code> */
    public List getPaths();
    /** Criteria field name: <code>#paths</code> */
    public int countPaths();

}
