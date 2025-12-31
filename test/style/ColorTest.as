package test.style
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.style.Color;

    public class ColorTest extends TestCase
    {
        public function ColorTest()
        {
            super("ColorTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testHexParsing",
                "testLuminanceAndContrast",
                "testLerp"
            ];
        }

        public function testHexParsing():void
        {
            var red:Color = Color.fromHex("#FF0000");
            Assert.fuzzyEquals(1.0, red.red);
            Assert.fuzzyEquals(0.0, red.green);
            Assert.fuzzyEquals(0.0, red.blue);
            Assert.fuzzyEquals(1.0, red.alpha);

            var shortHex:Color = Color.fromHex("#0F0");
            Assert.fuzzyEquals(0.0, shortHex.red);
            Assert.fuzzyEquals(1.0, shortHex.green);
            Assert.fuzzyEquals(0.0, shortHex.blue);

            var argbHex:Color = Color.fromHex("#800000FF");
            Assert.fuzzyEquals(0.5, argbHex.alpha, 0.01);
            Assert.fuzzyEquals(1.0, argbHex.blue);
        }

        public function testLuminanceAndContrast():void
        {
            var white:Color = new Color(0xFFFFFFFF);
            var black:Color = new Color(0xFF000000);

            Assert.fuzzyEquals(1.0, white.relativeLuminance(), 1e-3);
            Assert.fuzzyEquals(0.0, black.relativeLuminance(), 1e-3);

            // Black vs White contrast ratio is exactly 21.0
            var ratio:Number = white.contrastRatio(black);
            Assert.fuzzyEquals(21.0, ratio, 0.1);
        }

        public function testLerp():void
        {
            var black:Color = new Color(0xFF000000);
            var white:Color = new Color(0xFFFFFFFF);

            var gray:Color = black.lerp(white, 0.5);
            Assert.fuzzyEquals(0.5, gray.red, 0.01);
            Assert.fuzzyEquals(0.5, gray.green, 0.01);
            Assert.fuzzyEquals(0.5, gray.blue, 0.01);
        }
    }
}
