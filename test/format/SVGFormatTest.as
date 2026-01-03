package test.format
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.format.SVGParser;
    import stencil.format.SVGSerializer;
    import stencil.geom.PathData;
    import stencil.scene.SceneGraph;
    import stencil.scene.ShapeNode;

    public class SVGFormatTest extends TestCase
    {
        public function SVGFormatTest()
        {
            super("SVGFormatTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testPathParsing",
                "testSceneSerialization"
            ];
        }

        public function testPathParsing():void
        {
            var d:String = "M 10 20 L 50 80 C 60 70 80 90 100 100 Z";
            var path:PathData = SVGParser.parsePathData(d);

            Assert.isTrue(path.segmentCount >= 4);
            Assert.fuzzyEquals(10.0, path.bounds().left);
            Assert.fuzzyEquals(100.0, path.bounds().right);
        }

        public function testSceneSerialization():void
        {
            var scene:SceneGraph = new SceneGraph("TestScene", 800, 600);
            var rect:ShapeNode = new ShapeNode("Box", "rect");
            rect.shapeWidth = 200;
            rect.shapeHeight = 100;
            rect.rebuildGeometry();
            scene.addChild(rect);

            var svgString:String = SVGSerializer.serialize(scene);
            Assert.isTrue(svgString.indexOf("<svg") != -1);
            Assert.isTrue(svgString.indexOf("width=\"800\"") != -1);
            Assert.isTrue(svgString.indexOf("<path id=\"") != -1);
            Assert.isTrue(svgString.indexOf("</svg>") != -1);
        }
    }
}
