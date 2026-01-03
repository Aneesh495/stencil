package test.format
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.core.ByteArrayUtil;
    import stencil.format.PDFDocument;
    import stencil.scene.SceneGraph;
    import stencil.scene.ShapeNode;

    public class PDFDocumentTest extends TestCase
    {
        public function PDFDocumentTest()
        {
            super("PDFDocumentTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testPDFCompilation",
                "testSceneToPDF"
            ];
        }

        public function testPDFCompilation():void
        {
            var pdf:PDFDocument = new PDFDocument(612, 792);
            pdf.saveGraphicsState();
            pdf.moveTo(50, 50);
            pdf.lineTo(150, 50);
            pdf.stroke();
            pdf.restoreGraphicsState();

            var bytes:Array = pdf.compile();
            Assert.isTrue(bytes.length > 100);

            var pdfStr:String = ByteArrayUtil.readUTF8(bytes, 0, bytes.length);
            Assert.isTrue(pdfStr.indexOf("%PDF-1.7") == 0);
            Assert.isTrue(pdfStr.indexOf("xref") != -1);
            Assert.isTrue(pdfStr.indexOf("trailer") != -1);
            Assert.isTrue(pdfStr.indexOf("%%EOF") != -1);
        }

        public function testSceneToPDF():void
        {
            var scene:SceneGraph = new SceneGraph("Root", 612, 792);
            var rect:ShapeNode = new ShapeNode("Box", "rect");
            scene.addChild(rect);

            var pdf:PDFDocument = new PDFDocument(612, 792);
            pdf.renderScene(scene);

            var bytes:Array = pdf.compile();
            Assert.isTrue(bytes.length > 100);
        }
    }
}
