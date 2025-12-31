package test.style
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.geom.Polygon2D;
    import stencil.style.StrokeExpander;

    public class StrokeExpanderTest extends TestCase
    {
        public function StrokeExpanderTest()
        {
            super("StrokeExpanderTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testHorizontalSegmentExpansion"
            ];
        }

        public function testHorizontalSegmentExpansion():void
        {
            // Segment of length 100 from (0, 0) to (100, 0), strokeWidth = 10
            var pts:Array = [new Point2D(0.0, 0.0), new Point2D(100.0, 0.0)];
            var poly:Polygon2D = StrokeExpander.expandPolyline(pts, 10.0);

            Assert.isTrue(poly.vertexCount >= 4);
            // Area should be approximately 100 * 10 = 1000
            Assert.fuzzyEquals(1000.0, poly.area(), 10.0);
        }
    }
}
