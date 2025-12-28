package test.text
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.core.ByteArrayUtil;
    import stencil.text.SFNTParser;

    public class SFNTParserTest extends TestCase
    {
        public function SFNTParserTest()
        {
            super("SFNTParserTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testHeaderParsing",
                "testHeadTable"
            ];
        }

        public function testHeaderParsing():void
        {
            // Build mock SFNT byte buffer: 1 table ("head")
            var bytes:Array = [];
            // sfntVersion: 0x00010000
            ByteArrayUtil.writeUint32BE(bytes, 0, 0x00010000);
            // numTables: 1
            ByteArrayUtil.writeUint16BE(bytes, 4, 1);
            // searchRange, entrySelector, rangeShift (unused dummy values)
            ByteArrayUtil.writeUint16BE(bytes, 6, 16);
            ByteArrayUtil.writeUint16BE(bytes, 8, 4);
            ByteArrayUtil.writeUint16BE(bytes, 10, 0);

            // Table record: "head" at offset 28, length 54
            ByteArrayUtil.writeUTF8(bytes, "head");
            ByteArrayUtil.writeUint32BE(bytes, 16, 0x12345678); // checksum
            ByteArrayUtil.writeUint32BE(bytes, 20, 28);         // offset
            ByteArrayUtil.writeUint32BE(bytes, 24, 54);         // length

            // Pad up to offset 28
            while (bytes.length < 28) bytes.push(0);

            // Write 54 bytes of mock head table data
            // unitsPerEm at head + 18: 2048
            for (var i:int = 0; i < 54; i++) bytes.push(0);
            ByteArrayUtil.writeUint16BE(bytes, 28 + 18, 2048);
            ByteArrayUtil.writeUint16BE(bytes, 28 + 50, 1); // indexToLocFormat

            var parser:SFNTParser = new SFNTParser();
            parser.parse(bytes);

            Assert.isTrue(parser.hasTable("head"));
            Assert.equals(2048, parser.unitsPerEm);
            Assert.equals(1, parser.indexToLocFormat);
        }

        public function testHeadTable():void
        {
            var parser:SFNTParser = new SFNTParser();
            Assert.equals(1000, parser.unitsPerEm); // default
            Assert.equals(800, parser.ascender);
            Assert.equals(-200, parser.descender);
        }
    }
}
