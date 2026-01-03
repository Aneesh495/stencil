package test.format
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.format.JSONFormat;
    import stencil.scene.SceneGraph;
    import stencil.scene.ShapeNode;

    public class JSONFormatTest extends TestCase
    {
        public function JSONFormatTest()
        {
            super("JSONFormatTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testExportAndImportRoundtrip"
            ];
        }

        public function testExportAndImportRoundtrip():void
        {
            var origScene:SceneGraph = new SceneGraph("TestDoc", 1280, 720);
            var shape:ShapeNode = new ShapeNode("MyRect", "rect");
            shape.x = 42.0;
            shape.y = 84.0;
            shape.shapeWidth = 250.0;
            shape.shapeHeight = 150.0;
            origScene.addChild(shape);

            var exported:Object = JSONFormat.exportDocument(origScene);
            Assert.notNull(exported);
            Assert.equals(JSONFormat.SCHEMA_VERSION, exported.schemaVersion);

            var imported:SceneGraph = JSONFormat.importDocument(exported);
            Assert.equals(1280.0, imported.viewportWidth);
            Assert.equals(720.0, imported.viewportHeight);
            Assert.equals(1, imported.numChildren);

            var importedShape:ShapeNode = imported.getChildAt(0) as ShapeNode;
            Assert.notNull(importedShape);
            Assert.equals("MyRect", importedShape.name);
            Assert.fuzzyEquals(42.0, importedShape.x);
            Assert.fuzzyEquals(84.0, importedShape.y);
        }
    }
}
