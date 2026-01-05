package test.integration
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.crdt.CRDTree;
    import stencil.crdt.CRDTOperation;

    public class CollaborativeSyncIntegrationTest extends TestCase
    {
        public function CollaborativeSyncIntegrationTest()
        {
            super("CollaborativeSyncIntegrationTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testMultiPeerConvergence"
            ];
        }

        public function testMultiPeerConvergence():void
        {
            // Three peers collaborating simultaneously
            var peerA:CRDTree = new CRDTree("PeerA");
            var peerB:CRDTree = new CRDTree("PeerB");
            var peerC:CRDTree = new CRDTree("PeerC");

            // Peer A creates root group
            var op1:CRDTOperation = peerA.insert("group1", "root", "GroupNode");
            peerB.applyOperation(op1);
            peerC.applyOperation(op1);

            // Peer B creates a shape inside group1
            var op2:CRDTOperation = peerB.insert("shape1", "group1", "ShapeNode", { fill: 0xFF0000 });
            peerA.applyOperation(op2);
            peerC.applyOperation(op2);

            // Peer C updates shape color
            var op3:CRDTOperation = peerC.updateProperty("shape1", "fill", 0x00FF00);
            // Peer A concurrently updates shape width
            var op4:CRDTOperation = peerA.updateProperty("shape1", "width", 500);

            // Synchronize all pending ops
            peerA.applyOperation(op3);
            peerB.applyOperation(op3);
            peerB.applyOperation(op4);
            peerC.applyOperation(op4);

            // Verify all peers have identical nodes and property maps
            Assert.isTrue(peerA.hasNode("shape1"));
            Assert.isTrue(peerB.hasNode("shape1"));
            Assert.isTrue(peerC.hasNode("shape1"));

            Assert.equals(peerA.getNode("shape1").props.fill, peerB.getNode("shape1").props.fill);
            Assert.equals(peerB.getNode("shape1").props.fill, peerC.getNode("shape1").props.fill);

            Assert.equals(peerA.getNode("shape1").props.width, peerB.getNode("shape1").props.width);
            Assert.equals(peerB.getNode("shape1").props.width, peerC.getNode("shape1").props.width);
        }
    }
}
