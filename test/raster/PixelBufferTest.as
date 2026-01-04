package test.raster
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Rect2D;
    import stencil.raster.PixelBuffer;

    public class PixelBufferTest extends TestCase
    {
        public function PixelBufferTest()
        {
            super("PixelBufferTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testAllocationAndClear",
                "testSetGetPixel",
                "testFillRect",
                "testBlending"
            ];
        }

        public function testAllocationAndClear():void
        {
            var pb:PixelBuffer = new PixelBuffer(10, 10);
            Assert.equals(10, pb.width);
            Assert.equals(10, pb.height);
            Assert.equals(0x00000000, pb.getPixel(0, 0));

            pb.clear(0xFFFFFFFF);
            Assert.equals(0xFFFFFFFF, pb.getPixel(5, 5));
        }

        public function testSetGetPixel():void
        {
            var pb:PixelBuffer = new PixelBuffer(20, 20);
            pb.setPixel(7, 9, 0xFF336699);
            Assert.equals(0xFF336699, pb.getPixel(7, 9));
            Assert.equals(0x00000000, pb.getPixel(0, 0));
        }

        public function testFillRect():void
        {
            var pb:PixelBuffer = new PixelBuffer(50, 50);
            pb.fillRect(new Rect2D(10, 10, 20, 20), 0xFFFF0000);

            Assert.equals(0xFFFF0000, pb.getPixel(15, 15));
            Assert.equals(0x00000000, pb.getPixel(5, 5));
            Assert.equals(0x00000000, pb.getPixel(35, 35));
        }

        public function testBlending():void
        {
            var pb:PixelBuffer = new PixelBuffer(10, 10);
            pb.clear(0xFF000000); // Black background

            // Blend 50% white over black
            pb.blendPixel(0, 0, 0xFFFFFFFF, 0.5);
            var result:uint = pb.getPixel(0, 0);

            // Channel values should be approximately 128
            var r:uint = (result >>> 16) & 0xFF;
            var g:uint = (result >>> 8) & 0xFF;
            var b:uint = result & 0xFF;

            Assert.isTrue(r >= 120 && r <= 135);
            Assert.isTrue(g >= 120 && g <= 135);
            Assert.isTrue(b >= 120 && b <= 135);
        }
    }
}
