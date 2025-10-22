package stencil.scene
{
    import stencil.geom.Rect2D;

    /**
     * DamageTracker accumulates dirty invalidation rectangles across frame updates.
     * Coalesces overlapping rects to minimize raster redraw area and GPU blit overhead.
     */
    public class DamageTracker
    {
        protected var _dirtyRects:Array;
        protected var _maxRegions:int;

        public function DamageTracker(maxRegions:int = 8)
        {
            _dirtyRects = [];
            _maxRegions = maxRegions;
        }

        public function get hasDamage():Boolean
        {
            return _dirtyRects.length > 0;
        }

        public function get dirtyCount():int
        {
            return _dirtyRects.length;
        }

        /**
         * Adds an invalidated region to the damage tracker.
         */
        public function addDamage(rect:Rect2D):void
        {
            if (rect == null || rect.isEmpty()) return;

            // Quantize to integer pixel boundary
            var l:Number = Math.floor(rect.left);
            var t:Number = Math.floor(rect.top);
            var r:Number = Math.ceil(rect.right);
            var b:Number = Math.ceil(rect.bottom);
            var pixelRect:Rect2D = new Rect2D(l, t, r - l, b - t);

            // Attempt to merge with existing overlapping rect
            var merged:Boolean = false;
            for (var i:int = 0; i < _dirtyRects.length; i++)
            {
                var existing:Rect2D = _dirtyRects[i] as Rect2D;
                if (existing.intersects(pixelRect))
                {
                    _dirtyRects[i] = existing.union(pixelRect);
                    merged = true;
                    break;
                }
            }

            if (!merged)
            {
                _dirtyRects.push(pixelRect);
            }

            // Coalesce if exceeding max region threshold
            if (_dirtyRects.length > _maxRegions)
            {
                coalesce();
            }
        }

        /**
         * Merges closest bounding boxes until list fits within maxRegions.
         */
        public function coalesce():void
        {
            while (_dirtyRects.length > _maxRegions)
            {
                var bestI:int = 0;
                var bestJ:int = 1;
                var minArea:Number = Number.MAX_VALUE;

                for (var i:int = 0; i < _dirtyRects.length - 1; i++)
                {
                    for (var j:int = i + 1; j < _dirtyRects.length; j++)
                    {
                        var u:Rect2D = (_dirtyRects[i] as Rect2D).union(_dirtyRects[j] as Rect2D);
                        var area:Number = u.area();
                        if (area < minArea)
                        {
                            minArea = area;
                            bestI = i;
                            bestJ = j;
                        }
                    }
                }

                var merged:Rect2D = (_dirtyRects[bestI] as Rect2D).union(_dirtyRects[bestJ] as Rect2D);
                _dirtyRects.splice(bestJ, 1);
                _dirtyRects[bestI] = merged;
            }
        }

        /**
         * Returns an array of coalesced dirty regions.
         */
        public function getDamagedRegions():Array
        {
            var results:Array = [];
            for (var i:int = 0; i < _dirtyRects.length; i++)
            {
                results.push((_dirtyRects[i] as Rect2D).clone());
            }
            return results;
        }

        /**
         * Returns total bounding box enclosing all dirty regions.
         */
        public function getTotalDamage():Rect2D
        {
            if (_dirtyRects.length == 0) return new Rect2D(0.0, 0.0, 0.0, 0.0);

            var total:Rect2D = (_dirtyRects[0] as Rect2D).clone() as Rect2D;
            for (var i:int = 1; i < _dirtyRects.length; i++)
            {
                total = total.union(_dirtyRects[i] as Rect2D);
            }
            return total;
        }

        /**
         * Clears all recorded damage.
         */
        public function reset():void
        {
            _dirtyRects = [];
        }
    }
}
