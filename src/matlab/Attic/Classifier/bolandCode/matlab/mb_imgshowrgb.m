i=mb_tclread('/mnt/cdrom/06aug97.erdak/deconvolved/r06aug97.erdak.01--1---2.dat');
d=mb_tclread('/mnt/cdrom/06aug97.erdap/deconvolved/r06aug97.erdap.01--1---2.dat');
imshow(cat(3,mb_imgscale(i),mb_imgscale(d),zeros(size(i)))) ;

