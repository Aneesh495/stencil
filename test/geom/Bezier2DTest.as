package test.geom
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Bezier2D;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.geom.Vector2D;

    public class Bezier2DTest extends TestCase
    {
        public function Bezier2DTest()
        {
            super("Bezier2DTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testQuadraticEvaluation",
                "testCubicEvaluation",
                "testSubdivision",
                "testArcLength",
                "testFlattening",
                "testTightBounds"
            ];
        }

        public function testQuadraticEvaluation():void
        {
            var p0:Point2D = new Point2D(0.0, 0.0);
            var p1:Point2D = new Point2D(50.0, 100.0);
            var p2:Point2D = new Point2D(100.0, 0.0);
            var q:Bezier2D = Bezier2D.quadratic(p0, p1, p2);

            var start:Point2D = q.pointAt(0.0);
            Assert.fuzzyEquals(0.0, start.x);
            Assert.fuzzyEquals(0.0, start.y);

            var end:Point2D = q.pointAt(1.0);
            Assert.fuzzyEquals(100.0, end.x);
            Assert.fuzzyEquals(0.0, end.y);

            var mid:Point2D = q.pointAt(0.5);
            Assert.fuzzyEquals(50.0, mid.x);
            Assert.fuzzyEquals(50.0, mid.y);
        }

        public function testCubicEvaluation():void
        {
            var p0:Point2D = new Point2D(0.0, 0.0);
            var p1:Point2D = new Point2D(0.0, 100.0);
            var p2:Point2D = new Point2D(100.0, 100.0);
            var p3:Point2D = new Point2D(100.0, 0.0);
            var c:Bezier2D = Bezier2D.cubic(p0, p1, p2, p3);

            var mid:Point2D = c.pointAt(0.5);
            Assert.fuzzyEquals(50.0, mid.x);
            Assert.fuzzyEquals(75.0, mid.y);

            var tangent:Vector2D = c.tangent(0.5);
            Assert.fuzzyEquals(1.0, tangent.dx, 1e-4);
            Assert.fuzzyEquals(0.0, tangent.dy, 1e-4);
        }

        public function testSubdivision():void
        {
            var p0:Point2D = new Point2D(0.0, 0.0);
            var p1:Point2D = new Point2D(50.0, 100.0);
            var p2:Point2D = new Point2D(100.0, 0.0);
            var q:Bezier2D = Bezier2D.quadratic(p0, p1, p2);

            var split:Object = q.splitAt(0.5);
            var left:Bezier2D = split.left as Bezier2D;
            var right:Bezier2D = split.right as Bezier2D;

            Assert.fuzzyEquals(0.0, left.p0.x);
            Assert.fuzzyEquals(50.0, left.p2.x);
            Assert.fuzzyEquals(50.0, right.p0.x);
            Assert.fuzzyEquals(100.0, right.p2.x);

            // Left evaluated at t=1 must equal right evaluated at t=0
            var leftEnd:Point2D = left.pointAt(1.0);
            var rightStart:Point2D = right.pointAt(0.0);
            Assert.fuzzyEquals(leftEnd.x, rightStart.x);
            Assert.fuzzyEquals(leftEnd.y, rightStart.y);
        }

        public function testArcLength():void
        {
            // Straight line curve
            var p0:Point2D = new Point2D(0.0, 0.0);
            var p1:Point2D = new Point2D(50.0, 0.0);
            var p2:Point2D = new Point2D(100.0, 0.0);
            var lineBez:Bezier2D = Bezier2D.quadratic(p0, p1, p2);

            var len:Number = lineBez.arcLength();
            Assert.fuzzyEquals(100.0, len, 1e-3);
        }

        public function testFlattening():void
        {
            var p0:Point2D = new Point2D(0.0, 0.0);
            var p1:Point2D = new Point2D(50.0, 100.0);
            var p2:Point2D = new Point2D(100.0, 0.0);
            var q:Bezier2D = Bezier2D.quadratic(p0, p1, p2);

            var poly:Array = q.flatten(0.5);
            Assert.isTrue(poly.length >= 3);
            Assert.fuzzyEquals(0.0, (poly[0] as Point2D).x);
            Assert.fuzzyEquals(100.0, (poly[poly.length - 1] as Point2D).x);
        }

        public function testTightBounds():void
        {
            var p0:Point2D = new Point2D(0.0, 0.0);
            var p1:Point2D = new Point2D(50.0, 100.0);
            var p2:Point2D = new Point2D(100.0, 0.0);
            var q:Bezier2D = Bezier2D.quadratic(p0, p1, p2);

            var b:Rect2D = q.bounds();
            Assert.fuzzyEquals(0.0, b.left);
            Assert.fuzzyEquals(100.0, b.right);
            Assert.fuzzyEquals(0.0, b.top);
            // Peak at t=0.5 is y=50.0
            Assert.fuzzyEquals(50.0, b.bottom, 1e-3);
        }
    }
}
