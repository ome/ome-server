use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
warn "WARNING:  libtiff must be installed !\n";
WriteMakefile(
    'NAME'		=> 'OME::Image::Pix',
    'VERSION_FROM'	=> '../../../OME.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> ['-L/usr/local/lib -L/sw/lib -ltiff'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I/sw/include', # e.g., '-I/usr/include/other'
	'OBJECT'    => 'Pix.o libpix.o',
	'realclean'    =>   {FILES => '../blib'},
	'clean'    =>   {FILES => '../blib'},
);
