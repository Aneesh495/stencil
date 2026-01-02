package test.crdt
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.crdt.VectorClock;

    public class VectorClockTest extends TestCase
    {
        public function VectorClockTest()
        {
            super("VectorClockTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testTickAndGet",
                "testMerge",
                "testCausalOrdering"
            ];
        }

        public function testTickAndGet():void
        {
            var vc:VectorClock = new VectorClock();
            Assert.equals(0, vc.getCounter("peerA"));

            vc.tick("peerA");
            Assert.equals(1, vc.getCounter("peerA"));

            vc.tick("peerA");
            Assert.equals(2, vc.getCounter("peerA"));
        }

        public function testMerge():void
        {
            var vc1:VectorClock = new VectorClock();
            vc1.setCounter("A", 5);
            vc1.setCounter("B", 2);

            var vc2:VectorClock = new VectorClock();
            vc2.setCounter("A", 3);
            vc2.setCounter("B", 7);
            vc2.setCounter("C", 1);

            vc1.merge(vc2);
            Assert.equals(5, vc1.getCounter("A"));
            Assert.equals(7, vc1.getCounter("B"));
            Assert.equals(1, vc1.getCounter("C"));
        }

        public function testCausalOrdering():void
        {
            var vA:VectorClock = new VectorClock();
            var vB:VectorClock = new VectorClock();

            // Initially equal
            Assert.equals(VectorClock.ORDER_EQUAL, vA.compare(vB));

            // vA ticks -> vA is after vB
            vA.tick("peer1");
            Assert.equals(VectorClock.ORDER_AFTER, vA.compare(vB));
            Assert.equals(VectorClock.ORDER_BEFORE, vB.compare(vA));

            // vB ticks on different peer -> concurrent
            vB.tick("peer2");
            Assert.equals(VectorClock.ORDER_CONCURRENT, vA.compare(vB));
        }
    }
}
