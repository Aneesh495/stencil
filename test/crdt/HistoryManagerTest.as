package test.crdt
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.crdt.HistoryManager;

    public class HistoryManagerTest extends TestCase
    {
        public function HistoryManagerTest()
        {
            super("HistoryManagerTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testSingleActionUndoRedo",
                "testBatchedTransaction"
            ];
        }

        public function testSingleActionUndoRedo():void
        {
            var history:HistoryManager = new HistoryManager();
            var val:int = 10;

            history.record(
                function():void { val = 20; },
                function():void { val = 10; }
            );

            Assert.isTrue(history.canUndo);
            Assert.isFalse(history.canRedo);

            history.undo();
            Assert.equals(10, val);
            Assert.isFalse(history.canUndo);
            Assert.isTrue(history.canRedo);

            history.redo();
            Assert.equals(20, val);
            Assert.isTrue(history.canUndo);
            Assert.isFalse(history.canRedo);
        }

        public function testBatchedTransaction():void
        {
            var history:HistoryManager = new HistoryManager();
            var valA:int = 0;
            var valB:int = 0;

            history.beginTransaction();
            history.record(
                function():void { valA = 1; },
                function():void { valA = 0; }
            );
            history.record(
                function():void { valB = 2; },
                function():void { valB = 0; }
            );
            history.commitTransaction();

            // Batched transaction counts as 1 undoable entry
            Assert.equals(1, history.undoCount);

            history.undo();
            Assert.equals(0, valA);
            Assert.equals(0, valB);

            history.redo();
            Assert.equals(1, valA);
            Assert.equals(2, valB);
        }
    }
}
