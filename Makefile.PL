use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sub::ParamFrame',
    VERSION_FROM      => 'lib/Sub/ParamFrame.pm', # finds $VERSION
    PREREQ_PM         => {'Sub::ParamLoader'=>0.01},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sub/ParamFrame.pm', # retrieve abstract from module
       AUTHOR         => 'Josef Schoenbrunner <j.schoenbrunner@schule.at>') : (),
       ABSTRACT       => 'Supply key alias and defaults of named arguments.',
    )
  );
