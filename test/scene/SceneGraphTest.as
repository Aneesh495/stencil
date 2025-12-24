package test.scene
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.scene.GroupNode;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.scene.ShapeNode;

    public class SceneGraphTest extends TestCase
    {
        public function SceneGraphTest()
        {
            super("SceneGraphTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testHierarchyAndTransforms",
                "testBoundsCalculation",
                "testTraversals",
                "testZOrdering"
            ];
        }

        public function testHierarchyAndTransforms():void
        {
            var scene:SceneGraph = new SceneGraph("Root", 800, 600);
            var parentNode:GroupNode = new GroupNode("Parent");
            parentNode.x = 100.0;
            parentNode.y = 50.0;

            var childNode:ShapeNode = new ShapeNode("Child", "rect");
            childNode.x = 20.0;
            childNode.y = 30.0;

            parentNode.addChild(childNode);
            scene.addChild(parentNode);

            Assert.equals(scene, parentNode.parent);
            Assert.equals(parentNode, childNode.parent);

            var childWorldPos:Point2D = childNode.localToWorld(new Point2D(0.0, 0.0));
            Assert.fuzzyEquals(120.0, childWorldPos.x);
            Assert.fuzzyEquals(80.0, childWorldPos.y);

            var localFromWorld:Point2D = childNode.worldToLocal(childWorldPos);
            Assert.fuzzyEquals(0.0, localFromWorld.x);
            Assert.fuzzyEquals(0.0, localFromWorld.y);
        }

        public function testBoundsCalculation():void
        {
            var scene:SceneGraph = new SceneGraph("Root");
            var shape1:ShapeNode = new ShapeNode("S1", "rect");
            shape1.x = 10.0;
            shape1.y = 10.0;
            shape1.shapeWidth = 50.0;
            shape1.shapeHeight = 50.0;
            shape1.rebuildGeometry();

            var shape2:ShapeNode = new ShapeNode("S2", "rect");
            shape2.x = 100.0;
            shape2.y = 100.0;
            shape2.shapeWidth = 40.0;
            shape2.shapeHeight = 40.0;
            shape2.rebuildGeometry();

            scene.addChild(shape1);
            scene.addChild(shape2);

            var bounds:Rect2D = scene.localBounds();
            Assert.fuzzyEquals(10.0, bounds.left);
            Assert.fuzzyEquals(140.0, bounds.right);
            Assert.fuzzyEquals(10.0, bounds.top);
            Assert.fuzzyEquals(140.0, bounds.bottom);
        }

        public function testTraversals():void
        {
            var scene:SceneGraph = new SceneGraph("Root");
            var g1:GroupNode = new GroupNode("G1");
            var g2:GroupNode = new GroupNode("G2");
            var s1:ShapeNode = new ShapeNode("S1");

            scene.addChild(g1);
            g1.addChild(s1);
            scene.addChild(g2);

            var preOrderNames:Array = [];
            scene.traversePreOrder(function(n:SceneNode):void {
                preOrderNames.push(n.name);
            });

            Assert.equals("Root", preOrderNames[0]);
            Assert.equals("G1", preOrderNames[1]);
            Assert.equals("S1", preOrderNames[2]);
            Assert.equals("G2", preOrderNames[3]);
        }

        public function testZOrdering():void
        {
            var g:GroupNode = new GroupNode("Parent");
            var c1:SceneNode = new SceneNode("C1");
            var c2:SceneNode = new SceneNode("C2");
            var c3:SceneNode = new SceneNode("C3");

            c1.zIndex = 10;
            c2.zIndex = -5;
            c3.zIndex = 2;

            g.addChild(c1);
            g.addChild(c2);
            g.addChild(c3);

            g.sortChildrenByZIndex();

            Assert.equals(c2, g.getChildAt(0)); // -5
            Assert.equals(c3, g.getChildAt(1)); // 2
            Assert.equals(c1, g.getChildAt(2)); // 10
        }
    }
}
