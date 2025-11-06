package stencil.text
{
    import stencil.geom.Matrix2D;
    import stencil.geom.PathData;
    import stencil.geom.Rect2D;

    /**
     * GlyphOutline represents the vector outline and advance metrics for a single typographic glyph.
     */
    public class GlyphOutline
    {
        public var glyphId:uint;
        public var advanceWidth:Number;
        public var leftSideBearing:Number;
        public var pathData:PathData;

        public function GlyphOutline(
            glyphId:uint = 0,
            advanceWidth:Number = 500.0,
            leftSideBearing:Number = 0.0,
            pathData:PathData = null
        )
        {
            this.glyphId = glyphId;
            this.advanceWidth = advanceWidth;
            this.leftSideBearing = leftSideBearing;
            this.pathData = (pathData != null) ? pathData : new PathData();
        }

        public function bounds():Rect2D
        {
            return pathData.bounds();
        }

        /**
         * Generates a transformed PathData positioned at baseline (x, y) with target font size.
         */
        public function toPathAt(x:Number, y:Number, fontSize:Number, unitsPerEm:Number):PathData
        {
            var scale:Number = fontSize / unitsPerEm;
            // TrueType Y-axis points upward; flip Y for screen coordinates
            var m:Matrix2D = Matrix2D.scaling(scale, -scale);
            m.translate(x, y);
            return pathData.transform(m);
        }
    }
}
