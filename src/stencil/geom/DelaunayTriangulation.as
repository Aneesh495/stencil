package stencil.geom
{
    import stencil.core.MathUtil;

    /**
     * Triangle primitive for Delaunay triangulation meshes.
     */
    class Triangle
    {
        public var a:Point2D;
        public var b:Point2D;
        public var c:Point2D;

        public var circumCenterX:Number;
        public var circumCenterY:Number;
        public var circumRadiusSq:Number;

        public function Triangle(a:Point2D, b:Point2D, c:Point2D)
        {
            this.a = a;
            this.b = b;
            this.c = c;
            computeCircumcircle();
        }

        private function computeCircumcircle():void
        {
            var d:Number = 2.0 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
            if (MathUtil.fuzzyZero(d))
            {
                circumCenterX = (a.x + b.x + c.x) / 3.0;
                circumCenterY = (a.y + b.y + c.y) / 3.0;
                circumRadiusSq = 1e12;
                return;
            }

            var aSq:Number = a.x * a.x + a.y * a.y;
            var bSq:Number = b.x * b.x + b.y * b.y;
            var cSq:Number = c.x * c.x + c.y * c.y;

            var ux:Number = (aSq * (b.y - c.y) + bSq * (c.y - a.y) + cSq * (a.y - b.y)) / d;
            var uy:Number = (aSq * (c.x - b.x) + bSq * (a.x - c.x) + cSq * (b.x - a.x)) / d;

            circumCenterX = ux;
            circumCenterY = uy;

            var dx:Number = a.x - ux;
            var dy:Number = a.y - uy;
            circumRadiusSq = dx * dx + dy * dy;
        }

        public function inCircumcircle(p:Point2D):Boolean
        {
            var dx:Number = p.x - circumCenterX;
            var dy:Number = p.y - circumCenterY;
            return (dx * dx + dy * dy) <= (circumRadiusSq + 1e-9);
        }

        public function containsVertex(p:Point2D):Boolean
        {
            return p.fuzzyEquals(a) || p.fuzzyEquals(b) || p.fuzzyEquals(c);
        }
    }

    /**
     * Bowyer-Watson incremental Delaunay Triangulation algorithm.
     * Generates a conforming Delaunay mesh over a set of 2D planar points.
     */
    public class DelaunayTriangulation
    {
        /**
         * Computes Delaunay triangles for a given set of 2D points.
         * Returns an array of objects { a: Point2D, b: Point2D, c: Point2D }.
         */
        public static function triangulate(points:Array):Array
        {
            if (points == null || points.length < 3) return [];

            // Compute bounding box
            var minX:Number = points[0].x;
            var maxX:Number = points[0].x;
            var minY:Number = points[0].y;
            var maxY:Number = points[0].y;

            for (var i:int = 1; i < points.length; i++)
            {
                var pt:Point2D = points[i] as Point2D;
                if (pt.x < minX) minX = pt.x;
                if (pt.x > maxX) maxX = pt.x;
                if (pt.y < minY) minY = pt.y;
                if (pt.y > maxY) maxY = pt.y;
            }

            var dx:Number = (maxX - minX) * 2.0;
            var dy:Number = (maxY - minY) * 2.0;
            var deltaMax:Number = Math.max(dx, dy, 100.0);
            var midX:Number = (minX + maxX) * 0.5;
            var midY:Number = (minY + maxY) * 0.5;

            // Create super-triangle enclosing all points
            var stA:Point2D = new Point2D(midX - 2.0 * deltaMax, midY - deltaMax);
            var stB:Point2D = new Point2D(midX, midY + 2.0 * deltaMax);
            var stC:Point2D = new Point2D(midX + 2.0 * deltaMax, midY - deltaMax);

            var superTriangle:Triangle = new Triangle(stA, stB, stC);
            var triangles:Array = [superTriangle];

            // Incremental insertion
            for (var pIdx:int = 0; pIdx < points.length; pIdx++)
            {
                var p:Point2D = points[pIdx] as Point2D;
                var badTriangles:Array = [];

                for (var tIdx:int = 0; tIdx < triangles.length; tIdx++)
                {
                    var tri:Triangle = triangles[tIdx] as Triangle;
                    if (tri.inCircumcircle(p))
                    {
                        badTriangles.push(tri);
                    }
                }

                // Find boundary of polygonal hole
                var polygon:Array = [];
                for (var bIdx:int = 0; bIdx < badTriangles.length; bIdx++)
                {
                    var bTri:Triangle = badTriangles[bIdx] as Triangle;
                    var edges:Array = [
                        { p1: bTri.a, p2: bTri.b },
                        { p1: bTri.b, p2: bTri.c },
                        { p1: bTri.c, p2: bTri.a }
                    ];

                    for (var eIdx:int = 0; eIdx < 3; eIdx++)
                    {
                        var edge:Object = edges[eIdx];
                        var isShared:Boolean = false;

                        for (var oIdx:int = 0; oIdx < badTriangles.length; oIdx++)
                        {
                            if (oIdx == bIdx) continue;
                            var oTri:Triangle = badTriangles[oIdx] as Triangle;
                            if (edgeShared(edge, oTri))
                            {
                                isShared = true;
                                break;
                            }
                        }

                        if (!isShared)
                        {
                            polygon.push(edge);
                        }
                    }
                }

                // Remove bad triangles
                for (var rIdx:int = 0; rIdx < badTriangles.length; rIdx++)
                {
                    var remIdx:int = triangles.indexOf(badTriangles[rIdx]);
                    if (remIdx != -1)
                    {
                        triangles.splice(remIdx, 1);
                    }
                }

                // Re-triangulate hole with point p
                for (var polyIdx:int = 0; polyIdx < polygon.length; polyIdx++)
                {
                    var polyEdge:Object = polygon[polyIdx];
                    triangles.push(new Triangle(polyEdge.p1, polyEdge.p2, p));
                }
            }

            // Remove triangles sharing vertices with super-triangle
            var results:Array = [];
            for (var fIdx:int = 0; fIdx < triangles.length; fIdx++)
            {
                var fTri:Triangle = triangles[fIdx] as Triangle;
                if (!fTri.containsVertex(stA) && !fTri.containsVertex(stB) && !fTri.containsVertex(stC))
                {
                    results.push({
                        a: fTri.a.clone(),
                        b: fTri.b.clone(),
                        c: fTri.c.clone(),
                        circumCenter: new Point2D(fTri.circumCenterX, fTri.circumCenterY)
                    });
                }
            }

            return results;
        }

        private static function edgeShared(edge:Object, tri:Triangle):Boolean
        {
            var hasP1:Boolean = edge.p1.fuzzyEquals(tri.a) || edge.p1.fuzzyEquals(tri.b) || edge.p1.fuzzyEquals(tri.c);
            var hasP2:Boolean = edge.p2.fuzzyEquals(tri.a) || edge.p2.fuzzyEquals(tri.b) || edge.p2.fuzzyEquals(tri.c);
            return hasP1 && hasP2;
        }
    }
}
