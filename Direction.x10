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


public class Direction {

       static val LEFT:long = -1;
       static val COLLINEAR:long = 0;
       static val RIGHT:long = 1;

       val dir:long;
       val next:DoublePoint;

       def this(d:long) { this.dir = d; this.next = new DoublePoint(); }
       def this(d:Direction) { this.dir = d.dir; this.next = d.next; }

       public def isRight() {
       	      return this.dir == RIGHT;
       }

       public def isLeft() {
       	      return this.dir == LEFT;
       }

       public def isCollinear() {
       	      return this.dir == COLLINEAR;
       }
}
