package stencil.core
{
    /**
     * Binary stream manipulation and endianness conversion utilities.
     * Operates over byte buffers for SFNT font decoding, PDF binary streams, and PNG chunks.
     */
    public class ByteArrayUtil
    {
        /**
         * Writes an unsigned 16-bit integer in big-endian format.
         */
        public static function writeUint16BE(bytes:Array, offset:int, val:uint):void
        {
            bytes[offset]     = (val >> 8) & 0xFF;
            bytes[offset + 1] = val & 0xFF;
        }

        /**
         * Reads an unsigned 16-bit integer in big-endian format.
         */
        public static function readUint16BE(bytes:Array, offset:int):uint
        {
            return ((bytes[offset] & 0xFF) << 8) | (bytes[offset + 1] & 0xFF);
        }

        /**
         * Writes an unsigned 16-bit integer in little-endian format.
         */
        public static function writeUint16LE(bytes:Array, offset:int, val:uint):void
        {
            bytes[offset]     = val & 0xFF;
            bytes[offset + 1] = (val >> 8) & 0xFF;
        }

        /**
         * Reads an unsigned 16-bit integer in little-endian format.
         */
        public static function readUint16LE(bytes:Array, offset:int):uint
        {
            return (bytes[offset] & 0xFF) | ((bytes[offset + 1] & 0xFF) << 8);
        }

        /**
         * Writes an unsigned 32-bit integer in big-endian format.
         */
        public static function writeUint32BE(bytes:Array, offset:int, val:uint):void
        {
            bytes[offset]     = (val >>> 24) & 0xFF;
            bytes[offset + 1] = (val >>> 16) & 0xFF;
            bytes[offset + 2] = (val >>> 8) & 0xFF;
            bytes[offset + 3] = val & 0xFF;
        }

        /**
         * Reads an unsigned 32-bit integer in big-endian format.
         */
        public static function readUint32BE(bytes:Array, offset:int):uint
        {
            return (((bytes[offset] & 0xFF) << 24) >>> 0) +
                   ((bytes[offset + 1] & 0xFF) << 16) +
                   ((bytes[offset + 2] & 0xFF) << 8) +
                   (bytes[offset + 3] & 0xFF);
        }

        /**
         * Writes an unsigned 32-bit integer in little-endian format.
         */
        public static function writeUint32LE(bytes:Array, offset:int, val:uint):void
        {
            bytes[offset]     = val & 0xFF;
            bytes[offset + 1] = (val >>> 8) & 0xFF;
            bytes[offset + 2] = (val >>> 16) & 0xFF;
            bytes[offset + 3] = (val >>> 24) & 0xFF;
        }

        /**
         * Reads an unsigned 32-bit integer in little-endian format.
         */
        public static function readUint32LE(bytes:Array, offset:int):uint
        {
            return (bytes[offset] & 0xFF) +
                   ((bytes[offset + 1] & 0xFF) << 8) +
                   ((bytes[offset + 2] & 0xFF) << 16) +
                   (((bytes[offset + 3] & 0xFF) << 24) >>> 0);
        }

        /**
         * Encodes a variable-length unsigned integer (LEB128/Varint).
         */
        public static function writeVarint(bytes:Array, val:uint):void
        {
            while (val >= 0x80)
            {
                bytes.push((val & 0x7F) | 0x80);
                val >>>= 7;
            }
            bytes.push(val & 0x7F);
        }

        /**
         * Decodes a variable-length unsigned integer from a byte stream.
         * Returns an object { value: uint, bytesRead: int }.
         */
        public static function readVarint(bytes:Array, offset:int):Object
        {
            var res:uint = 0;
            var shift:int = 0;
            var count:int = 0;

            while (offset < bytes.length)
            {
                var b:int = bytes[offset++];
                count++;
                res |= (b & 0x7F) << shift;
                if ((b & 0x80) == 0)
                {
                    break;
                }
                shift += 7;
            }

            return { value: res, bytesRead: count };
        }

        /**
         * Writes UTF-8 encoded text into a byte array.
         */
        public static function writeUTF8(bytes:Array, str:String):void
        {
            if (str == null) return;
            for (var i:int = 0; i < str.length; i++)
            {
                var c:int = str.charCodeAt(i);
                if (c < 0x80)
                {
                    bytes.push(c);
                }
                else if (c < 0x800)
                {
                    bytes.push(0xC0 | (c >> 6));
                    bytes.push(0x80 | (c & 0x3F));
                }
                else if (c < 0x10000)
                {
                    bytes.push(0xE0 | (c >> 12));
                    bytes.push(0x80 | ((c >> 6) & 0x3F));
                    bytes.push(0x80 | (c & 0x3F));
                }
                else
                {
                    bytes.push(0xF0 | (c >> 18));
                    bytes.push(0x80 | ((c >> 12) & 0x3F));
                    bytes.push(0x80 | ((c >> 6) & 0x3F));
                    bytes.push(0x80 | (c & 0x3F));
                }
            }
        }

        /**
         * Reads UTF-8 encoded string from byte slice.
         */
        public static function readUTF8(bytes:Array, offset:int, length:int):String
        {
            var out:String = "";
            var end:int = offset + length;
            var i:int = offset;

            while (i < end && i < bytes.length)
            {
                var b1:int = bytes[i++] & 0xFF;
                if (b1 < 0x80)
                {
                    out += String.fromCharCode(b1);
                }
                else if ((b1 & 0xE0) == 0xC0)
                {
                    var b2:int = bytes[i++] & 0xFF;
                    out += String.fromCharCode(((b1 & 0x1F) << 6) | (b2 & 0x3F));
                }
                else if ((b1 & 0xF0) == 0xE0)
                {
                    var b2_3:int = bytes[i++] & 0xFF;
                    var b3_3:int = bytes[i++] & 0xFF;
                    out += String.fromCharCode(((b1 & 0x0F) << 12) | ((b2_3 & 0x3F) << 6) | (b3_3 & 0x3F));
                }
            }
            return out;
        }

        /**
         * Converts byte array to hex string.
         */
        public static function toHexString(bytes:Array):String
        {
            var hex:String = "";
            for (var i:int = 0; i < bytes.length; i++)
            {
                var s:String = (bytes[i] & 0xFF).toString(16);
                if (s.length < 2) s = "0" + s;
                hex += s;
            }
            return hex;
        }
    }
}
