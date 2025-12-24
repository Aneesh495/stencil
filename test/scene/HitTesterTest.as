package test.scene
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.scene.HitTester;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.scene.ShapeNode;

    public class HitTesterTest extends TestCase
    {
        public function HitTesterTest()
        {
            super("HitTesterTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testHitTestBasic",
                "testHitTestTopmostZOrder",
                "testHitTestStrokeProximity"
            ];
        }

        public function testHitTestBasic():void
        {
            var scene:SceneGraph = new SceneGraph("Root");
            var shape:ShapeNode = new ShapeNode("Target", "rect");
            shape.x = 50.0;
            shape.y = 50.0;
            shape.shapeWidth = 100.0;
            shape.shapeHeight = 100.0;
            shape.rebuildGeometry();
            scene.addChild(shape);

            // Hit inside shape
            var hit:SceneNode = HitTester.hitTest(scene, new Point2D(100.0, 100.0));
            Assert.equals(shape, hit);

            // Hit outside shape
            var miss:SceneNode = HitTester.hitTest(scene, new Point2D(200.0, 200.0));
            Assert.isNull(miss);
        }

        public function testHitTestTopmostZOrder():void
        {
            var scene:SceneGraph = new SceneGraph("Root");

            var bottomShape:ShapeNode = new ShapeNode("Bottom", "rect");
            bottomShape.x = 0.0;
            bottomShape.y = 0.0;
            bottomShape.shapeWidth = 100.0;
            bottomShape.shapeHeight = 100.0;
            bottomShape.rebuildGeometry();

            var topShape:ShapeNode = new ShapeNode("Top", "rect");
            topShape.x = 20.0;
            topShape.y = 20.0;
            topShape.shapeWidth = 100.0;
            topShape.shapeHeight = 100.0;
            topShape.rebuildGeometry();

            scene.addChild(bottomShape);
            scene.addChild(topShape);

            // Point (50, 50) is inside both shapes, topShape was added later so it is topmost
            var hit:SceneNode = HitTester.hitTest(scene, new Point2D(50.0, 50.0));
            Assert.equals(topShape, hit);
        }

        public function testHitTestStrokeProximity():void
        {
            var scene:SceneGraph = new SceneGraph("Root");
            var linePath:PathNode = new PathNode("Line");
            linePath.pathData.moveTo(0.0, 50.0).lineTo(100.0, 50.0);
            linePath.hasFill = false;
            linePath.hasStroke = true;
            linePath.strokeWidth = 4.0;
            scene.addChild(linePath);

            // Hit 2px above line: within stroke half-width + tolerance
            var hit:SceneNode = HitTester.hitTest(scene, new Point2D(50.0, 52.0), 3.0);
            Assert.equals(linePath, hit);

            // Hit 20px above line: too far
            var miss:SceneNode = HitTester.hitTest(scene, new Point2D(50.0, 80.0), 3.0);
            Assert.isNull(miss);
        }
    }
}
