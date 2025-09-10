package stencil.core
{
    /**
     * RFC 4122 version 4 UUID generator, parser, and validator.
     * Generates collision-resistant identifiers for distributed CRDT scene elements.
     */
    public class UUID
    {
        private var _str:String;

        public function UUID(uuidString:String = null)
        {
            if (uuidString != null && isValid(uuidString))
            {
                _str = uuidString.toLowerCase();
            }
            else
            {
                _str = generate();
            }
        }

        public function get value():String
        {
            return _str;
        }

        /**
         * Generates a pseudo-random RFC 4122 version 4 UUID string.
         */
        public static function generate():String
        {
            var hex:Array = [];
            for (var i:int = 0; i < 256; i++)
            {
                var h:String = i.toString(16);
                hex[i] = (h.length < 2) ? ("0" + h) : h;
            }

            var r:Array = [];
            for (var j:int = 0; j < 16; j++)
            {
                r[j] = int(Math.random() * 256);
            }

            // Set version 4 bits: 0100xxxx
            r[6] = (r[6] & 0x0f) | 0x40;
            // Set variant bits: 10xxxxxx
            r[8] = (r[8] & 0x3f) | 0x80;

            return hex[r[0]] + hex[r[1]] + hex[r[2]] + hex[r[3]] + "-" +
                   hex[r[4]] + hex[r[5]] + "-" +
                   hex[r[6]] + hex[r[7]] + "-" +
                   hex[r[8]] + hex[r[9]] + "-" +
                   hex[r[10]] + hex[r[11]] + hex[r[12]] + hex[r[13]] + hex[r[14]] + hex[r[15]];
        }

        /**
         * Validates standard 36-character hyphenated UUID format.
         */
        public static function isValid(str:String):Boolean
        {
            if (str == null || str.length != 36) return false;

            for (var i:int = 0; i < 36; i++)
            {
                var c:String = str.charAt(i);
                if (i == 8 || i == 13 || i == 18 || i == 23)
                {
                    if (c != "-") return false;
                }
                else
                {
                    var code:int = str.charCodeAt(i);
                    var isHex:Boolean = (code >= 48 && code <= 57) || // 0-9
                                        (code >= 65 && code <= 70) || // A-F
                                        (code >= 97 && code <= 102);  // a-f
                    if (!isHex) return false;
                }
            }
            return true;
        }

        public function equals(other:UUID):Boolean
        {
            if (other == null) return false;
            return _str == other.value;
        }

        public function toString():String
        {
            return _str;
        }
    }
}
