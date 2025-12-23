package test.geom
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.geom.Polygon2D;
    import stencil.geom.PolygonClipper;

    public class PolygonClipperTest extends TestCase
    {
        public function PolygonClipperTest()
        {
            super("PolygonClipperTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testIntersection",
                "testUnion",
                "testDifference",
                "testDisjoint"
            ];
        }

        public function testIntersection():void
        {
            // Square A: (0,0) to (100,100)
            var polyA:Polygon2D = new Polygon2D([
                new Point2D(0.0, 0.0),
                new Point2D(100.0, 0.0),
                new Point2D(100.0, 100.0),
                new Point2D(0.0, 100.0)
            ]);

            // Square B: (50,50) to (150,150)
            var polyB:Polygon2D = new Polygon2D([
                new Point2D(50.0, 50.0),
                new Point2D(150.0, 50.0),
                new Point2D(150.0, 150.0),
                new Point2D(50.0, 150.0)
            ]);

            var results:Array = PolygonClipper.intersect(polyA, polyB);
            Assert.isTrue(results.length >= 1);
            var inter:Polygon2D = results[0] as Polygon2D;
            // Overlap is (50,50) to (100,100), area should be 50 * 50 = 2500
            Assert.fuzzyEquals(2500.0, inter.area(), 10.0);
        }

        public function testUnion():void
        {
            var polyA:Polygon2D = new Polygon2D([
                new Point2D(0.0, 0.0),
                new Point2D(100.0, 0.0),
                new Point2D(100.0, 100.0),
                new Point2D(0.0, 100.0)
            ]);

            var polyB:Polygon2D = new Polygon2D([
                new Point2D(50.0, 50.0),
                new Point2D(150.0, 50.0),
                new Point2D(150.0, 150.0),
                new Point2D(50.0, 150.0)
            ]);

            var results:Array = PolygonClipper.union(polyA, polyB);
            Assert.isTrue(results.length >= 1);
            var un:Polygon2D = results[0] as Polygon2D;
            // Area = Area(A) + Area(B) - Area(A & B) = 10000 + 10000 - 2500 = 17500
            Assert.fuzzyEquals(17500.0, un.area(), 50.0);
        }

        public function testDifference():void
        {
            var polyA:Polygon2D = new Polygon2D([
                new Point2D(0.0, 0.0),
                new Point2D(100.0, 0.0),
                new Point2D(100.0, 100.0),
                new Point2D(0.0, 100.0)
            ]);

            var polyB:Polygon2D = new Polygon2D([
                new Point2D(50.0, 0.0),
                new Point2D(150.0, 0.0),
                new Point2D(150.0, 100.0),
                new Point2D(50.0, 100.0)
            ]);

            var results:Array = PolygonClipper.difference(polyA, polyB);
            Assert.isTrue(results.length >= 1);
            var diff:Polygon2D = results[0] as Polygon2D;
            // Remaining half: (0,0) to (50,100), area = 50 * 100 = 5000
            Assert.fuzzyEquals(5000.0, diff.area(), 20.0);
        }

        public function testDisjoint():void
        {
            var polyA:Polygon2D = new Polygon2D([
                new Point2D(0.0, 0.0),
                new Point2D(10.0, 0.0),
                new Point2D(10.0, 10.0),
                new Point2D(0.0, 10.0)
            ]);

            var polyB:Polygon2D = new Polygon2D([
                new Point2D(100.0, 100.0),
                new Point2D(110.0, 100.0),
                new Point2D(110.0, 110.0),
                new Point2D(100.0, 110.0)
            ]);

            var inter:Array = PolygonClipper.intersect(polyA, polyB);
            Assert.equals(0, inter.length);

            var un:Array = PolygonClipper.union(polyA, polyB);
            Assert.equals(2, un.length);
        }
    }
}
