package stencil.text
{
    /**
     * FontMetrics encapsulates vertical typographic measurements normalized to font units.
     */
    public class FontMetrics
    {
        public var unitsPerEm:Number;
        public var ascender:Number;
        public var descender:Number;
        public var lineGap:Number;
        public var capHeight:Number;
        public var xHeight:Number;

        public function FontMetrics(
            unitsPerEm:Number = 1000.0,
            ascender:Number = 800.0,
            descender:Number = -200.0,
            lineGap:Number = 90.0,
            capHeight:Number = 700.0,
            xHeight:Number = 500.0
        )
        {
            this.unitsPerEm = unitsPerEm;
            this.ascender = ascender;
            this.descender = descender;
            this.lineGap = lineGap;
            this.capHeight = capHeight;
            this.xHeight = xHeight;
        }

        /**
         * Scales metrics to target pixel font size.
         */
        public function scale(fontSize:Number):Object
        {
            var factor:Number = fontSize / unitsPerEm;
            return {
                fontSize: fontSize,
                ascender: ascender * factor,
                descender: descender * factor,
                lineGap: lineGap * factor,
                lineHeight: (ascender - descender + lineGap) * factor,
                capHeight: capHeight * factor,
                xHeight: xHeight * factor
            };
        }
    }
}
