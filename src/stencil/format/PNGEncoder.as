package stencil.format
{
    import stencil.core.ByteArrayUtil;
    import stencil.core.HashUtil;

    /**
     * Pure ActionScript 3 PNG (Portable Network Graphics) image chunk encoder.
     * Encodes 32-bit ARGB scanline pixel buffers into compliant PNG binary streams.
     */
    public class PNGEncoder
    {
        /**
         * Encodes a 32-bit ARGB pixel array into a PNG byte stream.
         * 
         * @param pixels Array of uint 0xAARRGGBB colors, length = width * height.
         * @param width Image width in pixels.
         * @param height Image height in pixels.
         * @return Array of unsigned bytes representing valid PNG image file.
         */
        public static function encode(pixels:Array, width:int, height:int):Array
        {
            var png:Array = [];

            // 1. PNG Signature (8 bytes)
            png.push(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);

            // 2. IHDR Chunk (Image Header)
            var ihdrData:Array = [];
            writeUint32(ihdrData, width);
            writeUint32(ihdrData, height);
            ihdrData.push(8); // Bit depth: 8
            ihdrData.push(6); // Color type: 6 (RGBA with alpha)
            ihdrData.push(0); // Compression method: 0 (Deflate)
            ihdrData.push(0); // Filter method: 0 (Standard adaptive)
            ihdrData.push(0); // Interlace method: 0 (No interlace)

            writeChunk(png, "IHDR", ihdrData);

            // 3. IDAT Chunk (Image Data)
            // Construct raw filtered scanlines: each row starts with filter byte 0 (None)
            var rawScanlines:Array = [];
            var ptr:int = 0;

            for (var y:int = 0; y < height; y++)
            {
                rawScanlines.push(0); // Filter type: None
                for (var x:int = 0; x < width; x++)
                {
                    var argb:uint = (ptr < pixels.length) ? uint(pixels[ptr++]) : 0;
                    var a:uint = (argb >>> 24) & 0xFF;
                    var r:uint = (argb >>> 16) & 0xFF;
                    var g:uint = (argb >>> 8) & 0xFF;
                    var b:uint = argb & 0xFF;
                    rawScanlines.push(r, g, b, a); // RGBA order
                }
            }

            // Deflate compression: use uncompressed / stored deflate blocks (RFC 1951)
            var idatData:Array = deflateStored(rawScanlines);
            writeChunk(png, "IDAT", idatData);

            // 4. IEND Chunk (Image Trailer)
            writeChunk(png, "IEND", []);

            return png;
        }

        /**
         * Encodes raw byte payload into valid RFC 1950 Zlib stream using RFC 1951 stored blocks.
         */
        private static function deflateStored(data:Array):Array
        {
            var zlib:Array = [];

            // Zlib header: CMF (Deflate, 32K window) = 0x78, FLG (Default compression, check bits) = 0x01
            zlib.push(0x78, 0x01);

            var totalLen:int = data.length;
            var offset:int = 0;
            var maxBlockSize:int = 65535;

            while (offset < totalLen)
            {
                var remaining:int = totalLen - offset;
                var blockSize:int = Math.min(remaining, maxBlockSize);
                var isLast:Boolean = (offset + blockSize) >= totalLen;

                // BFINAL and BTYPE (00 = stored block)
                zlib.push(isLast ? 0x01 : 0x00);

                // LEN (little-endian 16-bit)
                zlib.push(blockSize & 0xFF, (blockSize >> 8) & 0xFF);
                // NLEN (ones complement of LEN)
                var nlen:int = (~blockSize) & 0xFFFF;
                zlib.push(nlen & 0xFF, (nlen >> 8) & 0xFF);

                // Stored literal data bytes
                for (var i:int = 0; i < blockSize; i++)
                {
                    zlib.push(data[offset + i]);
                }

                offset += blockSize;
            }

            // Adler-32 checksum (big-endian 32-bit)
            var adler:uint = HashUtil.adler32(data);
            writeUint32(zlib, adler);

            return zlib;
        }

        private static function writeChunk(out:Array, typeStr:String, data:Array):void
        {
            // 4 bytes length
            writeUint32(out, data.length);

            var chunkStart:int = out.length;

            // 4 bytes type
            out.push(
                typeStr.charCodeAt(0) & 0xFF,
                typeStr.charCodeAt(1) & 0xFF,
                typeStr.charCodeAt(2) & 0xFF,
                typeStr.charCodeAt(3) & 0xFF
            );

            // Data bytes
            for (var i:int = 0; i < data.length; i++)
            {
                out.push(data[i]);
            }

            // 4 bytes CRC32 over type + data
            var crc:uint = HashUtil.crc32(out, chunkStart, 4 + data.length);
            writeUint32(out, crc);
        }

        private static function writeUint32(out:Array, val:uint):void
        {
            out.push(
                (val >>> 24) & 0xFF,
                (val >>> 16) & 0xFF,
                (val >>> 8) & 0xFF,
                val & 0xFF
            );
        }
    }
}
