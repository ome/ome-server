/*
 * org.openmicroscopy.util.SHA1
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

package org.openmicroscopy.util;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.io.File;
import java.io.IOException;
import java.io.FileInputStream;
import java.io.BufferedInputStream;

/**
 * Simple utility class to calculate SHA-1 digests.  This class is not
 * thread-safe.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @since OME2.2
 * @version 2.2
 */

public class SHA1
{
    private static final int BUFFER_SIZE = 4096;
    private static MessageDigest md;

    private static String[] BYTES =
    {"00","01","02","03","04","05","06","07",
     "08","09","0a","0b","0c","0d","0e","0f",
     "10","11","12","13","14","15","16","17",
     "18","19","1a","1b","1c","1d","1e","1f",
     "20","21","22","23","24","25","26","27",
     "28","29","2a","2b","2c","2d","2e","2f",
     "30","31","32","33","34","35","36","37",
     "38","39","3a","3b","3c","3d","3e","3f",
     "40","41","42","43","44","45","46","47",
     "48","49","4a","4b","4c","4d","4e","4f",
     "50","51","52","53","54","55","56","57",
     "58","59","5a","5b","5c","5d","5e","5f",
     "60","61","62","63","64","65","66","67",
     "68","69","6a","6b","6c","6d","6e","6f",
     "70","71","72","73","74","75","76","77",
     "78","79","7a","7b","7c","7d","7e","7f",
     "80","81","82","83","84","85","86","87",
     "88","89","8a","8b","8c","8d","8e","8f",
     "90","91","92","93","94","95","96","97",
     "98","99","9a","9b","9c","9d","9e","9f",
     "a0","a1","a2","a3","a4","a5","a6","a7",
     "a8","a9","aa","ab","ac","ad","ae","af",
     "b0","b1","b2","b3","b4","b5","b6","b7",
     "b8","b9","ba","bb","bc","bd","be","bf",
     "c0","c1","c2","c3","c4","c5","c6","c7",
     "c8","c9","ca","cb","cc","cd","ce","cf",
     "d0","d1","d2","d3","d4","d5","d6","d7",
     "d8","d9","da","db","dc","dd","de","df",
     "e0","e1","e2","e3","e4","e5","e6","e7",
     "e8","e9","ea","eb","ec","ed","ee","ef",
     "f0","f1","f2","f3","f4","f5","f6","f7",
     "f8","f9","fa","fb","fc","fd","fe","ff"};

    public static String byteToHex(byte b)
    {
        return BYTES[((int) b) & 0xff];
    }

    public static byte[] getSHA1(File file)
        throws IOException
    {
        try
        {
            // Create the SHA-1 digest handler if it hasn't already
            // been created

            if (md == null)
                md = MessageDigest.getInstance("SHA");
            md.reset();

            // Open the specified file for input, and buffer the
            // stream

            FileInputStream fis = new FileInputStream(file);
            BufferedInputStream bis = new BufferedInputStream(fis,BUFFER_SIZE);

            // Read in the entire file, passing the contents into the
            // digest handler

            byte[] buf = new byte[BUFFER_SIZE];
            int result;
            while ((result = bis.read(buf)) > 0)
                md.update(buf,0,result);

            return md.digest();
        } catch (NoSuchAlgorithmException e) {
            throw new UnsupportedOperationException("No SHA-1 provider - "+e);
        }
    }

    public static String getSHA1String(File file)
        throws IOException
    {
        byte[] digest = getSHA1(file);
        StringBuffer sb = new StringBuffer(digest.length * 2);
        for (int i = 0; i < digest.length; i++)
            sb.append(byteToHex(digest[i]));
        return sb.toString();
    }
}