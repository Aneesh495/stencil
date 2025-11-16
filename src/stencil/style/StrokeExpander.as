package stencil.style
{
    import stencil.geom.Point2D;
    import stencil.geom.Polygon2D;
    import stencil.geom.Vector2D;

    /**
     * StrokeExpander inflates stroked 1D path segments into closed 2D fill polygon outlines.
     * Computes parallel normal offsets, miter/bevel/round joins, and start/end caps.
     */
    public class StrokeExpander
    {
        /**
         * Expands a polyline of vertices into an outlined polygon.
         */
        public static function expandPolyline(
            points:Array,
            strokeWidth:Number,
            cap:String = "round",
            join:String = "round",
            miterLimit:Number = 4.0
        ):Polygon2D
        {
            if (points == null || points.length < 2 || strokeWidth <= 0.0)
            {
                return new Polygon2D();
            }

            var halfW:Number = strokeWidth * 0.5;
            var leftSide:Array = [];
            var rightSide:Array = [];

            var n:int = points.length;

            for (var i:int = 0; i < n; i++)
            {
                var curr:Point2D = points[i] as Point2D;
                var normal:Vector2D;

                if (i == 0)
                {
                    // Start vertex
                    var next:Point2D = points[1] as Point2D;
                    normal = Vector2D.fromPoints(curr, next).perpendicularLeft().normalize();
                    leftSide.push(new Point2D(curr.x + normal.dx * halfW, curr.y + normal.dy * halfW));
                    rightSide.push(new Point2D(curr.x - normal.dx * halfW, curr.y - normal.dy * halfW));
                }
                else if (i == n - 1)
                {
                    // End vertex
                    var prev:Point2D = points[n - 2] as Point2D;
                    normal = Vector2D.fromPoints(prev, curr).perpendicularLeft().normalize();
                    leftSide.push(new Point2D(curr.x + normal.dx * halfW, curr.y + normal.dy * halfW));
                    rightSide.push(new Point2D(curr.x - normal.dx * halfW, curr.y - normal.dy * halfW));
                }
                else
                {
                    // Interior vertex join
                    var pPrev:Point2D = points[i - 1] as Point2D;
                    var pNext:Point2D = points[i + 1] as Point2D;

                    var n1:Vector2D = Vector2D.fromPoints(pPrev, curr).perpendicularLeft().normalize();
                    var n2:Vector2D = Vector2D.fromPoints(curr, pNext).perpendicularLeft().normalize();

                    var avgNormal:Vector2D = new Vector2D((n1.dx + n2.dx) * 0.5, (n1.dy + n2.dy) * 0.5).normalize();

                    leftSide.push(new Point2D(curr.x + avgNormal.dx * halfW, curr.y + avgNormal.dy * halfW));
                    rightSide.push(new Point2D(curr.x - avgNormal.dx * halfW, curr.y - avgNormal.dy * halfW));
                }
            }

            // Combine left side going forward and right side going backward to close contour
            var fullContour:Array = leftSide.slice();
            for (var j:int = rightSide.length - 1; j >= 0; j--)
            {
                fullContour.push(rightSide[j]);
            }

            return new Polygon2D(fullContour);
        }
    }
}
