package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * Planar polygon representation with computational geometry algorithms.
     * Computes signed shoelace area, centroid, winding orientation, point containment,
     * and convex hull via Andrew's monotone chain algorithm.
     */
    public class Polygon2D implements ICloneable, ISerializable
    {
        public var vertices:Array; // Array of Point2D

        public function Polygon2D(vertices:Array = null)
        {
            this.vertices = (vertices != null) ? vertices : [];
        }

        public function get vertexCount():int
        {
            return vertices.length;
        }

        public function addVertex(p:Point2D):Polygon2D
        {
            vertices.push(p);
            return this;
        }

        public function getVertex(index:int):Point2D
        {
            if (index >= 0 && index < vertices.length)
            {
                return vertices[index] as Point2D;
            }
            return null;
        }

        /**
         * Computes signed area using the Shoelace formula (Gauss's area formula).
         * Positive for counter-clockwise orientation; negative for clockwise.
         */
        public function signedArea():Number
        {
            var n:int = vertices.length;
            if (n < 3) return 0.0;

            var sum:Number = 0.0;
            for (var i:int = 0; i < n; i++)
            {
                var j:int = (i + 1) % n;
                var p1:Point2D = vertices[i] as Point2D;
                var p2:Point2D = vertices[j] as Point2D;
                sum += (p1.x * p2.y - p2.x * p1.y);
            }

            return sum * 0.5;
        }

        public function area():Number
        {
            return Math.abs(signedArea());
        }

        public function isClockwise():Boolean
        {
            return signedArea() < 0.0;
        }

        /**
         * Computes geometric centroid (center of mass) of the planar polygon.
         */
        public function centroid():Point2D
        {
            var n:int = vertices.length;
            if (n == 0) return new Point2D(0.0, 0.0);
            if (n == 1) return (vertices[0] as Point2D).clone() as Point2D;
            if (n == 2) return (vertices[0] as Point2D).midpoint(vertices[1] as Point2D);

            var sArea:Number = signedArea();
            if (MathUtil.fuzzyZero(sArea))
            {
                var cxSimple:Number = 0.0;
                var cySimple:Number = 0.0;
                for (var k:int = 0; k < n; k++)
                {
                    cxSimple += vertices[k].x;
                    cySimple += vertices[k].y;
                }
                return new Point2D(cxSimple / n, cySimple / n);
            }

            var factor:Number = 1.0 / (6.0 * sArea);
            var cx:Number = 0.0;
            var cy:Number = 0.0;

            for (var i:int = 0; i < n; i++)
            {
                var j:int = (i + 1) % n;
                var pi:Point2D = vertices[i] as Point2D;
                var pj:Point2D = vertices[j] as Point2D;
                var crossTerm:Number = (pi.x * pj.y - pj.x * pi.y);
                cx += (pi.x + pj.x) * crossTerm;
                cy += (pi.y + pj.y) * crossTerm;
            }

            return new Point2D(cx * factor, cy * factor);
        }

        /**
         * Total boundary perimeter.
         */
        public function perimeter():Number
        {
            var n:int = vertices.length;
            if (n < 2) return 0.0;

            var total:Number = 0.0;
            for (var i:int = 0; i < n; i++)
            {
                var j:int = (i + 1) % n;
                total += (vertices[i] as Point2D).distanceTo(vertices[j] as Point2D);
            }
            return total;
        }

        /**
         * Checks whether point p lies inside polygon using ray-casting crossing algorithm.
         */
        public function containsPoint(p:Point2D):Boolean
        {
            var n:int = vertices.length;
            if (n < 3) return false;

            var inside:Boolean = false;
            for (var i:int = 0, j:int = n - 1; i < n; j = i++)
            {
                var pi:Point2D = vertices[i] as Point2D;
                var pj:Point2D = vertices[j] as Point2D;

                var intersect:Boolean = ((pi.y > p.y) != (pj.y > p.y)) &&
                    (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x);

                if (intersect)
                {
                    inside = !inside;
                }
            }
            return inside;
        }

        /**
         * Axis-aligned bounding box of polygon.
         */
        public function bounds():Rect2D
        {
            if (vertices.length == 0) return new Rect2D(0.0, 0.0, 0.0, 0.0);

            var minX:Number = vertices[0].x;
            var maxX:Number = vertices[0].x;
            var minY:Number = vertices[0].y;
            var maxY:Number = vertices[0].y;

            for (var i:int = 1; i < vertices.length; i++)
            {
                var p:Point2D = vertices[i] as Point2D;
                if (p.x < minX) minX = p.x;
                if (p.x > maxX) maxX = p.x;
                if (p.y < minY) minY = p.y;
                if (p.y > maxY) maxY = p.y;
            }

            return new Rect2D(minX, minY, maxX - minX, maxY - minY);
        }

        /**
         * Computes the 2D convex hull using Andrew's monotone chain O(N log N) algorithm.
         */
        public function convexHull():Polygon2D
        {
            var n:int = vertices.length;
            if (n <= 3)
            {
                return this.clone() as Polygon2D;
            }

            // Clone and sort vertices by x, then y
            var pts:Array = [];
            for (var i:int = 0; i < n; i++)
            {
                pts.push((vertices[i] as Point2D).clone());
            }

            pts.sort(function(a:Point2D, b:Point2D):int {
                if (a.x < b.x) return -1;
                if (a.x > b.x) return 1;
                if (a.y < b.y) return -1;
                if (a.y > b.y) return 1;
                return 0;
            });

            // Build lower hull
            var lower:Array = [];
            for (var j:int = 0; j < pts.length; j++)
            {
                while (lower.length >= 2)
                {
                    var p1:Point2D = lower[lower.length - 2] as Point2D;
                    var p2:Point2D = lower[lower.length - 1] as Point2D;
                    var p3:Point2D = pts[j] as Point2D;
                    // Cross product: (p2 - p1) x (p3 - p1)
                    var cross:Number = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x);
                    if (cross <= 0)
                    {
                        lower.pop();
                    }
                    else
                    {
                        break;
                    }
                }
                lower.push(pts[j]);
            }

            // Build upper hull
            var upper:Array = [];
            for (var k:int = pts.length - 1; k >= 0; k--)
            {
                while (upper.length >= 2)
                {
                    var u1:Point2D = upper[upper.length - 2] as Point2D;
                    var u2:Point2D = upper[upper.length - 1] as Point2D;
                    var u3:Point2D = pts[k] as Point2D;
                    var uCross:Number = (u2.x - u1.x) * (u3.y - u1.y) - (u2.y - u1.y) * (u3.x - u1.x);
                    if (uCross <= 0)
                    {
                        upper.pop();
                    }
                    else
                    {
                        break;
                    }
                }
                upper.push(pts[k]);
            }

            // Remove last point of each half because it's repeated
            lower.pop();
            upper.pop();

            return new Polygon2D(lower.concat(upper));
        }

        public function clone():Object
        {
            var copyPts:Array = [];
            for (var i:int = 0; i < vertices.length; i++)
            {
                copyPts.push((vertices[i] as Point2D).clone());
            }
            return new Polygon2D(copyPts);
        }

        public function toJSON():Object
        {
            var raw:Array = [];
            for (var i:int = 0; i < vertices.length; i++)
            {
                raw.push((vertices[i] as Point2D).toJSON());
            }
            return { vertices: raw };
        }

        public function fromJSON(data:Object):void
        {
            vertices = [];
            if (data != null && data.vertices is Array)
            {
                var arr:Array = data.vertices as Array;
                for (var i:int = 0; i < arr.length; i++)
                {
                    var p:Point2D = new Point2D();
                    p.fromJSON(arr[i]);
                    vertices.push(p);
                }
            }
        }
    }
}
