package stencil.core
{
    /**
     * Non-cryptographic hashing and checksum algorithms.
     * Used for scene graph damage hashing, PNG integrity checksums, and CRDT causal state digests.
     */
    public class HashUtil
    {
        private static var _crcTable:Array = null;

        /**
         * Computes 32-bit Fowler-Noll-Vo hash (FNV-1a).
         */
        public static function fnv1a32(str:String):uint
        {
            var hash:uint = 2166136261;
            if (str == null) return hash;

            for (var i:int = 0; i < str.length; i++)
            {
                hash ^= (str.charCodeAt(i) & 0xFF);
                // Multiply by FNV prime: 16777619
                hash = (hash * 16777619) >>> 0;
            }
            return hash;
        }

        /**
         * Computes 32-bit MurmurHash3.
         */
        public static function murmur3(str:String, seed:uint = 0):uint
        {
            var h1:uint = seed;
            var c1:uint = 0xcc9e2d51;
            var c2:uint = 0x1b873593;

            if (str == null) return h1;

            var len:int = str.length;
            var roundedEnd:int = len & ~0x1;

            for (var i:int = 0; i < roundedEnd; i += 2)
            {
                var k1:uint = str.charCodeAt(i) | (str.charCodeAt(i + 1) << 16);
                k1 = ((k1 * c1) >>> 0);
                k1 = ((k1 << 15) | (k1 >>> 17)) >>> 0;
                k1 = ((k1 * c2) >>> 0);

                h1 ^= k1;
                h1 = ((h1 << 13) | (h1 >>> 19)) >>> 0;
                h1 = (((h1 * 5) >>> 0) + 0xe6546b64) >>> 0;
            }

            if ((len & 1) == 1)
            {
                var kRemaining:uint = str.charCodeAt(roundedEnd);
                kRemaining = ((kRemaining * c1) >>> 0);
                kRemaining = ((kRemaining << 15) | (kRemaining >>> 17)) >>> 0;
                kRemaining = ((kRemaining * c2) >>> 0);
                h1 ^= kRemaining;
            }

            h1 ^= (len * 2);
            h1 ^= (h1 >>> 16);
            h1 = ((h1 * 0x85ebca6b) >>> 0);
            h1 ^= (h1 >>> 13);
            h1 = ((h1 * 0xc2b2ae35) >>> 0);
            h1 ^= (h1 >>> 16);

            return h1 >>> 0;
        }

        /**
         * Initializes CRC32 lookup table according to IEEE 802.3 standard.
         */
        private static function initCRCTable():void
        {
            _crcTable = new Array(256);
            for (var i:uint = 0; i < 256; i++)
            {
                var c:uint = i;
                for (var j:int = 0; j < 8; j++)
                {
                    if ((c & 1) != 0)
                    {
                        c = 0xedb88320 ^ (c >>> 1);
                    }
                    else
                    {
                        c = c >>> 1;
                    }
                }
                _crcTable[i] = c >>> 0;
            }
        }

        /**
         * Computes standard CRC32 checksum over an array of bytes.
         */
        public static function crc32(bytes:Array, offset:int = 0, length:int = -1):uint
        {
            if (_crcTable == null)
            {
                initCRCTable();
            }

            if (length < 0)
            {
                length = bytes.length - offset;
            }

            var c:uint = 0xffffffff;
            var end:int = offset + length;

            for (var i:int = offset; i < end; i++)
            {
                var b:uint = bytes[i] & 0xFF;
                c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
            }

            return (c ^ 0xffffffff) >>> 0;
        }

        /**
         * Computes Adler-32 checksum (used in zlib wrapping).
         */
        public static function adler32(bytes:Array, offset:int = 0, length:int = -1):uint
        {
            var MOD_ADLER:uint = 65521;
            var a:uint = 1;
            var b:uint = 0;

            if (length < 0)
            {
                length = bytes.length - offset;
            }

            var end:int = offset + length;
            for (var i:int = offset; i < end; i++)
            {
                a = (a + (bytes[i] & 0xFF)) % MOD_ADLER;
                b = (b + a) % MOD_ADLER;
            }

            return ((b << 16) | a) >>> 0;
        }
    }
}
