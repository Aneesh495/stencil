package test.geom
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.core.MathUtil;

    public class Point2DTest extends TestCase
    {
        public function Point2DTest()
        {
            super("Point2DTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testArithmetic",
                "testDotAndCross",
                "testDistanceAndLength",
                "testRotationAroundPivot",
                "testLerpAndMidpoint"
            ];
        }

        public function testArithmetic():void
        {
            var p1:Point2D = new Point2D(10.0, 20.0);
            var p2:Point2D = new Point2D(5.0, 8.0);

            var sum:Point2D = p1.add(p2);
            Assert.fuzzyEquals(15.0, sum.x);
            Assert.fuzzyEquals(28.0, sum.y);

            var diff:Point2D = p1.subtract(p2);
            Assert.fuzzyEquals(5.0, diff.x);
            Assert.fuzzyEquals(12.0, diff.y);

            var scaled:Point2D = p1.multiply(2.5);
            Assert.fuzzyEquals(25.0, scaled.x);
            Assert.fuzzyEquals(50.0, scaled.y);

            var div:Point2D = scaled.divide(2.5);
            Assert.fuzzyEquals(10.0, div.x);
            Assert.fuzzyEquals(20.0, div.y);
        }

        public function testDotAndCross():void
        {
            var a:Point2D = new Point2D(1.0, 0.0);
            var b:Point2D = new Point2D(0.0, 1.0);

            Assert.fuzzyEquals(0.0, a.dot(b));
            Assert.fuzzyEquals(1.0, a.cross(b));

            var c:Point2D = new Point2D(3.0, 4.0);
            Assert.fuzzyEquals(25.0, c.dot(c));
        }

        public function testDistanceAndLength():void
        {
            var p:Point2D = new Point2D(3.0, 4.0);
            Assert.fuzzyEquals(5.0, p.length());
            Assert.fuzzyEquals(25.0, p.lengthSquared());

            var origin:Point2D = new Point2D(0.0, 0.0);
            Assert.fuzzyEquals(5.0, origin.distanceTo(p));

            var norm:Point2D = p.normalize();
            Assert.fuzzyEquals(1.0, norm.length());
            Assert.fuzzyEquals(0.6, norm.x);
            Assert.fuzzyEquals(0.8, norm.y);
        }

        public function testRotationAroundPivot():void
        {
            var pt:Point2D = new Point2D(10.0, 0.0);
            var pivot:Point2D = new Point2D(0.0, 0.0);

            // Rotate 90 degrees CCW
            var rotated:Point2D = pt.rotateAround(pivot, MathUtil.HALF_PI);
            Assert.fuzzyEquals(0.0, rotated.x, 1e-4);
            Assert.fuzzyEquals(10.0, rotated.y, 1e-4);

            // Rotate around arbitrary pivot (5, 5)
            var p2:Point2D = new Point2D(10.0, 5.0);
            var piv2:Point2D = new Point2D(5.0, 5.0);
            var rot2:Point2D = p2.rotateAround(piv2, MathUtil.PI);
            Assert.fuzzyEquals(0.0, rot2.x, 1e-4);
            Assert.fuzzyEquals(5.0, rot2.y, 1e-4);
        }

        public function testLerpAndMidpoint():void
        {
            var a:Point2D = new Point2D(0.0, 0.0);
            var b:Point2D = new Point2D(100.0, 200.0);

            var mid:Point2D = a.midpoint(b);
            Assert.fuzzyEquals(50.0, mid.x);
            Assert.fuzzyEquals(100.0, mid.y);

            var quarter:Point2D = a.lerp(b, 0.25);
            Assert.fuzzyEquals(25.0, quarter.x);
            Assert.fuzzyEquals(50.0, quarter.y);
        }
    }
}
