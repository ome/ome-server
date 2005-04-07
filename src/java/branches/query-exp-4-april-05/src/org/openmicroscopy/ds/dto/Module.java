/*
 * org.openmicroscopy.ds.dto.Module
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:49:34 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Module
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>description</code> */
    public String getDescription();
    public void setDescription(String value);

    /** Criteria field name: <code>module_type</code> */
    public String getModuleType();
    public void setModuleType(String value);

    /** Criteria field name: <code>location</code> */
    public String getLocation();
    public void setLocation(String value);

    /** Criteria field name: <code>category</code> */
    public ModuleCategory getCategory();
    public void setCategory(ModuleCategory value);

    /** Criteria field name: <code>default_iterator</code> */
    public String getDefaultIterator();
    public void setDefaultIterator(String value);

    /** Criteria field name: <code>new_feature_tag</code> */
    public String getNewFeatureTag();
    public void setNewFeatureTag(String value);

    /** Criteria field name: <code>inputs</code> */
    public List getFormalInputs();
    /** Criteria field name: <code>#inputs</code> or <code>inputsList</code> */
    public int countFormalInputs();

    /** Criteria field name: <code>outputs</code> */
    public List getFormalOutputs();
    /** Criteria field name: <code>#outputs</code> or <code>outputsList</code> */
    public int countFormalOutputs();

    /** Criteria field name: <code>executions</code> */
    public List getExecutions();
    /** Criteria field name: <code>#executions</code> or <code>executionsList</code> */
    public int countExecutions();

    /** Criteria field name: <code>execution_instructions</code> */
    public String getExecutionInstructions();
    public void setExecutionInstructions(String value);

}
