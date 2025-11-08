package stencil.text
{
    /**
     * TextShaper processes raw Unicode text into positioned glyph runs with horizontal pair kerning.
     */
    public class TextShaper
    {
        protected var _kerningTable:Object; // "char1_char2" -> kernValue in font units

        public function TextShaper()
        {
            _kerningTable = {};
            initDefaultKerning();
        }

        private function initDefaultKerning():void
        {
            // Standard typographic pair kerning adjustments
            setKerning("A", "V", -70);
            setKerning("V", "A", -70);
            setKerning("A", "W", -50);
            setKerning("W", "A", -50);
            setKerning("T", "o", -45);
            setKerning("T", "e", -40);
            setKerning("T", "a", -40);
            setKerning("F", "a", -30);
            setKerning("P", "a", -35);
            setKerning("Y", "a", -60);
        }

        public function setKerning(c1:String, c2:String, amount:Number):void
        {
            _kerningTable[c1 + "_" + c2] = amount;
        }

        public function getKerning(c1:String, c2:String):Number
        {
            var key:String = c1 + "_" + c2;
            if (_kerningTable.hasOwnProperty(key))
            {
                return Number(_kerningTable[key]);
            }
            return 0.0;
        }

        /**
         * Shapes a Unicode string into a positioned glyph sequence.
         */
        public function shape(
            text:String,
            fontSize:Number = 16.0,
            unitsPerEm:Number = 1000.0,
            letterSpacing:Number = 0.0
        ):Array
        {
            var result:Array = [];
            if (text == null || text.length == 0) return result;

            var scale:Number = fontSize / unitsPerEm;
            var currentX:Number = 0.0;

            for (var i:int = 0; i < text.length; i++)
            {
                var ch:String = text.charAt(i);
                var charCode:int = text.charCodeAt(i);

                // Default average character width estimate (600 font units)
                var baseAdvance:Number = 600.0;
                if (ch == "i" || ch == "l" || ch == "I" || ch == ".") baseAdvance = 280.0;
                else if (ch == "m" || ch == "M" || ch == "W") baseAdvance = 850.0;
                else if (ch == " ") baseAdvance = 300.0;

                // Check pair kerning with next character
                var kern:Number = 0.0;
                if (i < text.length - 1)
                {
                    kern = getKerning(ch, text.charAt(i + 1));
                }

                var advancePx:Number = (baseAdvance + kern) * scale + letterSpacing;

                result.push({
                    char: ch,
                    charCode: charCode,
                    x: currentX,
                    y: 0.0,
                    xAdvance: advancePx
                });

                currentX += advancePx;
            }

            return result;
        }
    }
}
