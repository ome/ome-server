use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'OME',
    VERSION_FROM => 'OME.pm', # finds $VERSION
    AUTHOR       => 'Ilya Goldberg, Doug Creager, Brian Hughes, Josiah Johnston (igg@nih,gov, dcreager@alum.mit.edu, bshughes@mit.edu, siah@nih.gov)',
    ABSTRACT     => 'The Open Microscopy Environment',
    DIR          => ['OME/Image/Pix'],
    MAN1PODS     => {},
    MAN3PODS     => {},
#    realclean    => {FILES => 'OME/Image/blib'}  
);
