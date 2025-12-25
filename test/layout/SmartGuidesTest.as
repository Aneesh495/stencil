package test.layout
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Rect2D;
    import stencil.layout.SmartGuides;

    public class SmartGuidesTest extends TestCase
    {
        public function SmartGuidesTest()
        {
            super("SmartGuidesTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testEdgeSnapping",
                "testNoSnapBeyondThreshold"
            ];
        }

        public function testEdgeSnapping():void
        {
            // Target box at (100, 100), size (50, 50)
            var target:Rect2D = new Rect2D(100.0, 100.0, 50.0, 50.0);

            // Dragged box at (103, 300) -> 3px off target left edge (100.0)
            var dragged:Rect2D = new Rect2D(103.0, 300.0, 50.0, 50.0);

            var snapRes:Object = SmartGuides.snap(dragged, [target], 5.0);
            Assert.fuzzyEquals(-3.0, snapRes.dx);
            Assert.isTrue((snapRes.guidelines as Array).length > 0);
        }

        public function testNoSnapBeyondThreshold():void
        {
            var target:Rect2D = new Rect2D(100.0, 100.0, 50.0, 50.0);
            var dragged:Rect2D = new Rect2D(120.0, 300.0, 50.0, 50.0); // 20px off

            var snapRes:Object = SmartGuides.snap(dragged, [target], 5.0);
            Assert.fuzzyEquals(0.0, snapRes.dx);
        }
    }
}
