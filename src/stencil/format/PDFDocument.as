package stencil.format
{
    import stencil.core.ByteArrayUtil;
    import stencil.geom.Bezier2D;
    import stencil.geom.Matrix2D;
    import stencil.geom.PathCommand;
    import stencil.geom.PathData;
    import stencil.geom.PathSegment;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.scene.TextNode;
    import stencil.style.Color;

    /**
     * Binary PDF 1.7 document composer written in pure ActionScript 3.
     * Generates valid PDF object structures, xref offsets, vector content streams, and trailers.
     */
    public class PDFDocument
    {
        public var pageWidth:Number;
        public var pageHeight:Number;

        protected var _objects:Array; // Array of String content
        protected var _pageContent:Array; // Array of PDF operator strings

        public function PDFDocument(pageWidth:Number = 612.0, pageHeight:Number = 792.0) // US Letter default
        {
            this.pageWidth = pageWidth;
            this.pageHeight = pageHeight;
            _objects = [];
            _pageContent = [];
        }

        public function appendOp(op:String):void
        {
            _pageContent.push(op);
        }

        public function saveGraphicsState():void { appendOp("q"); }
        public function restoreGraphicsState():void { appendOp("Q"); }

        public function setMatrix(a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number):void
        {
            appendOp(a + " " + b + " " + c + " " + d + " " + tx + " " + ty + " cm");
        }

        public function setStrokeColorRGB(r:Number, g:Number, b:Number):void
        {
            appendOp(r + " " + g + " " + b + " RG");
        }

        public function setFillColorRGB(r:Number, g:Number, b:Number):void
        {
            appendOp(r + " " + g + " " + b + " rg");
        }

        public function setLineWidth(width:Number):void
        {
            appendOp(width + " w");
        }

        public function moveTo(x:Number, y:Number):void
        {
            appendOp(x + " " + y + " m");
        }

        public function lineTo(x:Number, y:Number):void
        {
            appendOp(x + " " + y + " l");
        }

        public function curveTo(c1x:Number, c1y:Number, c2x:Number, c2y:Number, x:Number, y:Number):void
        {
            appendOp(c1x + " " + c1y + " " + c2x + " " + c2y + " " + x + " " + y + " c");
        }

        public function closePath():void
        {
            appendOp("h");
        }

        public function fill(evenOdd:Boolean = false):void
        {
            appendOp(evenOdd ? "f*" : "f");
        }

        public function stroke():void
        {
            appendOp("S");
        }

        public function fillAndStroke(evenOdd:Boolean = false):void
        {
            appendOp(evenOdd ? "B*" : "B");
        }

        /**
         * Renders a Stencil SceneGraph into this PDF document.
         */
        public function renderScene(root:SceneGraph):void
        {
            if (root == null) return;

            // Invert PDF Y-axis (PDF origin is bottom-left, screen is top-left)
            saveGraphicsState();
            setMatrix(1.0, 0.0, 0.0, -1.0, 0.0, pageHeight);

            // Background
            if (root.backgroundColor != 0x00000000)
            {
                var bgCol:Color = new Color(root.backgroundColor);
                setFillColorRGB(bgCol.red, bgCol.green, bgCol.blue);
                appendOp("0 0 " + pageWidth + " " + pageHeight + " re");
                fill();
            }

            for (var i:int = 0; i < root.numChildren; i++)
            {
                renderNode(root.getChildAt(i));
            }

            restoreGraphicsState();
        }

        protected function renderNode(node:SceneNode):void
        {
            if (!node.visible || node.opacity <= 0.0) return;

            saveGraphicsState();

            var m:Matrix2D = node.transform.localMatrix;
            setMatrix(m.a, m.b, m.c, m.d, m.tx, m.ty);

            if (node is PathNode)
            {
                var pn:PathNode = node as PathNode;
                if (pn.pathData != null)
                {
                    emitPath(pn.pathData);

                    var hasF:Boolean = pn.hasFill;
                    var hasS:Boolean = pn.hasStroke && pn.strokeWidth > 0;

                    if (hasF)
                    {
                        var fc:Color = new Color(pn.fillColor);
                        setFillColorRGB(fc.red, fc.green, fc.blue);
                    }
                    if (hasS)
                    {
                        var sc:Color = new Color(pn.strokeColor);
                        setStrokeColorRGB(sc.red, sc.green, sc.blue);
                        setLineWidth(pn.strokeWidth);
                    }

                    if (hasF && hasS) fillAndStroke();
                    else if (hasF) fill();
                    else if (hasS) stroke();
                    else appendOp("n"); // Clear path
                }
            }
            else if (node is TextNode)
            {
                var tn:TextNode = node as TextNode;
                var tc:Color = new Color(tn.textColor);
                setFillColorRGB(tc.red, tc.green, tc.blue);

                appendOp("BT");
                appendOp("/F1 " + tn.fontSize + " Tf");
                appendOp("1 0 0 -1 0 " + tn.fontSize + " Tm"); // Flip text upright
                appendOp("(" + escapePDFString(tn.text) + ") Tj");
                appendOp("ET");
            }

            for (var j:int = 0; j < node.numChildren; j++)
            {
                renderNode(node.getChildAt(j));
            }

            restoreGraphicsState();
        }

        protected function emitPath(path:PathData):void
        {
            var segs:Array = path.segments;
            for (var i:int = 0; i < segs.length; i++)
            {
                var seg:PathSegment = segs[i] as PathSegment;
                switch (seg.command)
                {
                    case PathCommand.MOVE_TO:
                        moveTo(seg.points[0].x, seg.points[0].y);
                        break;
                    case PathCommand.LINE_TO:
                        lineTo(seg.points[0].x, seg.points[0].y);
                        break;
                    case PathCommand.CURVE_TO:
                        // Convert quadratic to cubic approximation for PDF
                        var cBez:Object = Bezier2D.quadratic(
                            new Point2D(0, 0), seg.points[0], seg.points[1]
                        ).toCubic();
                        curveTo(cBez.p1.x, cBez.p1.y, cBez.p2.x, cBez.p2.y, seg.points[1].x, seg.points[1].y);
                        break;
                    case PathCommand.CUBIC_TO:
                        curveTo(seg.points[0].x, seg.points[0].y, seg.points[1].x, seg.points[1].y, seg.points[2].x, seg.points[2].y);
                        break;
                    case PathCommand.CLOSE:
                        closePath();
                        break;
                }
            }
        }

        protected function escapePDFString(str:String):String
        {
            if (str == null) return "";
            return str.replace(/\\/g, "\\\\")
                      .replace(/\(/g, "\\(")
                      .replace(/\)/g, "\\)");
        }

        /**
         * Compiles the complete binary PDF document bytes.
         */
        public function compile():Array
        {
            var streamContent:String = _pageContent.join("\n");
            var streamLen:int = streamContent.length;

            var obj1Catalog:String = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n";
            var obj2Pages:String = "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n";
            var obj3Page:String = "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 " + pageWidth + " " + pageHeight + "] " +
                                  "/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n";
            var obj4Stream:String = "4 0 obj\n<< /Length " + streamLen + " >>\nstream\n" + streamContent + "\nendstream\nendobj\n";
            var obj5Font:String = "5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n";

            var objects:Array = [obj1Catalog, obj2Pages, obj3Page, obj4Stream, obj5Font];

            var header:String = "%PDF-1.7\n%\xE2\xE3\xCF\xD3\n";
            var out:String = header;

            var offsets:Array = [];
            offsets.push(0); // Dummy entry for 0000000000 65535 f

            for (var i:int = 0; i < objects.length; i++)
            {
                offsets.push(out.length);
                out += objects[i];
            }

            var startXref:int = out.length;
            out += "xref\n";
            out += "0 " + (objects.length + 1) + "\n";
            out += "0000000000 65535 f \n";

            for (var j:int = 1; j <= objects.length; j++)
            {
                var offStr:String = offsets[j].toString();
                while (offStr.length < 10) offStr = "0" + offStr;
                out += offStr + " 00000 n \n";
            }

            out += "trailer\n";
            out += "<< /Size " + (objects.length + 1) + " /Root 1 0 R >>\n";
            out += "startxref\n" + startXref + "\n%%EOF\n";

            var bytes:Array = [];
            ByteArrayUtil.writeUTF8(bytes, out);
            return bytes;
        }
    }
}
