/*
 * org.openmicroscopy.is.UploadFilesTest
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

package org.openmicroscopy.is;

import java.io.File;
import java.util.List;
import java.util.Map;
import java.util.Iterator;
import java.util.Arrays;
import org.openmicroscopy.helpers.ImageServerHelper;
import org.openmicroscopy.util.ProgressTracker;
import org.openmicroscopy.util.ConsoleTracker;

import java.awt.*;
import javax.swing.*;
import org.openmicroscopy.util.ProgressBarTracker;

public class UploadFilesTest
{
    public static void main(String[] args)
    {
        if (args.length <= 0)
        {
            System.err.println("Usage: UploadFilesTest [filenames/directories]");
            System.err.println("   or: UploadFilesTest GUI");
            System.exit(-1);
        }

        if (args[0].equalsIgnoreCase("GUI"))
            graphical();
        else
            text(args);
    }

    public static void text(String[] args)
    {
        try
        {
            System.err.println("Finding files...");
            List input = Arrays.asList(args);
            List files = ImageServerHelper.normalizeFiles(input);

            System.err.println("Connecting to image server...");
            ImageServer is = ImageServer.getDefaultImageServer();

            System.err.println("Uploading files...");
            ProgressTracker tracker = new ConsoleTracker(System.err);
            Map result = ImageServerHelper.uploadFiles(is,files,tracker);

            System.err.println();

            Iterator iter = result.entrySet().iterator();
            while (iter.hasNext())
            {
                Map.Entry entry = (Map.Entry) iter.next();
                File file = (File) entry.getKey();
                Long fileID = (Long) entry.getValue();

                System.out.println(fileID+": "+file);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void graphical()
    {
        JFileChooser chooser = new JFileChooser();
        chooser.setApproveButtonText("Upload");
        chooser.setDialogTitle("Upload files to OME image server");
        chooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        chooser.setMultiSelectionEnabled(true);

        int okay = chooser.showOpenDialog(null);
        if (okay == JFileChooser.APPROVE_OPTION)
        {
            JFrame frame = new JFrame("Image server");
            JLabel label = new JLabel("Uploading...",
                                      SwingConstants.CENTER);
            Dimension size = label.getPreferredSize();
            label.setPreferredSize(new Dimension(450,(int) size.getHeight()));
            JProgressBar bar = new JProgressBar();
            bar.setStringPainted(true);

            JComponent cp = (JComponent) frame.getContentPane();
            cp.setLayout(new GridLayout(0,1,0,4));
            cp.setBorder(BorderFactory.createEmptyBorder(6,6,6,6));
            cp.add(label);
            cp.add(bar);

            ProgressTracker tracker = new ProgressBarTracker(bar);

            frame.pack();
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);

            File[] args = chooser.getSelectedFiles();
            List input = Arrays.asList(args);

            try
            {
                List files = ImageServerHelper.normalizeFiles(input);
                ImageServer is = ImageServer.getDefaultImageServer();
                Map result = ImageServerHelper.uploadFiles(is,files,tracker);

                Iterator iter = result.entrySet().iterator();
                while (iter.hasNext())
                {
                    Map.Entry entry = (Map.Entry) iter.next();
                    File file = (File) entry.getKey();
                    Long fileID = (Long) entry.getValue();

                    System.out.println(fileID+": "+file);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }

            frame.setVisible(false);
            frame.dispose();
        }

        System.exit(0);
    }
}
