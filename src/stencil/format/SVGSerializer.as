package stencil.format
{
    import stencil.geom.Matrix2D;
    import stencil.scene.ClipNode;
    import stencil.scene.GroupNode;
    import stencil.scene.ImageNode;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.scene.ShapeNode;
    import stencil.scene.TextNode;
    import stencil.style.Color;

    /**
     * SVGSerializer transforms Stencil scene graphs into high-fidelity W3C-compliant SVG XML documents.
     */
    public class SVGSerializer
    {
        public static function serialize(root:SceneGraph):String
        {
            if (root == null) return "<svg xmlns=\"http://www.w3.org/2000/svg\"/>";

            var w:Number = root.viewportWidth;
            var h:Number = root.viewportHeight;

            var xml:Array = [];
            xml.push("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
            xml.push("<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" " +
                     "width=\"" + w + "\" height=\"" + h + "\" viewBox=\"0 0 " + w + " " + h + "\">");

            // Background rect
            if (root.backgroundColor != 0x00000000)
            {
                var bgCol:Color = new Color(root.backgroundColor);
                xml.push("  <rect width=\"100%\" height=\"100%\" fill=\"" + bgCol.toHexString() + "\"/>");
            }

            // Serialize children
            for (var i:int = 0; i < root.numChildren; i++)
            {
                serializeNode(root.getChildAt(i), xml, "  ");
            }

            xml.push("</svg>");
            return xml.join("\n");
        }

        private static function serializeNode(node:SceneNode, xml:Array, indent:String):void
        {
            if (!node.visible || node.opacity <= 0.0) return;

            var transformAttr:String = "";
            var m:Matrix2D = node.transform.localMatrix;
            if (m.a != 1.0 || m.b != 0.0 || m.c != 0.0 || m.d != 1.0 || m.tx != 0.0 || m.ty != 0.0)
            {
                transformAttr = " transform=\"matrix(" + m.a + " " + m.b + " " + m.c + " " + m.d + " " + m.tx + " " + m.ty + ")\"";
            }

            var opacityAttr:String = (node.opacity < 1.0) ? (" opacity=\"" + node.opacity + "\"") : "";

            if (node is PathNode)
            {
                var pn:PathNode = node as PathNode;
                var dStr:String = pn.pathData ? pn.pathData.toSVGPathString() : "";

                var fillStr:String = pn.hasFill ? new Color(pn.fillColor).toHexString() : "none";
                var strokeStr:String = pn.hasStroke ? new Color(pn.strokeColor).toHexString() : "none";
                var strokeWStr:String = pn.hasStroke ? (" stroke-width=\"" + pn.strokeWidth + "\"") : "";
                var strokeCapStr:String = pn.hasStroke ? (" stroke-linecap=\"" + pn.strokeCap + "\"") : "";
                var strokeJoinStr:String = pn.hasStroke ? (" stroke-linejoin=\"" + pn.strokeJoin + "\"") : "";

                xml.push(indent + "<path id=\"" + pn.id + "\" d=\"" + dStr + "\" fill=\"" + fillStr + "\" " +
                         "stroke=\"" + strokeStr + "\"" + strokeWStr + strokeCapStr + strokeJoinStr +
                         transformAttr + opacityAttr + "/>");
            }
            else if (node is TextNode)
            {
                var tn:TextNode = node as TextNode;
                var textCol:Color = new Color(tn.textColor);

                xml.push(indent + "<text id=\"" + tn.id + "\" font-family=\"" + escapeXML(tn.fontFamily) + "\" " +
                         "font-size=\"" + tn.fontSize + "\" fill=\"" + textCol.toHexString() + "\"" +
                         transformAttr + opacityAttr + ">" + escapeXML(tn.text) + "</text>");
            }
            else if (node is ImageNode)
            {
                var img:ImageNode = node as ImageNode;
                xml.push(indent + "<image id=\"" + img.id + "\" href=\"" + escapeXML(img.source) + "\" " +
                         "width=\"" + img.imageWidth + "\" height=\"" + img.imageHeight + "\"" +
                         transformAttr + opacityAttr + "/>");
            }
            else if (node is GroupNode || node.numChildren > 0)
            {
                xml.push(indent + "<g id=\"" + node.id + "\"" + transformAttr + opacityAttr + ">");
                for (var j:int = 0; j < node.numChildren; j++)
                {
                    serializeNode(node.getChildAt(j), xml, indent + "  ");
                }
                xml.push(indent + "</g>");
            }
        }

        private static function escapeXML(str:String):String
        {
            if (str == null) return "";
            return str.replace(/&/g, "&amp;")
                      .replace(/</g, "&lt;")
                      .replace(/>/g, "&gt;")
                      .replace(/"/g, "&quot;")
                      .replace(/'/g, "&apos;");
        }
    }
}
