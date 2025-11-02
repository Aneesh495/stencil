package stencil.text
{
    import stencil.core.ByteArrayUtil;
    import stencil.core.StencilError;

    /**
     * Binary SFNT font parser reading TrueType and OpenType table directories.
     * Decodes head, hhea, maxp, hmtx, and cmap character-to-glyph mappings directly from byte streams.
     */
    public class SFNTParser
    {
        public var sfntVersion:uint;
        public var numTables:uint;
        public var tables:Object; // Tag -> FontTable

        public var unitsPerEm:uint;
        public var indexToLocFormat:int; // 0 for short (16-bit), 1 for long (32-bit)
        public var ascender:int;
        public var descender:int;
        public var lineGap:int;
        public var numGlyphs:uint;
        public var numOfLongHorMetrics:uint;

        protected var _cmapFormat4:Object; // charCode -> glyphID

        public function SFNTParser()
        {
            tables = {};
            unitsPerEm = 1000;
            indexToLocFormat = 0;
            ascender = 800;
            descender = -200;
            lineGap = 0;
            numGlyphs = 0;
            numOfLongHorMetrics = 0;
            _cmapFormat4 = {};
        }

        public function hasTable(tag:String):Boolean
        {
            return tables.hasOwnProperty(tag);
        }

        public function getTable(tag:String):FontTable
        {
            return tables[tag] as FontTable;
        }

        /**
         * Parses the root SFNT directory and key metadata tables from an array of unsigned bytes.
         */
        public function parse(bytes:Array):void
        {
            if (bytes == null || bytes.length < 12)
            {
                throw new StencilError("Invalid font stream: insufficient bytes for SFNT header", StencilError.CATEGORY_TYPOGRAPHY);
            }

            sfntVersion = ByteArrayUtil.readUint32BE(bytes, 0);
            numTables = ByteArrayUtil.readUint16BE(bytes, 4);

            tables = {};
            var offset:int = 12;

            for (var i:int = 0; i < numTables && (offset + 16) <= bytes.length; i++)
            {
                var tag:String = ByteArrayUtil.readUTF8(bytes, offset, 4);
                var checkSum:uint = ByteArrayUtil.readUint32BE(bytes, offset + 4);
                var tableOffset:uint = ByteArrayUtil.readUint32BE(bytes, offset + 8);
                var tableLength:uint = ByteArrayUtil.readUint32BE(bytes, offset + 12);

                tables[tag] = new FontTable(tag, checkSum, tableOffset, tableLength);
                offset += 16;
            }

            if (hasTable("head")) parseHead(bytes);
            if (hasTable("hhea")) parseHhea(bytes);
            if (hasTable("maxp")) parseMaxp(bytes);
            if (hasTable("cmap")) parseCmap(bytes);
        }

        protected function parseHead(bytes:Array):void
        {
            var t:FontTable = getTable("head");
            var off:int = t.offset;
            if (off + 54 > bytes.length) return;

            unitsPerEm = ByteArrayUtil.readUint16BE(bytes, off + 18);
            indexToLocFormat = int(ByteArrayUtil.readUint16BE(bytes, off + 50));
        }

        protected function parseHhea(bytes:Array):void
        {
            var t:FontTable = getTable("hhea");
            var off:int = t.offset;
            if (off + 36 > bytes.length) return;

            var rawAsc:int = ByteArrayUtil.readUint16BE(bytes, off + 4);
            ascender = (rawAsc > 32767) ? (rawAsc - 65536) : rawAsc;

            var rawDesc:int = ByteArrayUtil.readUint16BE(bytes, off + 6);
            descender = (rawDesc > 32767) ? (rawDesc - 65536) : rawDesc;

            var rawGap:int = ByteArrayUtil.readUint16BE(bytes, off + 8);
            lineGap = (rawGap > 32767) ? (rawGap - 65536) : rawGap;

            numOfLongHorMetrics = ByteArrayUtil.readUint16BE(bytes, off + 34);
        }

        protected function parseMaxp(bytes:Array):void
        {
            var t:FontTable = getTable("maxp");
            var off:int = t.offset;
            if (off + 6 > bytes.length) return;

            numGlyphs = ByteArrayUtil.readUint16BE(bytes, off + 4);
        }

        protected function parseCmap(bytes:Array):void
        {
            var t:FontTable = getTable("cmap");
            var off:int = t.offset;
            if (off + 4 > bytes.length) return;

            var numSubtables:uint = ByteArrayUtil.readUint16BE(bytes, off + 2);
            var subtableOffset:int = off + 4;

            for (var i:int = 0; i < numSubtables; i++)
            {
                var platformID:uint = ByteArrayUtil.readUint16BE(bytes, subtableOffset);
                var encodingID:uint = ByteArrayUtil.readUint16BE(bytes, subtableOffset + 2);
                var subOffset:uint = ByteArrayUtil.readUint32BE(bytes, subtableOffset + 4);

                // Look for Windows Unicode BMP (Platform 3, Encoding 1) or Unicode (Platform 0)
                if ((platformID == 3 && encodingID == 1) || platformID == 0)
                {
                    parseCmapFormat4(bytes, off + subOffset);
                    break;
                }
                subtableOffset += 8;
            }
        }

        protected function parseCmapFormat4(bytes:Array, offset:int):void
        {
            if (offset + 14 > bytes.length) return;
            var format:uint = ByteArrayUtil.readUint16BE(bytes, offset);
            if (format != 4) return;

            var segCountX2:uint = ByteArrayUtil.readUint16BE(bytes, offset + 6);
            var segCount:int = segCountX2 >> 1;

            var endCodeOffset:int = offset + 14;
            var startCodeOffset:int = endCodeOffset + segCountX2 + 2; // +2 for reservedPad
            var idDeltaOffset:int = startCodeOffset + segCountX2;
            var idRangeOffsetOffset:int = idDeltaOffset + segCountX2;

            _cmapFormat4 = {};

            for (var s:int = 0; s < segCount; s++)
            {
                var endCode:uint = ByteArrayUtil.readUint16BE(bytes, endCodeOffset + s * 2);
                var startCode:uint = ByteArrayUtil.readUint16BE(bytes, startCodeOffset + s * 2);
                var idDelta:int = ByteArrayUtil.readUint16BE(bytes, idDeltaOffset + s * 2);
                if (idDelta > 32767) idDelta -= 65536;

                if (startCode == 0xFFFF) break;

                for (var code:uint = startCode; code <= endCode; code++)
                {
                    var glyphId:uint = (code + idDelta) & 0xFFFF;
                    _cmapFormat4[code] = glyphId;
                }
            }
        }

        public function getGlyphIndex(charCode:uint):uint
        {
            if (_cmapFormat4.hasOwnProperty(charCode))
            {
                return uint(_cmapFormat4[charCode]);
            }
            return 0; // Missing glyph (.notdef)
        }
    }
}
