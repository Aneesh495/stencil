package test.crdt
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.crdt.CRDTree;
    import stencil.crdt.CRDTOperation;

    public class CRDTreeTest extends TestCase
    {
        public function CRDTreeTest()
        {
            super("CRDTreeTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testInsertAndHierarchy",
                "testCyclePrevention",
                "testLWWPropertyResolution",
                "testTombstoneDeletion"
            ];
        }

        public function testInsertAndHierarchy():void
        {
            var tree:CRDTree = new CRDTree("peer1");
            tree.insert("nodeA", "root", "GroupNode");
            tree.insert("nodeB", "nodeA", "ShapeNode");

            Assert.isTrue(tree.hasNode("nodeA"));
            Assert.isTrue(tree.hasNode("nodeB"));

            var childrenOfA:Array = tree.getChildren("nodeA");
            Assert.equals(1, childrenOfA.length);
            Assert.equals("nodeB", childrenOfA[0].id);
        }

        public function testCyclePrevention():void
        {
            var tree:CRDTree = new CRDTree("peer1");
            tree.insert("nodeA", "root", "GroupNode");
            tree.insert("nodeB", "nodeA", "GroupNode");
            tree.insert("nodeC", "nodeB", "ShapeNode");

            // Attempting to move nodeA under nodeC should create cycle A -> B -> C -> A
            // It MUST be rejected!
            var op:CRDTOperation = tree.move("nodeA", "nodeC");
            Assert.isFalse(tree.applyOperation(op));

            // nodeA must still have parent "root"
            Assert.equals("root", tree.getNode("nodeA").parentId);
        }

        public function testLWWPropertyResolution():void
        {
            var treeA:CRDTree = new CRDTree("A");
            var treeB:CRDTree = new CRDTree("B");

            var op1:CRDTOperation = treeA.insert("box1", "root", "ShapeNode", { width: 100 });
            treeB.applyOperation(op1);

            // Peer A updates width to 200
            var opA:CRDTOperation = treeA.updateProperty("box1", "width", 200);

            // Peer B updates width to 300 concurrently
            var opB:CRDTOperation = treeB.updateProperty("box1", "width", 300);

            // Cross-replicate
            treeA.applyOperation(opB);
            treeB.applyOperation(opA);

            // Both replicas MUST converge to identical state
            Assert.equals(treeA.getNode("box1").props.width, treeB.getNode("box1").props.width);
        }

        public function testTombstoneDeletion():void
        {
            var tree:CRDTree = new CRDTree("peer1");
            tree.insert("n1", "root", "PathNode");
            Assert.isTrue(tree.hasNode("n1"));

            tree.remove("n1");
            Assert.isFalse(tree.hasNode("n1"));
        }
    }
}
