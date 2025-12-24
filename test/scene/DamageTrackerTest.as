package test.scene
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Rect2D;
    import stencil.scene.DamageTracker;

    public class DamageTrackerTest extends TestCase
    {
        public function DamageTrackerTest()
        {
            super("DamageTrackerTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testAddAndMerge",
                "testCoalesceThreshold",
                "testReset"
            ];
        }

        public function testAddAndMerge():void
        {
            var tracker:DamageTracker = new DamageTracker(4);
            Assert.isFalse(tracker.hasDamage);

            // Add first rect
            tracker.addDamage(new Rect2D(10.0, 10.0, 20.0, 20.0));
            Assert.equals(1, tracker.dirtyCount);

            // Add overlapping rect: should merge
            tracker.addDamage(new Rect2D(20.0, 20.0, 30.0, 30.0));
            Assert.equals(1, tracker.dirtyCount);

            var total:Rect2D = tracker.getTotalDamage();
            Assert.fuzzyEquals(10.0, total.left);
            Assert.fuzzyEquals(50.0, total.right);
            Assert.fuzzyEquals(10.0, total.top);
            Assert.fuzzyEquals(50.0, total.bottom);
        }

        public function testCoalesceThreshold():void
        {
            var tracker:DamageTracker = new DamageTracker(2);

            tracker.addDamage(new Rect2D(0.0, 0.0, 10.0, 10.0));
            tracker.addDamage(new Rect2D(100.0, 100.0, 10.0, 10.0));
            Assert.equals(2, tracker.dirtyCount);

            // Adding 3rd disjoint rect should trigger coalesce back down to 2
            tracker.addDamage(new Rect2D(10.0, 0.0, 10.0, 10.0));
            Assert.isTrue(tracker.dirtyCount <= 2);
        }

        public function testReset():void
        {
            var tracker:DamageTracker = new DamageTracker();
            tracker.addDamage(new Rect2D(5.0, 5.0, 20.0, 20.0));
            Assert.isTrue(tracker.hasDamage);

            tracker.reset();
            Assert.isFalse(tracker.hasDamage);
            Assert.equals(0, tracker.dirtyCount);
        }
    }
}
