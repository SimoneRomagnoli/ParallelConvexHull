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


public class DoublePoint {

       var x:double;
       var y:double;

       def this(p:DoublePoint) { x = p.getX(); y = p.getY(); }
       def this(px:double, py:double) { x = px; y = py; }
       def this() { x = 0; y = 0; }

       public def getX() { return x; }

       public def getY() { return y; }

       public def getLowerX() { return Long.operator_as(x); }

       public def getLowerY() { return Long.operator_as(y); }

       public def getUpperX() { return Long.operator_as(x+1); }

       public def getUpperY() { return Long.operator_as(y+1); }

       public def setX(v:double) { this.x = v; }

       public def setY(v:double) { this.y = v; }

       public def equals(point:DoublePoint):boolean {
       	      if(this.x==point.getX() && this.y==point.getY()) {
	      	return true;
	      } else {
	      	return false;
	      }

       }
}
