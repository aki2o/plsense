#!/usr/bin/perl

use File::Copy;

# astart project module prior to installed module
#&File::Copy::
# aend equal: File::Copy::dummy_copy

# mstart project module prior method
#File::Copy::dummy_copy
# mend ^ NAME: \s dummy_copy $
# mend ^ RETURN: \s Literal \s As \s SCALAR $
# mend ^ FILE: \s .+ /File\.Copy\.pm $
# mend ^ LINE: \s 6 $
# mend ^ COL: \s 1 $

# mstart explicit project module prior method
#&File::Copy::dummy_copy
# mend ^ NAME: \s dummy_copy $
# mend ^ RETURN: \s Literal \s As \s SCALAR $
# mend ^ FILE: \s .+ /File\.Copy\.pm $
# mend ^ LINE: \s 6 $
# mend ^ COL: \s 1 $

