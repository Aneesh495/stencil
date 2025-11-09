package stencil.text
{
    import stencil.geom.Rect2D;

    /**
     * TextLayoutResult holds the positioned line frames, glyph runs, and baseline bounds for laid out text.
     */
    public class TextLayoutResult
    {
        public var lines:Array; // Array of { text: String, x: Number, y: Number, width: Number, height: Number, baseline: Number, glyphs: Array }
        public var totalBounds:Rect2D;

        public function TextLayoutResult()
        {
            lines = [];
            totalBounds = new Rect2D(0.0, 0.0, 0.0, 0.0);
        }

        public function get lineCount():int
        {
            return lines.length;
        }

        public function addLine(line:Object):void
        {
            lines.push(line);
            var lineBounds:Rect2D = new Rect2D(line.x, line.y, line.width, line.height);
            totalBounds = totalBounds.union(lineBounds);
        }

        /**
         * Resolves cursor character index given a 2D hit coordinate relative to text box origin.
         */
        public function hitTest(localX:Number, localY:Number):int
        {
            if (lines.length == 0) return 0;

            // Find closest line
            var bestLineIdx:int = 0;
            var bestDistY:Number = Number.MAX_VALUE;

            for (var i:int = 0; i < lines.length; i++)
            {
                var line:Object = lines[i];
                var midY:Number = line.y + line.height * 0.5;
                var distY:Number = Math.abs(localY - midY);
                if (distY < bestDistY)
                {
                    bestDistY = distY;
                    bestLineIdx = i;
                }
            }

            var targetLine:Object = lines[bestLineIdx];
            var glyphs:Array = targetLine.glyphs as Array;
            if (glyphs == null || glyphs.length == 0) return 0;

            var charOffset:int = 0;
            for (var prevLine:int = 0; prevLine < bestLineIdx; prevLine++)
            {
                charOffset += (lines[prevLine].text as String).length + 1; // +1 for newline
            }

            // Find character on line closest to localX
            for (var g:int = 0; g < glyphs.length; g++)
            {
                var glyph:Object = glyphs[g];
                var glyphMidX:Number = targetLine.x + glyph.x + glyph.xAdvance * 0.5;
                if (localX < glyphMidX)
                {
                    return charOffset + g;
                }
            }

            return charOffset + glyphs.length;
        }
    }
}
