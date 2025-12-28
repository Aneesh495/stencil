package test.text
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.text.TextShaper;

    public class TextShaperTest extends TestCase
    {
        public function TextShaperTest()
        {
            super("TextShaperTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testEmptyShaping",
                "testPositioningAdvancement",
                "testKerningApplication"
            ];
        }

        public function testEmptyShaping():void
        {
            var shaper:TextShaper = new TextShaper();
            var res:Array = shaper.shape("");
            Assert.equals(0, res.length);
        }

        public function testPositioningAdvancement():void
        {
            var shaper:TextShaper = new TextShaper();
            var glyphs:Array = shaper.shape("Hello", 16.0);
            Assert.equals(5, glyphs.length);

            // Monotonically increasing X coordinates
            var lastX:Number = -1.0;
            for (var i:int = 0; i < glyphs.length; i++)
            {
                var g:Object = glyphs[i];
                Assert.isTrue(g.x > lastX);
                lastX = g.x;
            }
        }

        public function testKerningApplication():void
        {
            var shaper:TextShaper = new TextShaper();
            var unkernedKern:Number = shaper.getKerning("A", "A");
            var kernedVal:Number = shaper.getKerning("A", "V");

            Assert.fuzzyEquals(0.0, unkernedKern);
            Assert.isTrue(kernedVal < 0.0); // Negative kerning tightens "AV"
        }
    }
}
