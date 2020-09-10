This program is under GNU GPL v3 license.
Please check the COPYING file.

If you want to use this program you need to download the x10 environment at:
http://x10-lang.org/releases/x10-release-262.html .

Once you have the environment ready use the bin/x10c and bin/x10c++ files to compile .x10 sources.
First, compile DoublePoint, Direction, PointSet classes and then the main program ConvexHUll.
DoublePoint: a class representing a point in the plane with double coordinates.
Direction: class that determines if a triplet of points turns left or right or if they are collinear.
PointSet: a class that contains an array of DoublePoints and some methods.
To execute the program you need to have an input file such as circ5k.in or circ50k.in: their structure is explained in the ConvexHull.x10 file.

I recommend to use the -O -NO_CHECKS options for the compilation; to compile use the x10c and x10c++ files in the bin directory:
Java backend:
bin/x10c -O -NO_CHECKS src/ConvexHull.x10

C++ backend:
bin/x10c++ -O -NO_CHECKS -o ConvexHull src/ConvexHull.x10


To execute:
Java backend:
X10_NPLACES=1 X10_NTHREADS=12 bin/x10 ConvexHull circ5k.in 012

C++ backend:
X10_NPLACES=1 X10_NTHREADS=12 ./ConvexHull circ5k.in 012

I recommend to use all the available cores; if you have 12 cores and you want to execute with 1 place, set the number of worker threads per place at 12;
if you want to use 2 places, set it to 6, with 3 places set it to 4, and so on.

The "012" sequence determines the implementation to call:
Serial implementation: 0 ;
Shared memory implementation: 1 ;
Distributed memory implementation: 2 .
If you write "01" the program will call the serial implementation and then the shared memory one; if you write "012" the program will call all the implementations.
The shared memory implementation has to be run with X10_NPLACES=1 and needs to know the number of activities to spawn;
you have to write the number of activities as the last number: for example, with 4 activities "X10_NPLACES=1 X10_NTHREADS=12 bin/x10 ConvexHull circ5k.in 1 4"

