/*
 * org.openmicroscopy.Factory
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy;

import java.util.Map;
import java.util.List;
import java.util.Iterator;

/**
 * <p>Provides a single interface through which the rest of OME
 * interacts with the database.</p>
 *
 * <p><b>Objects vs. attributes</b></p>
 *
 * <p>Several of the <code>Factory</code> methods make a distinction
 * between "objects" and "attributes".  In this convention, an
 * "object" is defined by an {@link OMEObject} subinterface included
 * in the OME source tree.  All of the core OME database tables
 * (PROJECTS, DATASETS, IMAGES, etc.) are "objects", and have
 * predefined {@link OMEObject} subinterfaces ({@link Project}, {@link
 * Dataset}, {@link Image}, etc.).  Methods such as {@link #newObject
 * newObject} and {@link #loadObject loadObject} operate on these core
 * tables, and identify the specific {@link OMEObject} subinterface by
 * the name of its corresponding Perl class.</p>
 *
 * <p>Attribute tables, however, cannot have predefined {@link
 * OMEObject} subinterfaces, since the semantic types available in OME
 * can vary from time to time.  However, OME stores enough information
 * about each semantic type to construct the appropriate Perl
 * subclasses at runtime.  (The real situation is slightly more
 * complex than this because of the distinction between data tables
 * and semantic types.  See the {@link DataTable} and {@link
 * SemanticType} interfaces for more details.)  Methods such as {@link
 * #newAttribute newAttribute} and {@link #loadAttribute
 * loadAttribute} operate on these user-defined semantic types, and
 * identify the semantic type by name.  In Java, instances of
 * semantically typed attributes are always instances of the {@link
 * Attribute} interface.  Since there is no dynamic compilation in
 * Java, the values of an attribute's semantic elements must be
 * retrieved by name, rather than by accessors specific to the
 * element.</p>
 *
 * <p><b>Obtaining a <code>Factory</code></b></p>
 *
 * <p>To retrieve an instance of <code>Factory</code>, the user must
 * first log into OME.  The act of logging in (most often via the
 * {@link org.openmicroscopy.remote.RemoteBindings} class of the
 * Remote Framework) will return an instance of the {@link Session}
 * interface.  The {@link Session#getFactory} method will then return
 * the factory used to create and retrieve data objects for that
 * session.</p>
 *
 * <p><b>Search criteria</b></p>
 *
 * <p>The {@link #objectExists objectExists}, {@link #findObject
 * findObject}, {@link #findObjects findObjects}, {@link
 * #findObjectLike findObjectLike}, and {@link #findObjectsLike
 * findObjectsLike} methods all take in search criteria as their last
 * parameters.  These criteria are used to build the WHERE clause of
 * the SQL statement used to retrieve the objects in question.  You
 * can think of these criteria as similar to the data hash used to
 * create objects: The keys should be column names (with the "_id"
 * suffix for foreign keys), the values should be the search criteria
 * values (ID's, not objects, for foreign keys).  When calling the
 * methods, these criteria should be passed in as an instance of
 * {@link Map}.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public interface Factory
{
    /**
     * Creates a new object with initial values specified by
     * <code>data</code>.  The keys of <code>data</code> should be the
     * names of the columns in the corresponding dataset table.
     * Foreign key fields should be referred to its "_id" suffix, and
     * values for these fields should be specified by their primary
     * key ID.  The <code>data</code> map should not contain a value
     * for the primary key if the underlying table has a corresponding
     * sequence.  This method creates a new row in the database, so
     * any columns defined to be <code>NOT NULL</code> must be
     * specified in <code>data</code>, or the database driver will
     * throw an error.
     * @param className the name of the Perl class representing the
     * object to create
     * @param data the initial values for the new instance
     * @return an instance of the appropriate Java class
     */
    public OMEObject newObject(String className, Map data);

    /**
     * Works exactly like {@link #newObject newObject}, except that if
     * an object in the database already exists with the given
     * contents, it will be returned, and no new object will be
     * created.  This is extremely useful for adding items to a
     * many-to-many map.
     * @param className the name of the Perl class representing the
     * object to create
     * @param data the initial values for the new instance
     * @return an instance of the appropriate Java class
     */
    public OMEObject maybeNewObject(String className, Map data);

    /**
     * Returns an {@link OMEObject} instance corresponding to the row
     * in <code>className</code>'s table with <code>id</code> for its
     * primary key.  Returns <code>null</code> if there is no row with
     * that primary key.
     * @param className the name of the Perl class repesenting the
     * object to load
     * @param id a primary key ID
     * @return the {@link OMEObject} of the given class with the given
     * primary key ID
     */
    public OMEObject loadObject(String className, int id);

    /**
     * Returns whether there is an object in the database matching the
     * given criteria.  Please see the <i>Search criteria</i> section
     * of the class documentation for details on forming the
     * <code>criteria</code> map.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return whether an object exists that matches the given
     * criteria
     */
    public boolean objectExists(String className, Map criteria);

    /**
     * Returns an {@link OMEObject} matching the given criteria, if
     * there is one.  If there isn't, returns <code>null</code>.  If
     * there is more than one row that matches, it is undefined which
     * is returned.  Please see the <i>Search criteria</i> section of
     * the class documentation for details on forming the
     * <code>criteria</code> map.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return an object that matches the given criteria
     */
    public OMEObject findObject(String className, Map criteria);

    /**
     * Returns a {@link List} of {@link OMEObject OMEObjects} matching
     * the given criteria, if there are any.  If there isn't, returns
     * an empty {@link List}.  Please see the <i>Search criteria</i>
     * section of the class documentation for details on forming the
     * <code>criteria</code> map.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return a {@link List} of objects that match the given criteria
     */
    public List findObjects(String className, Map criteria);

    /**
     * Returns an {@link Iterator} of {@link OMEObject OMEObjects}
     * matching the given criteria, if there are any.  If there isn't,
     * returns an empty {@link Iterator}.  Please see the <i>Search
     * criteria</i> section of the class documentation for details on
     * forming the <code>criteria</code> map.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return an {@link Iterator} of objects that match the given
     * criteria
     */
    public Iterator iterateObjects(String className, Map criteria);

    /**
     * Works exactly like the {@link #findObject findObject} method,
     * but uses the SQL <code>LIKE</code> operator for comparison,
     * rather than the <code>=</code> operator.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return an object that matches the given criteria
     */
    public OMEObject findObjectLike(String className, Map criteria);

    /**
     * Works exactly like the {@link #findObjects findObjects} method,
     * but uses the SQL <code>LIKE</code> operator for comparison,
     * rather than the <code>=</code> operator.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return a {@link List} of objects that match the given criteria
     */
    public List findObjectsLike(String className, Map criteria);

    /**
     * Works exactly like the {@link #iterateObjects iterateObjects}
     * method, but uses the SQL <code>LIKE</code> operator for
     * comparison, rather than the <code>=</code> operator.
     * @param className the name of the Perl class to search through
     * @param criteria the search criteria
     * @return an {@link Iterator} of objects that match the given
     * criteria
     */
    public Iterator iterateObjectsLike(String className, Map criteria);

    /**
     * <p>Creates a new {@link Attribute} instance.  The
     * <code>data</code> map contains values for the new attribute,
     * using basically the same format as the <code>data</code> map in
     * the {@link #newObject newObject} method.  However, in this
     * case, the keys of the map are semantic element names instead of
     * database column names.  Further, the target of the new
     * attribute and the module execution that created it should be
     * specified in the <code>target</code> and
     * <code>moduleExecution</code> parameters, and not in the
     * <code>data</code> map.</p>
     *
     * <p>Since the underlying Perl code for a semantic type is
     * created dynamically, semantic types are not referred to by
     * class name, like objects are.  Rather, the
     * <code>typeName</code> parameter should be the name of the
     * semantic type desired.</p>
     *
     * @param typeName the name of a semantic type
     * @param target the target of the new attribute
     * @param moduleExecution the module execution that created the
     * attribute
     * @param data the values for the new attribute
     * @return an instance of {@link Attribute} representing the new
     * attribute
     */
    public Attribute newAttribute(String typeName,
                                  OMEObject target,
                                  ModuleExecution moduleExecution,
                                  Map data);

    /**
     * Loads in the attribute of the given semantic type with the
     * given primary key ID.
     * @param typeName the name of a semantic type
     * @param id a primary key ID
     * @return the attribute of the given semantic type with the given
     * primary key ID
     */
    public Attribute loadAttribute(String typeName, int id);

    /**
     * Finds the attributes of a given type referring to a given target.
     * The <code>typeName</code> parameter should be a semantic type
     * name.  The <code>target</code> must be an instance of {@link
     * Dataset}, {@link Image}, or {@link Feature}, depending on the
     * granularity of the type.  Note that arbitrary search criteria
     * is not yet supported in this method.  We are currently deciding
     * how best to add this functionality.
     * @param typeName the name of a semantic type
     * @param target the target of the attributes to find
     * @return a {@link List} of {@link Attribute Attributes}
     */
    public List findAttributes(String typeName, OMEObject target);
}
