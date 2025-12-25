package test.layout
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Rect2D;
    import stencil.layout.FlexLayoutEngine;

    public class FlexLayoutTest extends TestCase
    {
        public function FlexLayoutTest()
        {
            super("FlexLayoutTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testRowLayoutFixed",
                "testFlexGrowDistribution",
                "testJustifyContentCenter"
            ];
        }

        public function testRowLayoutFixed():void
        {
            var engine:FlexLayoutEngine = new FlexLayoutEngine();
            engine.direction = FlexLayoutEngine.DIR_ROW;
            engine.gap = 10.0;

            var items:Array = [
                { width: 100.0, height: 50.0 },
                { width: 150.0, height: 50.0 }
            ];

            var frames:Array = engine.layout(500.0, 200.0, items);
            Assert.equals(2, frames.length);

            var f0:Rect2D = frames[0] as Rect2D;
            var f1:Rect2D = frames[1] as Rect2D;

            Assert.fuzzyEquals(0.0, f0.x);
            Assert.fuzzyEquals(100.0, f0.width);

            Assert.fuzzyEquals(110.0, f1.x); // 100 + 10 gap
            Assert.fuzzyEquals(150.0, f1.width);
        }

        public function testFlexGrowDistribution():void
        {
            var engine:FlexLayoutEngine = new FlexLayoutEngine();
            engine.direction = FlexLayoutEngine.DIR_ROW;
            engine.gap = 0.0;

            // Container width = 400. Total base = 100 + 100 = 200. Free space = 200.
            // Both items have flexGrow = 1.0 -> each gets +100
            var items:Array = [
                { width: 100.0, height: 50.0, flexGrow: 1.0 },
                { width: 100.0, height: 50.0, flexGrow: 1.0 }
            ];

            var frames:Array = engine.layout(400.0, 100.0, items);
            var f0:Rect2D = frames[0] as Rect2D;
            var f1:Rect2D = frames[1] as Rect2D;

            Assert.fuzzyEquals(200.0, f0.width);
            Assert.fuzzyEquals(200.0, f1.width);
        }

        public function testJustifyContentCenter():void
        {
            var engine:FlexLayoutEngine = new FlexLayoutEngine();
            engine.direction = FlexLayoutEngine.DIR_ROW;
            engine.justifyContent = FlexLayoutEngine.JUSTIFY_CENTER;

            // Container 500, item 100 -> remaining 400 -> offset 200
            var items:Array = [{ width: 100.0, height: 50.0 }];
            var frames:Array = engine.layout(500.0, 100.0, items);

            var f0:Rect2D = frames[0] as Rect2D;
            Assert.fuzzyEquals(200.0, f0.x);
        }
    }
}
