package test.style
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.style.Color;
    import stencil.style.ConicGradientPaint;
    import stencil.style.LinearGradientPaint;

    public class GradientTest extends TestCase
    {
        public function GradientTest()
        {
            super("GradientTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testLinearGradientSampling",
                "testConicGradientSampling"
            ];
        }

        public function testLinearGradientSampling():void
        {
            var grad:LinearGradientPaint = new LinearGradientPaint(
                new Point2D(0.0, 0.0),
                new Point2D(100.0, 0.0)
            );
            grad.addStop(0.0, new Color(0xFF000000)); // Black
            grad.addStop(1.0, new Color(0xFFFFFFFF)); // White

            var startCol:Color = grad.sample(0.0, 0.0);
            Assert.fuzzyEquals(0.0, startCol.red);

            var endCol:Color = grad.sample(100.0, 0.0);
            Assert.fuzzyEquals(1.0, endCol.red);

            var midCol:Color = grad.sample(50.0, 0.0);
            Assert.fuzzyEquals(0.5, midCol.red, 0.02);
        }

        public function testConicGradientSampling():void
        {
            var conic:ConicGradientPaint = new ConicGradientPaint(new Point2D(50.0, 50.0));
            conic.addStop(0.0, new Color(0xFF000000));
            conic.addStop(1.0, new Color(0xFFFFFFFF));

            // Point right of center (angle 0)
            var c0:Color = conic.sample(100.0, 50.0);
            Assert.fuzzyEquals(0.0, c0.red, 0.05);

            // Point left of center (angle PI = 0.5 parameter)
            var cMid:Color = conic.sample(0.0, 50.0);
            Assert.fuzzyEquals(0.5, cMid.red, 0.05);
        }
    }
}
