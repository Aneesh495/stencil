package test.integration
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.format.JSONFormat;
    import stencil.format.PDFDocument;
    import stencil.format.PNGEncoder;
    import stencil.format.SVGSerializer;
    import stencil.geom.Rect2D;
    import stencil.raster.PixelBuffer;
    import stencil.raster.ScanlineRasterizer;
    import stencil.scene.GroupNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.ShapeNode;
    import stencil.scene.TextNode;

    /**
     * EndToEndDocumentTest executes the full document production pipeline:
     * Model creation -> Hierarchy transforms -> Multi-format exports (SVG, PDF, PNG).
     */
    public class EndToEndDocumentTest extends TestCase
    {
        public function EndToEndDocumentTest()
        {
            super("EndToEndDocumentTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testFullPipeline"
            ];
        }

        public function testFullPipeline():void
        {
            // 1. Construct SceneGraph
            var scene:SceneGraph = new SceneGraph("Brochure", 1200, 800);
            scene.backgroundColor = 0xFFF8FAFC;

            var headerGroup:GroupNode = new GroupNode("Header");
            headerGroup.x = 50.0;
            headerGroup.y = 40.0;

            var bgCard:ShapeNode = new ShapeNode("CardBg", "roundedRect");
            bgCard.shapeWidth = 1100.0;
            bgCard.shapeHeight = 120.0;
            bgCard.cornerRadius = 12.0;
            bgCard.fillColor = 0xFF2563EB;
            bgCard.rebuildGeometry();
            headerGroup.addChild(bgCard);

            var titleText:TextNode = new TextNode("Title", "Stencil Vector Engine");
            titleText.x = 30.0;
            titleText.y = 45.0;
            titleText.fontSize = 28.0;
            titleText.textColor = 0xFFFFFFFF;
            headerGroup.addChild(titleText);

            scene.addChild(headerGroup);

            // 2. Bounds Verification
            var sceneBounds:Rect2D = scene.localBounds();
            Assert.fuzzyEquals(50.0, sceneBounds.left);
            Assert.fuzzyEquals(1150.0, sceneBounds.right);

            // 3. SVG Export Validation
            var svg:String = SVGSerializer.serialize(scene);
            Assert.isTrue(svg.indexOf("<svg") != -1);
            Assert.isTrue(svg.indexOf("Stencil Vector Engine") != -1);
            Assert.isTrue(svg.indexOf("CardBg") != -1);

            // 4. PDF Compilation Validation
            var pdf:PDFDocument = new PDFDocument(1200, 800);
            pdf.renderScene(scene);
            var pdfBytes:Array = pdf.compile();
            Assert.isTrue(pdfBytes.length > 200);

            // 5. Software Rasterization & PNG Encoding
            var buffer:PixelBuffer = new PixelBuffer(300, 200);
            ScanlineRasterizer.renderScene(buffer, scene);
            var pngBytes:Array = PNGEncoder.encode(buffer.pixels, buffer.width, buffer.height);
            Assert.isTrue(pngBytes.length > 50);

            // 6. Lossless JSON Roundtrip
            var jsonDoc:Object = JSONFormat.exportDocument(scene);
            var reloadedScene:SceneGraph = JSONFormat.importDocument(jsonDoc);
            Assert.equals(1200.0, reloadedScene.viewportWidth);
            Assert.equals(1, reloadedScene.numChildren);
        }
    }
}
