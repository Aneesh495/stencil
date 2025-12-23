package test.geom
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.geom.SpatialBVH;

    public class SpatialBVHTest extends TestCase
    {
        public function SpatialBVHTest()
        {
            super("SpatialBVHTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testInsertAndQueryRect",
                "testQueryPoint",
                "testRemove"
            ];
        }

        public function testInsertAndQueryRect():void
        {
            var bvh:SpatialBVH = new SpatialBVH();

            var item1:Object = { name: "box1" };
            var item2:Object = { name: "box2" };
            var item3:Object = { name: "box3" };

            bvh.insert(item1, new Rect2D(0.0, 0.0, 50.0, 50.0));
            bvh.insert(item2, new Rect2D(100.0, 100.0, 50.0, 50.0));
            bvh.insert(item3, new Rect2D(500.0, 500.0, 50.0, 50.0));

            Assert.equals(3, bvh.count);

            // Query region covering box1 and box2
            var results:Array = bvh.queryRect(new Rect2D(0.0, 0.0, 200.0, 200.0));
            Assert.equals(2, results.length);
            Assert.isTrue(results.indexOf(item1) != -1);
            Assert.isTrue(results.indexOf(item2) != -1);
            Assert.isTrue(results.indexOf(item3) == -1);
        }

        public function testQueryPoint():void
        {
            var bvh:SpatialBVH = new SpatialBVH();
            var itemA:Object = { id: "A" };
            bvh.insert(itemA, new Rect2D(10.0, 10.0, 20.0, 20.0));

            var hits:Array = bvh.queryPoint(new Point2D(15.0, 15.0));
            Assert.equals(1, hits.length);
            Assert.equals(itemA, hits[0]);

            var misses:Array = bvh.queryPoint(new Point2D(50.0, 50.0));
            Assert.equals(0, misses.length);
        }

        public function testRemove():void
        {
            var bvh:SpatialBVH = new SpatialBVH();
            var item1:Object = { id: 1 };
            var item2:Object = { id: 2 };

            bvh.insert(item1, new Rect2D(0.0, 0.0, 10.0, 10.0));
            bvh.insert(item2, new Rect2D(20.0, 20.0, 10.0, 10.0));

            Assert.equals(2, bvh.count);
            bvh.remove(item1);
            Assert.equals(1, bvh.count);

            var q:Array = bvh.queryRect(new Rect2D(0.0, 0.0, 100.0, 100.0));
            Assert.equals(1, q.length);
            Assert.equals(item2, q[0]);
        }
    }
}
