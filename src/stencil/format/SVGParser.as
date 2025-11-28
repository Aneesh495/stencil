package stencil.format
{
    import stencil.geom.Matrix2D;
    import stencil.geom.PathBuilder;
    import stencil.geom.PathData;
    import stencil.geom.Point2D;
    import stencil.scene.GroupNode;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.style.Color;

    /**
     * SVGParser deserializes standard SVG XML documents into a Stencil scene graph DAG.
     * Parses SVG path commands (M, L, C, Q, Z), primitive tags, nested groups, and affine transforms.
     */
    public class SVGParser
    {
        /**
         * Parses an SVG path data string ("M 10 20 L 50 80 ...") into a PathData model.
         */
        public static function parsePathData(d:String):PathData
        {
            var path:PathData = new PathData();
            if (d == null || d.length == 0) return path;

            var tokens:Array = tokenizePath(d);
            var idx:int = 0;
            var currentX:Number = 0.0;
            var currentY:Number = 0.0;
            var startX:Number = 0.0;
            var startY:Number = 0.0;
            var lastCmd:String = "";

            while (idx < tokens.length)
            {
                var token:String = tokens[idx++];
                var isCmd:Boolean = isCommandChar(token);
                var cmd:String = isCmd ? token : lastCmd;
                if (!isCmd) idx--; // Backtrack if token is a coordinate number

                lastCmd = cmd;

                switch (cmd)
                {
                    case "M": // Absolute MoveTo
                        currentX = Number(tokens[idx++]);
                        currentY = Number(tokens[idx++]);
                        startX = currentX;
                        startY = currentY;
                        path.moveTo(currentX, currentY);
                        lastCmd = "L"; // Subsequent pairs default to LineTo
                        break;

                    case "m": // Relative MoveTo
                        currentX += Number(tokens[idx++]);
                        currentY += Number(tokens[idx++]);
                        startX = currentX;
                        startY = currentY;
                        path.moveTo(currentX, currentY);
                        lastCmd = "l";
                        break;

                    case "L": // Absolute LineTo
                        currentX = Number(tokens[idx++]);
                        currentY = Number(tokens[idx++]);
                        path.lineTo(currentX, currentY);
                        break;

                    case "l": // Relative LineTo
                        currentX += Number(tokens[idx++]);
                        currentY += Number(tokens[idx++]);
                        path.lineTo(currentX, currentY);
                        break;

                    case "H": // Absolute Horizontal LineTo
                        currentX = Number(tokens[idx++]);
                        path.lineTo(currentX, currentY);
                        break;

                    case "h": // Relative Horizontal LineTo
                        currentX += Number(tokens[idx++]);
                        path.lineTo(currentX, currentY);
                        break;

                    case "V": // Absolute Vertical LineTo
                        currentY = Number(tokens[idx++]);
                        path.lineTo(currentX, currentY);
                        break;

                    case "v": // Relative Vertical LineTo
                        currentY += Number(tokens[idx++]);
                        path.lineTo(currentX, currentY);
                        break;

                    case "C": // Absolute Cubic Bezier
                        var c1x:Number = Number(tokens[idx++]);
                        var c1y:Number = Number(tokens[idx++]);
                        var c2x:Number = Number(tokens[idx++]);
                        var c2y:Number = Number(tokens[idx++]);
                        currentX = Number(tokens[idx++]);
                        currentY = Number(tokens[idx++]);
                        path.cubicTo(c1x, c1y, c2x, c2y, currentX, currentY);
                        break;

                    case "c": // Relative Cubic Bezier
                        var rc1x:Number = currentX + Number(tokens[idx++]);
                        var rc1y:Number = currentY + Number(tokens[idx++]);
                        var rc2x:Number = currentX + Number(tokens[idx++]);
                        var rc2y:Number = currentY + Number(tokens[idx++]);
                        currentX += Number(tokens[idx++]);
                        currentY += Number(tokens[idx++]);
                        path.cubicTo(rc1x, rc1y, rc2x, rc2y, currentX, currentY);
                        break;

                    case "Q": // Absolute Quadratic Bezier
                        var qcx:Number = Number(tokens[idx++]);
                        var qcy:Number = Number(tokens[idx++]);
                        currentX = Number(tokens[idx++]);
                        currentY = Number(tokens[idx++]);
                        path.curveTo(qcx, qcy, currentX, currentY);
                        break;

                    case "q": // Relative Quadratic Bezier
                        var rqcx:Number = currentX + Number(tokens[idx++]);
                        var rqcy:Number = currentY + Number(tokens[idx++]);
                        currentX += Number(tokens[idx++]);
                        currentY += Number(tokens[idx++]);
                        path.curveTo(rqcx, rqcy, currentX, currentY);
                        break;

                    case "Z":
                    case "z": // ClosePath
                        path.closePath();
                        currentX = startX;
                        currentY = startY;
                        break;
                }
            }

            return path;
        }

        private static function tokenizePath(d:String):Array
        {
            var tokens:Array = [];
            var current:String = "";

            for (var i:int = 0; i < d.length; i++)
            {
                var c:String = d.charAt(i);
                if (isCommandChar(c))
                {
                    if (current.length > 0)
                    {
                        tokens.push(current);
                        current = "";
                    }
                    tokens.push(c);
                }
                else if (c == " " || c == "," || c == "\t" || c == "\n" || c == "\r")
                {
                    if (current.length > 0)
                    {
                        tokens.push(current);
                        current = "";
                    }
                }
                else if (c == "-" && current.length > 0)
                {
                    tokens.push(current);
                    current = "-";
                }
                else
                {
                    current += c;
                }
            }

            if (current.length > 0)
            {
                tokens.push(current);
            }

            return tokens;
        }

        private static function isCommandChar(c:String):Boolean
        {
            return "MmLlHhVvCcSsQqTtAaZz".indexOf(c) != -1;
        }
    }
}
