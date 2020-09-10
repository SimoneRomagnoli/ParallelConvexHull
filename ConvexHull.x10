/*

    This file is part of ParallelConvexHull.

    ParallelConvexHull is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ParallelConvexHull is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ParallelConvexHull.  If not, see <http://www.gnu.org/licenses/>.


*/
import x10.io.*;
import x10.regionarray.*;
import x10.array.DistArray_Block_1;
import x10.array.DistArray_Unique;
import x10.lang.Point;
import x10.lang.Math;

public class ConvexHull {

       //Read an input with the following structure:
       /*
       First line: dimension (always 2) 
       Second line: number of points (let's say n)
       Following n lines: X Y
       */
       public static def readInput(args:Rail[String]):PointSet {

       	      try {
       	      	  val f:File = args.size > 0 ? new File(args(0)) : new File("inputs/little.in");
	      	  val fr:FileReader = f.openRead();
		  val firstLine = fr.readLine().split(" ");
		  val rank:long = Long.parse(firstLine(0));
		  
		  if(rank!=2) throw new IOException();

		  val npoints:long = Long.parse(fr.readLine());

		  val pset:PointSet = new PointSet(npoints);

		  for(i:long in 0..(npoints-1)) {
		  	pset.p(i) = new DoublePoint();
			
		  	val ccs = fr.readLine().split(" ");
		  	pset.p(i).setX(Double.parse(ccs(0)));		  	
		  	pset.p(i).setY(Double.parse(ccs(1)));

			pset.n++;
		  }

		  return pset;

		  } catch (IOException) { x10.io.Console.OUT.println("Errore!"); }

	      return new PointSet();
       }

       //Determine if a triple of points turns left or right or if they are collinear
       public static def turn(p0:DoublePoint, p1:DoublePoint, p2:DoublePoint):Direction {

       	       val cross:double = (p1.x-p0.x)*(p2.y-p0.y) - (p2.x-p0.x)*(p1.y-p0.y);
	       if (cross > 0.0) {
	       	  return new Direction(Direction.LEFT);
	       } else {
	       	      if (cross < 0.0) {
		           return new Direction(Direction.RIGHT);
		      } else {
		           return new Direction(Direction.COLLINEAR);
		      }
	       }
       }

       //Easy string-printing function
       public static def print(s:String) {
       	      x10.io.Console.OUT.println(s);
       }

       //Determine the leftmost point in a set
       public static def leftmost(pset:PointSet):long {

       	       var leftmost:long = 0;
	       for(i in 1..(pset.n-1)) {
	       	     if(pset.p(i).x < pset.p(leftmost).x) {
		     	       leftmost = i;
		     }
	       }
	       return leftmost;

       }

       //Determine the rightmost point in a set
       public static def rightmost(pset:PointSet):long {

       	       var rightmost:long = 0;
	       for(i in 1..(pset.n-1)) {
	       	     if(pset.p(i).x > pset.p(rightmost).x) {
		     	       rightmost = i;
		     }
	       }
	       return rightmost;

       }
       
       //Determine the distance between two points
       public static def distanceBetween(p0:DoublePoint, p1:DoublePoint) {
       	      val yy:double = Math.abs( p1.getY() - p0.getY() );
       	      val xx:double = Math.abs( p1.getX() - p0.getX() );
	      return Math.sqrt( xx*xx + yy*yy );
       }

       //Parallel version of Gift Wrapping using distributed memory
       public static def distributedParallelConvexHull(pset:PointSet):PointSet {

       	      // Find the leftmost point
       	      val leftmost:long = leftmost(pset);
	      val leftmostPoint:DoublePoint = pset.p(leftmost);

	      // Find the size of each partition of the distributed array
	      val localSize = pset.n / Place.numPlaces();
	      val resto = pset.n % Place.numPlaces();
	      
	      // Create and initialize the distributed array with the Array.asyncCopy() function
	      val blk = Dist.makeBlock(Region.make(0, pset.n-1));
    	      val dist:DistArray[DoublePoint] = DistArray.make[DoublePoint](blk, ([i]:Point) => new DoublePoint(pset.p(i))  );
	      
	      // Array of points found by each place
	      val candidates = GlobalRef( new Array[DoublePoint](Place.numPlaces()) );

	      // Final pointset and current point variables
	      var hull:PointSet = new PointSet(pset.length());	      
	      var currentPoint:DoublePoint = pset.p(leftmost);

	      do {
	         // The first place adds the current point to the convex polygon
		 val lastPoint:DoublePoint = new DoublePoint(currentPoint);
		 hull.p(hull.n) = lastPoint;
		 hull.n++;

		 // Each place searches for the next point of the convex hull in his partition of points
		 finish for (p in Place.places()) {
	     	       at(p) async {
			   
			   val local = dist.getLocalPortion().raw();
			   var localNext:long = 0;
			   
			   for(j in 0..(local.size-1)) {
			   	 val d:Direction = turn(lastPoint, local(localNext), local(j));
		     		 if ( d.isCollinear() && distanceBetween(lastPoint, local(j)) > distanceBetween(lastPoint, local(localNext)) ) {
		     		    localNext = j;
		     		 }
		     		 if ( d.isLeft() ) {
                     		    localNext = j;
		     		 }	   	 
			   }

			   // Copy the candidate for the next point in the first place (GlobalRef variable candidates)
			   val nextPoint = localNext;
			   val index:long = here.id;

			   at (candidates.home) {
			      candidates.getLocalOrCopy().raw()(index) = local(nextPoint);
			      
			   }
		      }
	      	 }

		 // The first place analyzes the candidates and chooses the right one 
		 var next:long = 0;
		 val tmp = candidates.getLocalOrCopy().raw();

		 for (j in 0..(tmp.size-1)) {
                     val d:Direction = turn( currentPoint, tmp(next), tmp(j) );
		     if ( d.isCollinear() && distanceBetween(currentPoint, tmp(j)) > distanceBetween(currentPoint, tmp(next)) ) {
		      	next = j;
		     }
		     if ( d.isLeft() ) {
                       	next = j;
		     }
		 }

		 currentPoint = tmp(next);

	      } while( !leftmostPoint.equals(currentPoint) );

	      return new PointSet(hull);
       
       }

       //Parallel version of Gift Wrapping using distributed memory, but you can set more activities for each place       
       public static def distributedParallelConvexHull2(pset:PointSet, ppa:long):PointSet {

       	      // Find the leftmost point
       	      val leftmost:long = leftmost(pset);
	      val leftmostPoint:DoublePoint = pset.p(leftmost);

	      val start:long = System.currentTimeMillis();

	      // Create and initialize the distributed array with the Array.asyncCopy() function
	      val pointSet = new RemoteArray[DoublePoint](new Array[DoublePoint](pset.p));
	      val blk = Dist.makeBlock(Region.make(0, pset.n-1));
    	      val dist:DistArray[DoublePoint] = DistArray.make[DoublePoint](blk, ([i]:Point) => new DoublePoint(pset.p(i))  );
	 
	      val elapsed:long = System.currentTimeMillis() - start;
	      print("Distribution (ms):"+elapsed);

	      // Array of points found by each place
	      val candidates = GlobalRef( new Array[DoublePoint](Place.numPlaces()*ppa) );

	      // Final pointset and current point variables
	      var hull:PointSet = new PointSet(pset.length());	      
	      var currentPoint:DoublePoint = pset.p(leftmost);

	      do {
	         // The first place adds the current point to the convex polygon
		 val lastPoint:DoublePoint = new DoublePoint(currentPoint);
		 hull.p(hull.n) = lastPoint;
		 hull.n++;

		 // Each place searches for the next point of the convex hull in his partition of points
		 finish for (p in Place.places()) {
		    at (p) {
		       for(id in 0..(ppa-1)) {
	     	       	 async {
			   
			   val local = dist.getLocalPortion().raw();
			   var localNext:long = 0;

	      		   // Find the size of the partition each activity has to work on
			   val chunkSize = local.size / ppa;
              		   val localSize = id != ppa - 1 ? chunkSize : chunkSize + (local.size % ppa);

			   for(j in (chunkSize * id)..(chunkSize * id + localSize - 1)) {
			   	 val d:Direction = turn(lastPoint, local(localNext), local(j));
		     		 if ( d.isCollinear() && distanceBetween(lastPoint, local(j)) > distanceBetween(lastPoint, local(localNext)) ) {
		     		    localNext = j;
		     		 }
		     		 if ( d.isLeft() ) {
                     		    localNext = j;
		     		 }	   	 
			   }

			   // Copy the candidate for the next point in the first place (GlobalRef variable candidates)
			   val nextPoint = localNext;
			   val index:long = here.id;

			   at (candidates.home) {
			      candidates.getLocalOrCopy().raw()(index*ppa + id) = local(nextPoint);
			   }
		         }
		      }
		    }  
	      	 }

		 // The first place analyzes the candidates and chooses the right one 
		 var next:long = 0;
		 val tmp = candidates.getLocalOrCopy().raw();

		 for (j in 0..(tmp.size-1)) {
                     val d:Direction = turn( currentPoint, tmp(next), tmp(j) );
		     if ( d.isCollinear() && distanceBetween(currentPoint, tmp(j)) > distanceBetween(currentPoint, tmp(next)) ) {
		      	next = j;
		     }
		     if ( d.isLeft() ) {
                       	next = j;
		     }
		 }

		 currentPoint = tmp(next);

	      } while( !leftmostPoint.equals(currentPoint) );

	      return new PointSet(hull);
       
       }

       //Parallel version of Gift Wrapping using shared memory       
       public static def sharedParallelConvexHull(pset:PointSet, activities:long):PointSet {

       	      // Find the leftmost point
       	      val leftmost:long = leftmost(pset);
	      var hull:PointSet = new PointSet(pset.length());

	      // Find the size of the partition each activity has to work on
              val localSize = pset.n / activities;
              val resto = pset.n % activities;

	      // Current point
              var cur:long = leftmost;

	      // Array of points (indexes) found by each activity
              val candidates:Array[Long] = new Array[Long](activities, (i:Long) => 0);

              do {
	      	 //The root activity adds the current point to the convex polygon
	         hull.p(hull.n) = pset.p(cur);
		 hull.n++;

		 // Each activity searches for the next point of the convex hull in his partition of points (indexes)
		 // Activities are distinguished by the id variable
                 finish for(id in 0..(activities-1)) {
                        async {

			      val actualSize:long = id != activities-1 ? localSize : localSize + resto;
			      var localNext:long = localSize * id;

		 	      for(j in (localSize * id)..(localSize * id + actualSize - 1)) {
		     	      	        val d:Direction = turn(pset.p(cur), pset.p(localNext), pset.p(j));
		     		    	if ( d.isCollinear() && distanceBetween(pset.p(cur), pset.p(j)) > distanceBetween(pset.p(cur), pset.p(localNext)) ) {
					   localNext = j;
		     			}
		     			if ( d.isLeft() ) {
                         		   localNext = j;
		     			}
		 	       }

			       // Copy the candidate for the next point (index) in the candidate variable
			       // There's no need to manage concurrency as each activity writes on a personal cell of the candidates' array
			       candidates.raw()(id) = localNext;
			}
		 }

		 // The root activity analyzes the candidates and chooses the right one 
		 var next:long = 0;
		 val tmp = candidates.raw();

		 for(j in 0..(activities-1)) {
		      val d:Direction = turn(pset.p(cur), pset.p(tmp(next)), pset.p(tmp(j)));
   		      if ( d.isCollinear() && distanceBetween(pset.p(cur), pset.p(tmp(j))) > distanceBetween(pset.p(cur), pset.p(tmp(next))) ) {
		          next = j;
		      }
		      if ( d.isLeft() ) {
                          next = j;
		      }   	 
		 }

		 cur = tmp(next);	 
		 
	      } while(leftmost!=cur);

	      return new PointSet(hull);
       
       }

       //Shared version of Gift Wrapping              
       public static def serialConvexHull(pset:PointSet):PointSet {

       	      val leftmost:long = leftmost(pset);
	      var hull:PointSet = new PointSet(pset.length());

	      var cur:long = leftmost;
	      var next:long;

	      do {
		 hull.p(hull.n) = pset.p(cur);
		 hull.n++;

		 next = (cur + 1) % pset.n;
		 
		 for(j in 0..(pset.n-1)) {
		     val d:Direction = turn(pset.p(cur), pset.p(next), pset.p(j));
		     if ( d.isCollinear() && distanceBetween(pset.p(cur), pset.p(j)) > distanceBetween(pset.p(cur), pset.p(next)) ) {
		         next = j;
		     }
		     if ( d.isLeft() ) {
                         next = j;
		     }	   	 
		 } 
		 
		 cur = next;	 
		 
	      } while(leftmost!=cur);

	      return new PointSet(hull);
       
       }

       public static def main(args:Rail[String]) {

      	      val pset:PointSet = readInput(args);
	      val input:String = args(0).substring(Int.operator_as(7));

       	      if(args.size > 1 && args(1).contains("0")) {
	          x10.io.Console.OUT.println("Serial convex hull of input "+input+": ");

   	          val start:long = System.currentTimeMillis();
		  val serialConvexHull:PointSet = serialConvexHull(pset);
		  val elapsed:long = System.currentTimeMillis() - start;

		  x10.io.Console.OUT.println("Convex hull of "+serialConvexHull.length()+" points of "+pset.length());
	      	  x10.io.Console.OUT.println("Total volume: "+serialConvexHull.volume());
	     	  x10.io.Console.OUT.println("Elapsed time (ms): "+elapsed);
	      	  x10.io.Console.OUT.println("Elapsed time (s): "+elapsed/1000);
  	      	  x10.io.Console.OUT.println();
	      }
	      
       	      if(args(1).contains("1")) {
	          if(args.size > 2) {		   
			   x10.io.Console.OUT.println("Shared memory: parallel convex hull of input "+input+": ");
	      		   val activities:long = Long.parse(args(2));

	      		   val start:long = System.currentTimeMillis();
	      		   val parallelConvexHull:PointSet = sharedParallelConvexHull(pset, activities);
	      		   val elapsed:long = System.currentTimeMillis() - start;

			   x10.io.Console.OUT.println("Convex hull of "+parallelConvexHull.length()+" points of "+pset.length());
	      		   x10.io.Console.OUT.println("Total volume: "+parallelConvexHull.volume());
	      		   x10.io.Console.OUT.println("Elapsed time (ms): "+elapsed);
	      		   x10.io.Console.OUT.println("Elapsed time (s): "+elapsed/1000);
			   //parallelConvexHull.print();
	          } else {
		           x10.io.Console.OUT.println("Missing arguments");
		  }
	      }

	      if(args.size > 1 && args(1).contains("2")) {		   
			   x10.io.Console.OUT.println("Distributed memory: parallel convex hull of input "+input+": ");
	      		   
	      		   val start:long = System.currentTimeMillis();
	      		   val parallelConvexHull:PointSet = distributedParallelConvexHull(pset);
			   val elapsed:long = System.currentTimeMillis() - start;

			   x10.io.Console.OUT.println("Convex hull of "+parallelConvexHull.length()+" points of "+pset.length());
	      		   x10.io.Console.OUT.println("Total volume: "+parallelConvexHull.volume());
	      		   x10.io.Console.OUT.println("Elapsed time (ms): "+elapsed);
	      		   x10.io.Console.OUT.println("Elapsed time (s): "+elapsed/1000);
	      }

	      if(args(1).contains("3")) {
	          if(args.size > 2) {		   
			   x10.io.Console.OUT.println("Distributed memory: parallel convex hull of input "+input+": ");

			   // ppa = Per Place Activities
			   val ppa:long = Long.parse(args(2));

	      		   val start:long = System.currentTimeMillis();
	      		   val parallelConvexHull:PointSet = distributedParallelConvexHull2(pset, ppa);
	      		   val elapsed:long = System.currentTimeMillis() - start;

			   x10.io.Console.OUT.println("Convex hull of "+parallelConvexHull.length()+" points of "+pset.length());
	      		   x10.io.Console.OUT.println("Total volume: "+parallelConvexHull.volume());
	      		   x10.io.Console.OUT.println("Elapsed time (ms): "+elapsed);
	      		   x10.io.Console.OUT.println("Elapsed time (s): "+elapsed/1000);
			   //parallelConvexHull.print();
	          } else {
		           x10.io.Console.OUT.println("Missing arguments");
		  }
	      }
	      

       }

}
