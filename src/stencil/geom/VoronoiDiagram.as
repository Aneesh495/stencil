package stencil.geom
{
    /**
     * VoronoiDiagram extracts the geometric dual graph of a Delaunay triangulation.
     * Computes Voronoi cells for each generator site, clipped to an optional bounding rectangle.
     */
    public class VoronoiDiagram
    {
        public static function generate(sites:Array, clipBounds:Rect2D = null):Array
        {
            if (sites == null || sites.length < 3) return [];

            var triangles:Array = DelaunayTriangulation.triangulate(sites);
            if (triangles.length == 0) return [];

            var cells:Array = [];

            // For each site, collect circumcenters of triangles containing that site
            for (var sIdx:int = 0; sIdx < sites.length; sIdx++)
            {
                var site:Point2D = sites[sIdx] as Point2D;
                var cellVertices:Array = [];

                for (var tIdx:int = 0; tIdx < triangles.length; tIdx++)
                {
                    var tri:Object = triangles[tIdx];
                    if (site.fuzzyEquals(tri.a) || site.fuzzyEquals(tri.b) || site.fuzzyEquals(tri.c))
                    {
                        var cc:Point2D = tri.circumCenter as Point2D;
                        if (!containsPoint(cellVertices, cc))
                        {
                            cellVertices.push(cc);
                        }
                    }
                }

                if (cellVertices.length >= 3)
                {
                    // Sort vertices angularly around site to form valid convex polygon
                    cellVertices.sort(function(a:Point2D, b:Point2D):int {
                        var angleA:Number = Math.atan2(a.y - site.y, a.x - site.x);
                        var angleB:Number = Math.atan2(b.y - site.y, b.x - site.x);
                        if (angleA < angleB) return -1;
                        if (angleA > angleB) return 1;
                        return 0;
                    });

                    var poly:Polygon2D = new Polygon2D(cellVertices);
                    if (clipBounds != null)
                    {
                        var clipPoly:Polygon2D = new Polygon2D([
                            new Point2D(clipBounds.left, clipBounds.top),
                            new Point2D(clipBounds.right, clipBounds.top),
                            new Point2D(clipBounds.right, clipBounds.bottom),
                            new Point2D(clipBounds.left, clipBounds.bottom)
                        ]);
                        var clipped:Array = PolygonClipper.intersect(poly, clipPoly);
                        for (var c:int = 0; c < clipped.length; c++)
                        {
                            cells.push({ site: site.clone(), cell: clipped[c] });
                        }
                    }
                    else
                    {
                        cells.push({ site: site.clone(), cell: poly });
                    }
                }
            }

            return cells;
        }

        private static function containsPoint(list:Array, pt:Point2D):Boolean
        {
            for (var i:int = 0; i < list.length; i++)
            {
                if (pt.fuzzyEquals(list[i] as Point2D, 1e-4))
                {
                    return true;
                }
            }
            return false;
        }
    }
}
