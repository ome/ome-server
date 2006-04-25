/*
 * Xmlgen
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2006 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee,
 *      University of Wisconsin-Madison
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
 *-----------------------------------------------------------------------------
 */


/*-----------------------------------------------------------------------------
 *
 * Written by:    Curtis Rueden <ctrueden@wisc.edu>
 *
 *-----------------------------------------------------------------------------
 */

import java.io.*;
import java.text.DateFormat;
import java.util.*;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.openmicroscopy.xml.DOMUtil;
import org.w3c.dom.*;

/**
 * This class provides logic for automatically generating the code in the
 * org.openmicroscopy.xml.st package, based on the org.openmicroscopy.ds.st
 * package and the OME SemanticType definitions.
 */
public class Xmlgen {

  // -- Constants --

  /** Debugging flag. */
  private static final boolean DEBUG = false;

  /** Directory prefix for ST_FILES and ST_INTERFACE_DIR paths. */
  private static final String DIR_PREFIX = System.getProperty("user.home");

  /** List of files containing SemanticType definitions. */
  private static final String[] ST_FILES = {
    "OME/src/xml/OME/RenderingSettings.ome",
    "OME/src/xml/OME/Analysis/FindSpots/spotModules.ome",
    "OME/src/xml/OME/Annotations/annotations.ome",
    "OME/src/xml/OME/Annotations/classification.ome",
    "OME/src/xml/OME/Core/Experiment.ome",
    "OME/src/xml/OME/Core/Experimenter.ome",
    "OME/src/xml/OME/Core/Group.ome",
    "OME/src/xml/OME/Core/Image.ome",
    "OME/src/xml/OME/Core/Instrument.ome",
    "OME/src/xml/OME/Core/Plate.ome",
    "OME/src/xml/OME/Core/Screen.ome",
    "OME/src/xml/OME/Core/OMEIS/OriginalFile.ome",
    "OME/src/xml/OME/Core/OMEIS/Repository.ome",
    "OME/src/xml/OME/Import/FilenamePattern.ome",
    "OME/src/xml/OME/Import/ImageServerStatistics.ome",
    "OME/src/xml/OME/Tests/datasetExample.ome",
    "OME/src/xml/OME/Tests/featureExample.ome",
  };

  /** Directory where org.openmicroscopy.ds.st interfaces reside. */
  private static final String ST_INTERFACE_DIR =
    "OME-JAVA/src/org/openmicroscopy/ds/st";

  /** Directory where output files should be placed. */
  private static final String OUTPUT_DIR = "st";

  /** Line break, for convenience. */
  private static final String LN = System.getProperty("line.separator");

  /** First part of header for each output Java source file. */
  private static final String HEADER1 =
    " *" + LN +
    " *---------------------------------------------------------------------" +
    "--------" + LN +
    " *" + LN +
    " *  Copyright (C) 2006 Open Microscopy Environment" + LN +
    " *      Massachusetts Institute of Technology," + LN +
    " *      National Institutes of Health," + LN +
    " *      University of Dundee," + LN +
    " *      University of Wisconsin-Madison" + LN +
    " *" + LN +
    " *" + LN +
    " *" + LN +
    " *    This library is free software; you can redistribute it and/or" +
    LN +
    " *    modify it under the terms of the GNU Lesser General Public" + LN +
    " *    License as published by the Free Software Foundation; either" + LN +
    " *    version 2.1 of the License, or (at your option) any later " +
    "version." + LN +
    " *" + LN +
    " *    This library is distributed in the hope that it will be useful," +
    LN +
    " *    but WITHOUT ANY WARRANTY; without even the implied warranty of" +
    LN +
    " *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU" +
    LN +
    " *    Lesser General Public License for more details." + LN +
    " *" + LN +
    " *    You should have received a copy of the GNU Lesser General " +
    "Public" + LN +
    " *    License along with this library; if not, write to the Free " +
    "Software" + LN +
    " *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  " +
    "02111-1307  USA" + LN +
    " *" + LN +
    " *---------------------------------------------------------------------" +
    "--------" + LN +
    " */" + LN +
    "" + LN +
    "" + LN +
    "/*---------------------------------------------------------------------" +
    "--------" + LN +
    " *" + LN +
    " * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.";

  /** Second part of header for each output Java source file. */
  private static final String HEADER2 =
    " *" + LN +
    " *---------------------------------------------------------------------" +
    "--------" + LN +
    " */" + LN +
    "" + LN +
    "package org.openmicroscopy.xml.st;" + LN;


  // -- Main method --

  /**
   * Run 'java Xmlgen' to generate the source code
   * for the org.openmicroscopy.xml.st package.
   */
  public static void main(String[] args) throws Exception {
    // glean ST interface list from *DTO.java files
    System.out.println("\nScanning ST interfaces...");
    File[] stList = new File(DIR_PREFIX, ST_INTERFACE_DIR).listFiles();
    Vector sts = new Vector();
    for (int i=0; i<stList.length; i++) {
      File f = stList[i];
      String name = f.getName();
      if (!name.endsWith("DTO.java")) continue;
      name = name.substring(0, name.length() - 8);
      sts.add(name);
    }
    System.out.println(sts.size() + " interfaces found.");

    // read in ST definitions from OME files
    System.out.println("\nScanning ST definitions...");
    Vector defs = new Vector();
    Vector defNames = new Vector();
    Vector defLocations = new Vector();
    for (int i=0; i<ST_FILES.length; i++) {
      DocumentBuilderFactory docFact = DocumentBuilderFactory.newInstance();
      DocumentBuilder db = docFact.newDocumentBuilder();
      Document doc = db.parse(new File(DIR_PREFIX, ST_FILES[i]));

      Vector els = DOMUtil.findElementList("SemanticType", doc);
      for (int j=0; j<els.size(); j++) {
        Element el = (Element) els.elementAt(j);
        String name = el.getAttribute("Name");
        int index = defNames.indexOf(name);
        if (index < 0) {
          defs.add(el);
          defNames.add(name);
          defLocations.add(ST_FILES[i]);
        }
        else {
          System.out.println(ST_FILES[i] + ": ignoring duplicate " +
            name + " ST definition (already defined in " +
            defLocations.elementAt(index) + ").");
        }
      }
    }
    System.out.println(defs.size() + " definitions found.");

    // compare interface list with definitions found
    for (int i=0; i<sts.size(); i++) {
      String name = (String) sts.elementAt(i);
      if (defNames.indexOf(name) < 0) {
        System.out.println("Warning: " +
          name + " not found in ST definitions!");
      }
    }
    int num = defs.size();
    for (int i=0; i<num; i++) {
      String name = (String) defNames.elementAt(i);
      if (sts.indexOf(name) < 0) {
        System.out.println("Warning: " +
          name + " is an extraneous ST definition!");
      }
    }

    // compile information about each ST
    Vector[] listSTs = new Vector[num];
    Vector[] listAttrs = new Vector[num];
    Vector[] listDups = new Vector[num];
    String[] description = new String[num];
    StringBuffer[] constArgs = new StringBuffer[num];
    StringBuffer[] constBody = new StringBuffer[num];
    for (int i=0; i<num; i++) {
      constArgs[i] = new StringBuffer();
      constBody[i] = new StringBuffer();
      Element def = (Element) defs.elementAt(i);
      String stName = (String) defNames.elementAt(i);
      constBody[i].append("    this(parent);");
      int constLeft = 46 - stName.length();
      NodeList children = def.getChildNodes();
      for (int j=0; j<children.getLength(); j++) {
        Node node = children.item(j);
        if (!(node instanceof Element)) continue;
        Element el = (Element) node;
        String tagName = el.getTagName();
        if (tagName.equals("Description")) {
          // extract ST description
          Text text = DOMUtil.getChildTextNode(el);
          if (text != null) {
            // remove excess whitespace from description
            StringTokenizer st = new StringTokenizer(text.getNodeValue());
            StringBuffer sb = new StringBuffer();
            int left = 63;
            if (st.hasMoreTokens()) {
              String token = st.nextToken();
              left -= token.length();
              sb.append(token);
            }
            while (st.hasMoreTokens()) {
              String token = st.nextToken();
              int len = token.length();
              left -= len;
              if (left <= 0) {
                sb.append(LN);
                sb.append(" *  ");
                left = 75 - len;
              }
              sb.append(" ");
              left--;
              sb.append(token);
            }
            description[i] = sb.toString();
          }
        }
        if (!tagName.equals("Element")) continue;

        String attrName = el.getAttribute("Name");
        String dataType = el.getAttribute("DataType");

        // uncapitalize first letter(s) of attribute name (Java convention)
        char[] attrNameArray = attrName.toCharArray();
        int ndx = 0;
        while (attrNameArray[ndx] >= 'A' && attrNameArray[ndx] <= 'Z') {
          attrNameArray[ndx] += 'a' - 'A';
          ndx++;
          if (ndx >= attrNameArray.length) break;
        }
        String varName = new String(attrNameArray);

        boolean isRef = false;
        if (dataType.equals("reference")) {
          dataType = el.getAttribute("RefersTo");
          isRef = true;
          int index = defNames.indexOf(dataType);
          if (index < 0) {
            System.out.println("Error: " + dataType +
              " is not a valid ST (referenced from " +
              attrName + " in " + stName + ")");
          }
          else {
            if (listSTs[index] == null) {
              listSTs[index] = new Vector();
              listAttrs[index] = new Vector();
              listDups[index] = new Vector();
            }
            ndx = listSTs[index].indexOf(stName);
            boolean dup = ndx >= 0;
            if (dup) listDups[index].setElementAt(Boolean.TRUE, ndx);
            listSTs[index].add(stName);
            listAttrs[index].add(attrName);
            listDups[index].add(dup ? Boolean.TRUE : Boolean.FALSE);
          }
        }
        else if (dataType.equals("bigint")) dataType = "long";

        // capitalize first letter of data type
        char[] dataTypeArray = dataType.toCharArray();
        if (dataTypeArray[0] >= 'a' && dataTypeArray[0] <= 'z') {
          dataTypeArray[0] += 'A' - 'a';
        }
        dataType = new String(dataTypeArray);

        if (constArgs[i].length() > 0) {
          constArgs[i].append(",");
          constLeft--;
        }
        int len = dataTypeArray.length + 1 + attrNameArray.length;
        constLeft -= len + 1;
        if (constLeft < 0) {
          constArgs[i].append(LN);
          constArgs[i].append("   ");
          constLeft = 73 - len;
        }
        constArgs[i].append(" ");
        constArgs[i].append(dataType);
        constArgs[i].append(" ");
        constArgs[i].append(varName);

        constBody[i].append(LN);
        constBody[i].append("    set");

        String methodName = attrName;
        if (dataType.equals("Boolean") && methodName.startsWith("Is")) {
          methodName = methodName.substring(2);
        }
        constBody[i].append(methodName);
        constBody[i].append("(");
        constBody[i].append(varName);
        constBody[i].append(");");
      }
      if (DEBUG) {
        System.out.println("description for " +
          defNames.elementAt(i) + ": " + description[i]);
        System.out.println("constArgs for " +
          defNames.elementAt(i) + ": " + constArgs[i].toString());
        System.out.print("list links for " +
          defNames.elementAt(i) + ":");
        if (listSTs[i] == null) System.out.print(" none");
        else for (int j=0; j<listSTs[i].size(); j++) {
          System.out.print(listSTs[i].elementAt(j) + " / " +
            listAttrs[i].elementAt(j) +
            " (dup=" + listDups[i].elementAt(j) + ")");
        }
        System.out.println();
      }
    }

    // write out each output file
    System.out.println();
    for (int i=0; i<num; i++) {
      Element def = (Element) defs.elementAt(i);
      String stName = (String) defNames.elementAt(i);
      String nodeName = stName + "Node";
      String className = "org.openmicroscopy.xml." + nodeName;
      String particle = "AEIOU".indexOf(stName.charAt(0)) < 0 ? "a" : "an";

      // open output file
      File outputDir = new File(OUTPUT_DIR);
      if (!outputDir.exists()) outputDir.mkdir();
      File outputFile = new File(OUTPUT_DIR, nodeName + ".java");
      System.out.println("Generating " + outputFile + "...");
      PrintWriter fout = new PrintWriter(new FileWriter(outputFile));

      fout.println("/*");
      fout.println(" * " + className);
      fout.println(HEADER1);
      DateFormat dateFormat = DateFormat.getDateInstance(DateFormat.MEDIUM);
      DateFormat timeFormat = DateFormat.getTimeInstance(DateFormat.LONG);
      Date date = Calendar.getInstance().getTime();
      fout.println(" * Created by " +
        System.getProperty("user.name") + " via Xmlgen on " +
        dateFormat.format(date) + " " + timeFormat.format(date));
      fout.println(HEADER2);
      if (listSTs[i] != null) {
        fout.println("import java.util.List;");
      }
      fout.println("import org.openmicroscopy.xml.AttributeNode;");
      fout.println("import org.openmicroscopy.xml.OMEXMLNode;");
      fout.println("import org.openmicroscopy.ds.st.*;");
      fout.println("import org.w3c.dom.Element;");
      fout.println();
      fout.println("/**");
      fout.println(" * " + nodeName + " is the node corresponding to the");
      fout.println(" * \"" + stName + "\" XML element.");
      fout.println(" *");
      fout.println(" * Name: " + stName);
      fout.println(" * AppliesTo: " + def.getAttribute("AppliesTo"));
      fout.println(" * Location: " + defLocations.elementAt(i));
      if (description[i] != null && !description[i].equals("")) {
        fout.println(" * Description: " + description[i]);
      }
      fout.println(" */");
      fout.println("public class " + nodeName + " extends AttributeNode");
      fout.println("  implements " + stName);
      fout.println("{");
      fout.println();

      // generate constructors
      fout.println("  // -- Constructors --");
      fout.println();
      fout.println("  /**");
      fout.println("   * Constructs " + particle + " " + stName + " node");
      fout.println("   * with the given associated DOM element.");
      fout.println("   */");
      fout.println("  public " + nodeName +
        "(Element element) { super(element); }");
      fout.println();
      fout.println("  /**");
      fout.println("   * Constructs " + particle + " " + stName + " node,");
      fout.println("   * creating its associated DOM element beneath the");
      fout.println("   * given parent.");
      fout.println("   */");
      fout.println("  public " + nodeName + "(OMEXMLNode parent) {");
      fout.println("    super(parent.getDOMElement().getOwnerDocument().");
      fout.println("      createElement(\"" + stName + "\"));");
      fout.println("    parent.getDOMElement().appendChild(element);");
      fout.println("  }");
      fout.println();
      fout.println("  /**");
      fout.println("   * Constructs " + particle + " " + stName + " node,");
      fout.println("   * creating its associated DOM element beneath the");
      fout.println("   * given parent, using the specified parameter values.");
      fout.println("   */");
      fout.println("  public " + nodeName + "(OMEXMLNode parent," +
        constArgs[i] + ")");
      fout.println("  {");
      fout.println(constBody[i]);
      fout.println("  }");
      fout.println();
      fout.println();

      // insert custom API methods
      File api = new File(nodeName + ".api");
      if (api.exists()) {
        BufferedReader in = new BufferedReader(new FileReader(api));
        while (true) {
          String line = in.readLine();
          if (line == null) break;
          fout.println(line);
        }
        in.close();
      }

      // generate API methods
      fout.println("  // -- " + stName + " API methods --");
      fout.println();

      NodeList children = def.getChildNodes();
      for (int j=0; j<children.getLength(); j++) {
        Node node = children.item(j);
        if (!(node instanceof Element)) continue;
        Element el = (Element) node;
        String tagName = el.getTagName();
        if (!tagName.equals("Element")) continue;

        String attrName = el.getAttribute("Name");
        String dataType = el.getAttribute("DataType");

        boolean isRef = false;
        if (dataType.equals("reference")) {
          dataType = el.getAttribute("RefersTo");
          isRef = true;
        }
        else if (dataType.equals("bigint")) dataType = "long";

        // capitalize first letter of data type
        char[] dataTypeArray = dataType.toCharArray();
        if (dataTypeArray[0] >= 'a' && dataTypeArray[0] <= 'z') {
          dataTypeArray[0] += 'A' - 'a';
        }
        dataType = new String(dataTypeArray);

        // generate "get" method
        fout.println("  /**");
        if (isRef) {
          fout.println("   * Gets " + attrName + " referenced by " + dataType);
          fout.println("   * attribute of the " + stName + " element.");
        }
        else {
          fout.println("   * Gets " + attrName + " attribute");
          fout.println("   * of the " + stName + " element.");
        }
        fout.println("   */");
        String get, name = attrName;
        if (dataType.equals("Boolean")) {
          get = "is";
          if (name.startsWith("Is")) name = name.substring(2);
        }
        else get = "get";
        fout.println("  public " + dataType + " " + get + name + "() {");
        if (isRef) {
          fout.println("    return (" + dataType + ")");
          fout.println("      createReferencedNode(" +
            dataType + "Node.class,");
          fout.println("      \"" + dataType + "\", \"" + attrName + "\");");
        }
        else {
          fout.print("    return get");
          if (!dataType.equals("String")) fout.print(dataType);
          fout.println("Attribute(\"" + attrName + "\");");
        }
        fout.println("  }");
        fout.println();

        // generate "set" method
        fout.println("  /**");
        if (isRef) {
          fout.println("   * Sets " + attrName + " referenced by " + dataType);
          fout.println("   * attribute of the " + stName + " element.");
          fout.println("   *");
          fout.println("   * @throws ClassCastException");
          fout.println("   *   if parameter is not an instance of " +
            dataType + "Node");
        }
        else {
          fout.println("   * Sets " + attrName + " attribute");
          fout.println("   * for the " + stName + " element.");
        }
        fout.println("   */");
        fout.println("  public void set" + name +
          "(" + dataType + " value) {");
        if (isRef) {
          fout.println("    setReferencedNode((OMEXMLNode) value, \"" +
            dataType + "\", \"" + attrName + "\");");
        }
        else {
          fout.print("    set");
          if (!dataType.equals("String")) fout.print(dataType);
          fout.println("Attribute(\"" + attrName + "\", value);");
        }
        fout.println("  }");
        fout.println();
      }

      // generate list methods
      if (listSTs[i] != null) {
        for (int j=0; j<listSTs[i].size(); j++) {
          String linkName = (String) listSTs[i].elementAt(j);
          String attrName = (String) listAttrs[i].elementAt(j);
          boolean dup = ((Boolean) listDups[i].elementAt(j)).booleanValue();
          fout.println("  /**");
          fout.println("   * Gets a list of " + linkName + " elements");
          fout.print("   * referencing this " + stName + " node");
          if (dup) {
            fout.println();
            fout.print("   * via a " + attrName + " attribute");
          }
          fout.println(".");
          fout.println("   */");
          fout.print("  public List get" + linkName + "List");
          if (dup) fout.print("By" + attrName);
          fout.println("() {");
          fout.println("    return createAttrReferralNodes(" + linkName +
            "Node.class,");
          fout.println("      \"" + linkName + "\", \"" + attrName + "\");");
          fout.println("  }");
          fout.println();
          fout.println("  /**");
          fout.println("   * Gets the number of " + linkName + " elements");
          fout.print("   * referencing this " + stName + " node");
          if (!attrName.equals(stName)) {
            fout.println();
            fout.print("   * via a " + attrName + " attribute");
          }
          fout.println(".");
          fout.println("   */");
          fout.print("  public int count" + linkName + "List");
          if (dup) fout.print("By" + attrName);
          fout.println("() {");
          fout.println("    return getSize(getAttrReferrals(\"" +
            linkName + "\",");
          fout.println("      \"" + attrName + "\"));");
          fout.println("  }");
          fout.println();
        }
      }

      fout.println("}");
      fout.close();
    }
  }

}
