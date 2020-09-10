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


import x10.lang.Math.*;
import x10.regionarray.*;

public class PointSet {

       var p:Rail[DoublePoint];
       var n:Long;

       def this() { p = new Rail[DoublePoint](); n = 0; }
       def this(r:Rail[DoublePoint]) { p = new Rail[DoublePoint](r); n = r.size-1; }
       def this(len:Long) { p = new Rail[DoublePoint](len); n = 0; }
       def this(pset:PointSet) {
       	   p = new Rail[DoublePoint](pset.n);
	   n = pset.n;
       	   for(i in 0..(pset.n-1)) {
	   	 p(i) = pset.p(i);
	   }
       }

       public def pointSet() { return p; }

       public def length() { return n; }

       public def print() {

       	      for(i in 0..(this.n-1)) {
	      	    Console.OUT.println(this.p(i).getX()+" "+this.p(i).getY());	      
	      }

       }

       public def volume() {
       	      var sum:double = 0.0;
	      for (i in 0..(this.n-2)) {
	      	  sum += this.p(i).getX() * this.p(i+1).getY() - this.p(i+1).getX() * this.p(i).getY();
	      }
	      sum += this.p(this.n-1).getX() * this.p(0).getY() - this.p(0).getX() * this.p(this.n-1).getY();
	      return 0.5 * Math.abs(sum);
       }

       public def subset(fromIndex:long, length:long) {

       	      val r:Rail[DoublePoint] = new Rail[DoublePoint](length);
	      Rail.copy(this.p, fromIndex, r, 0, length); 

       	      return new PointSet( r );
       }

       public def merge(pset:PointSet):void {
              Rail.copy(pset.p, 0, this.p, this.n, pset.n);
	      this.n += pset.n;
       }

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
       
       public def isConvex() {
       	      var convex:Boolean = true;
	      var prev:long = 0;
	      var cur:long = 1;
	      var next:long = 2;

	      do {
	      	  if( turn(p(prev), p(cur), p(next)).isRight() ) {
		      convex = false;
	      	  }
		  prev = (prev + 1) % n;
 		  cur = (cur + 1) % n;
  		  next = (next + 1) % n;
		  
	      } while(convex && prev != 0);
	      
	      return convex;

       }
}
