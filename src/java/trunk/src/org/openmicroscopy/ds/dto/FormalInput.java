/*
 * org.openmicroscopy.ds.dto.FormalInput
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

public interface FormalInput
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>module</code> */
    public Module getModule();
    public void setModule(Module value);

    /** Criteria field name: <code>name</code> */
    public String getName();
    public void setName(String value);

    /** Criteria field name: <code>description</code> */
    public String getDescription();
    public void setDescription(String value);

    /** Criteria field name: <code>optional</code> */
    public boolean isOptional();
    public void setOptional(boolean value);

    /** Criteria field name: <code>list</code> */
    public boolean isList();
    public void setList(boolean value);

    /** Criteria field name: <code>semantic_type</code> */
    public SemanticType getSemanticType();
    public void setSemanticType(SemanticType value);

    /** Criteria field name: <code>lookup_table</code> */
    public LookupTable getLookupTable();
    public void setLookupTable(LookupTable value);

    /** Criteria field name: <code>user_defined</code> */
    public boolean isUserDefined();
    public void setUserDefined(boolean value);

    /** Criteria field name: <code>actual_inputs</code> */
    public List getActualInputs();
    /** Criteria field name: <code>#actual_inputs</code> */
    public int countActualInputs();

}
