use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "\n\nWhere is Matlab installed?\n";
print ">> ";

my $matlab_path = <STDIN>;
chomp($matlab_path);

$matlab_path = $matlab_path || "/Applications/matlab";

my $matlab_include = "$matlab_path/extern/include";
my $matlab_lib = "$matlab_path/extern/lib/mac";

print STDERR "Using Matlab located in $matlab_path\n";
print STDERR "  Include: $matlab_include\n";
print STDERR "  Lib:     $matlab_lib\n\n";

WriteMakefile(
    'NAME'		=> 'OME::Matlab',
    'VERSION_FROM'	=> '../../OME.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> ["-L/usr/local/lib -L/sw/lib -L$matlab_lib -lmx -leng"], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> "-I$matlab_include", # e.g., '-I/usr/include/other'
    'realclean'         => {FILES => '../blib'},
    'clean'             => {FILES => '../blib'},
);
