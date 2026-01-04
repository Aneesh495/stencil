package test.raster
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.geom.Polygon2D;
    import stencil.raster.PixelBuffer;
    import stencil.raster.ScanlineRasterizer;

    public class ScanlineRasterizerTest extends TestCase
    {
        public function ScanlineRasterizerTest()
        {
            super("ScanlineRasterizerTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testTriangleRasterization"
            ];
        }

        public function testTriangleRasterization():void
        {
            var pb:PixelBuffer = new PixelBuffer(100, 100);

            // Triangle covering center: (50, 10), (90, 90), (10, 90)
            var tri:Polygon2D = new Polygon2D([
                new Point2D(50.0, 10.0),
                new Point2D(90.0, 90.0),
                new Point2D(10.0, 90.0)
            ]);

            ScanlineRasterizer.renderPolygon(pb, tri, 0xFFFF0000);

            // Centroid (50, 63) should be colored red
            var centerColor:uint = pb.getPixel(50, 63);
            Assert.equals(0xFFFF0000, centerColor);

            // Top-left corner (5, 5) outside triangle should be clear
            var cornerColor:uint = pb.getPixel(5, 5);
            Assert.equals(0x00000000, cornerColor);
        }
    }
}
