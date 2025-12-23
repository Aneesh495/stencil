package test.geom
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.DelaunayTriangulation;
    import stencil.geom.Point2D;

    public class DelaunayTest extends TestCase
    {
        public function DelaunayTest()
        {
            super("DelaunayTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testSimpleQuad",
                "testRandomPoints"
            ];
        }

        public function testSimpleQuad():void
        {
            var pts:Array = [
                new Point2D(0.0, 0.0),
                new Point2D(100.0, 0.0),
                new Point2D(100.0, 100.0),
                new Point2D(0.0, 100.0)
            ];

            var triangles:Array = DelaunayTriangulation.triangulate(pts);
            // A convex quadrilateral must triangulate into exactly 2 triangles
            Assert.equals(2, triangles.length);
        }

        public function testRandomPoints():void
        {
            var pts:Array = [];
            for (var i:int = 0; i < 15; i++)
            {
                pts.push(new Point2D(Math.random() * 500, Math.random() * 500));
            }

            var triangles:Array = DelaunayTriangulation.triangulate(pts);
            Assert.isTrue(triangles.length > 0);

            // Verify each triangle has 3 valid non-null vertices
            for (var j:int = 0; j < triangles.length; j++)
            {
                var t:Object = triangles[j];
                Assert.notNull(t.a);
                Assert.notNull(t.b);
                Assert.notNull(t.c);
            }
        }
    }
}
