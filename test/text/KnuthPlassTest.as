package test.text
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.text.KnuthPlassLineBreaker;

    public class KnuthPlassTest extends TestCase
    {
        public function KnuthPlassTest()
        {
            super("KnuthPlassTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testSingleLineParagraph",
                "testMultiLineBreak"
            ];
        }

        public function testSingleLineParagraph():void
        {
            var nodes:Array = [
                KnuthPlassLineBreaker.makeBox(50, "Hello"),
                KnuthPlassLineBreaker.makeGlue(10, 5, 3),
                KnuthPlassLineBreaker.makeBox(50, "World")
            ];

            // Line width 200: fits comfortably on 1 line
            var breaks:Array = KnuthPlassLineBreaker.breakParagraph(nodes, 200.0);
            Assert.equals(1, breaks.length);
            Assert.equals(3, breaks[0]); // Ends at last node
        }

        public function testMultiLineBreak():void
        {
            // 4 words of width 40 each, separated by glue of 10
            // Total = 40 + 10 + 40 + 10 + 40 + 10 + 40 = 190
            // Line width = 100: can hold 2 words per line (40 + 10 + 40 = 90)
            var nodes:Array = [
                KnuthPlassLineBreaker.makeBox(40, "One"),
                KnuthPlassLineBreaker.makeGlue(10, 5, 2),
                KnuthPlassLineBreaker.makeBox(40, "Two"),
                KnuthPlassLineBreaker.makeGlue(10, 5, 2),
                KnuthPlassLineBreaker.makeBox(40, "Three"),
                KnuthPlassLineBreaker.makeGlue(10, 5, 2),
                KnuthPlassLineBreaker.makeBox(40, "Four")
            ];

            var breaks:Array = KnuthPlassLineBreaker.breakParagraph(nodes, 100.0);
            Assert.isTrue(breaks.length >= 2);
        }
    }
}
