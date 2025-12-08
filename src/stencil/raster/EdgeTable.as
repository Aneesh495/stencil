package stencil.raster
{
    import stencil.geom.Point2D;
    import stencil.geom.Polygon2D;

    /**
     * Edge record for scanline rasterization.
     */
    class RasterEdge
    {
        public var yMax:Number;
        public var xCurrent:Number;
        public var invSlope:Number; // dx / dy
        public var direction:int;   // +1 upward, -1 downward

        public function RasterEdge(yMax:Number, xStart:Number, invSlope:Number, direction:int)
        {
            this.yMax = yMax;
            this.xCurrent = xStart;
            this.invSlope = invSlope;
            this.direction = direction;
        }
    }

    /**
     * EdgeTable manages Global Edge Tables (GET) and Active Edge Tables (AET)
     * for polygon and path scanline rasterization.
     */
    public class EdgeTable
    {
        protected var _edgeBuckets:Object; // int y -> Array of RasterEdge
        protected var _minY:int;
        protected var _maxY:int;

        public function EdgeTable()
        {
            _edgeBuckets = {};
            _minY = int.MAX_VALUE;
            _maxY = int.MIN_VALUE;
        }

        public function get minY():int { return _minY; }
        public function get maxY():int { return _maxY; }

        public function addPolygon(poly:Polygon2D):void
        {
            if (poly == null || poly.vertexCount < 3) return;

            var n:int = poly.vertexCount;
            for (var i:int = 0; i < n; i++)
            {
                var p1:Point2D = poly.vertices[i] as Point2D;
                var p2:Point2D = poly.vertices[(i + 1) % n] as Point2D;

                if (Math.floor(p1.y) == Math.floor(p2.y))
                {
                    continue; // Skip horizontal edges
                }

                var top:Point2D = (p1.y < p2.y) ? p1 : p2;
                var bot:Point2D = (p1.y < p2.y) ? p2 : p1;
                var dir:int = (p1.y < p2.y) ? 1 : -1;

                var dy:Number = bot.y - top.y;
                var dx:Number = bot.x - top.x;
                var invSlope:Number = dx / dy;

                var yStart:int = Math.floor(top.y);
                var yEnd:int = Math.floor(bot.y);

                // Subpixel initial X adjustment
                var subY:Number = (yStart + 0.5) - top.y;
                var initialX:Number = top.x + invSlope * Math.max(0.0, subY);

                var edge:RasterEdge = new RasterEdge(bot.y, initialX, invSlope, dir);

                if (!_edgeBuckets.hasOwnProperty(yStart))
                {
                    _edgeBuckets[yStart] = [];
                }
                (_edgeBuckets[yStart] as Array).push(edge);

                if (yStart < _minY) _minY = yStart;
                if (yEnd > _maxY) _maxY = yEnd;
            }
        }

        public function getEdgesStartingAt(y:int):Array
        {
            if (_edgeBuckets.hasOwnProperty(y))
            {
                return (_edgeBuckets[y] as Array).slice();
            }
            return [];
        }
    }
}
