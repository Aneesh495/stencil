package stencil.layout
{
    import stencil.geom.Rect2D;

    /**
     * Responsive 12-column grid layout guide system.
     * Generates column bounds, margins, and gutters for UI templates and structured layouts.
     */
    public class GridSystem
    {
        public var columns:int;
        public var gutter:Number;
        public var margin:Number;

        public function GridSystem(columns:int = 12, gutter:Number = 24.0, margin:Number = 48.0)
        {
            this.columns = Math.max(1, columns);
            this.gutter = gutter;
            this.margin = margin;
        }

        /**
         * Calculates individual column width based on available container width.
         */
        public function getColumnWidth(containerWidth:Number):Number
        {
            var contentWidth:Number = containerWidth - (2.0 * margin);
            var totalGutters:Number = (columns - 1) * gutter;
            var netWidth:Number = contentWidth - totalGutters;
            return Math.max(1.0, netWidth / columns);
        }

        /**
         * Computes the bounding rectangle for a column span starting at colIndex.
         */
        public function getColumnRect(
            colIndex:int,
            colSpan:int,
            containerWidth:Number,
            containerHeight:Number
        ):Rect2D
        {
            var colW:Number = getColumnWidth(containerWidth);
            var x:Number = margin + colIndex * (colW + gutter);
            var w:Number = colSpan * colW + (colSpan - 1) * gutter;
            return new Rect2D(x, 0.0, w, containerHeight);
        }

        /**
         * Snaps horizontal coordinate x to nearest column boundary.
         */
        public function snapToColumn(x:Number, containerWidth:Number, tolerance:Number = 12.0):Number
        {
            var colW:Number = getColumnWidth(containerWidth);
            for (var i:int = 0; i <= columns; i++)
            {
                var leftEdge:Number = margin + i * (colW + gutter);
                if (Math.abs(x - leftEdge) <= tolerance)
                {
                    return leftEdge;
                }
                var rightEdge:Number = leftEdge + colW;
                if (Math.abs(x - rightEdge) <= tolerance)
                {
                    return rightEdge;
                }
            }
            return x;
        }
    }
}
