package test.format
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.core.ByteArrayUtil;
    import stencil.format.PNGEncoder;

    public class PNGEncoderTest extends TestCase
    {
        public function PNGEncoderTest()
        {
            super("PNGEncoderTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testPNGSignatureAndChunks"
            ];
        }

        public function testPNGSignatureAndChunks():void
        {
            // 2x2 solid red pixels (0xFFFF0000)
            var pixels:Array = [0xFFFF0000, 0xFFFF0000, 0xFFFF0000, 0xFFFF0000];
            var bytes:Array = PNGEncoder.encode(pixels, 2, 2);

            Assert.isTrue(bytes.length > 50);

            // Check standard 8-byte PNG signature
            var sig:Array = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
            for (var i:int = 0; i < 8; i++)
            {
                Assert.equals(sig[i], bytes[i]);
            }

            // Check for chunk headers in byte stream
            var rawStr:String = ByteArrayUtil.readUTF8(bytes, 0, bytes.length);
            Assert.isTrue(rawStr.indexOf("IHDR") != -1);
            Assert.isTrue(rawStr.indexOf("IDAT") != -1);
            Assert.isTrue(rawStr.indexOf("IEND") != -1);
        }
    }
}
