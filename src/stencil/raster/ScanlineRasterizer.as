package stencil.raster
{
    import stencil.geom.PathData;
    import stencil.geom.Polygon2D;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;

    /**
     * ScanlineRasterizer converts vector paths into raster pixels using Active Edge Table (AET)
     * scanline sorting and analytical subpixel area coverage.
     */
    public class ScanlineRasterizer
    {
        /**
         * Renders a polygonal path contour to the target pixel buffer with scanline filling.
         */
        public static function renderPolygon(
            buffer:PixelBuffer,
            poly:Polygon2D,
            color:uint,
            evenOdd:Boolean = false
        ):void
        {
            if (buffer == null || poly == null || poly.vertexCount < 3) return;

            var et:EdgeTable = new EdgeTable();
            et.addPolygon(poly);

            if (et.minY >= buffer.height || et.maxY < 0) return;

            var y0:int = Math.max(0, et.minY);
            var y1:int = Math.min(buffer.height - 1, et.maxY);

            var activeEdges:Array = [];

            for (var y:int = y0; y <= y1; y++)
            {
                // Add new edges starting at scanline y
                var newEdges:Array = et.getEdgesStartingAt(y);
                for (var n:int = 0; n < newEdges.length; n++)
                {
                    activeEdges.push(newEdges[n]);
                }

                // Remove edges where y >= yMax
                for (var r:int = activeEdges.length - 1; r >= 0; r--)
                {
                    if (y >= (activeEdges[r] as RasterEdge).yMax)
                    {
                        activeEdges.splice(r, 1);
                    }
                }

                // Sort active edges horizontally by xCurrent
                activeEdges.sort(function(a:RasterEdge, b:RasterEdge):int {
                    if (a.xCurrent < b.xCurrent) return -1;
                    if (a.xCurrent > b.xCurrent) return 1;
                    return 0;
                });

                // Fill spans across scanline
                fillScanlineSpans(buffer, y, activeEdges, color, evenOdd);

                // Advance X positions of active edges
                for (var a:int = 0; a < activeEdges.length; a++)
                {
                    var edge:RasterEdge = activeEdges[a] as RasterEdge;
                    edge.xCurrent += edge.invSlope;
                }
            }
        }

        private static function fillScanlineSpans(
            buffer:PixelBuffer,
            y:int,
            aet:Array,
            color:uint,
            evenOdd:Boolean
        ):void
        {
            var winding:int = 0;
            var inside:Boolean = false;
            var spanStartX:Number = 0.0;

            for (var i:int = 0; i < aet.length; i++)
            {
                var edge:RasterEdge = aet[i] as RasterEdge;
                var wasInside:Boolean = inside;

                if (evenOdd)
                {
                    inside = !inside;
                }
                else // Non-zero winding
                {
                    winding += edge.direction;
                    inside = (winding != 0);
                }

                if (!wasInside && inside)
                {
                    // Span starts
                    spanStartX = edge.xCurrent;
                }
                else if (wasInside && !inside)
                {
                    // Span ends
                    var spanEndX:Number = edge.xCurrent;
                    fillSpan(buffer, y, spanStartX, spanEndX, color);
                }
            }
        }

        private static function fillSpan(
            buffer:PixelBuffer,
            y:int,
            xStart:Number,
            xEnd:Number,
            color:uint
        ):void
        {
            var left:int = Math.max(0, Math.floor(xStart));
            var right:int = Math.min(buffer.width - 1, Math.ceil(xEnd));

            if (left > right) return;

            for (var x:int = left; x <= right; x++)
            {
                // Simple box coverage estimate for subpixel edges
                var coverage:Number = 1.0;
                if (x == left && (xStart > left))
                {
                    coverage = 1.0 - (xStart - left);
                }
                else if (x == right && (xEnd < right + 1))
                {
                    coverage = xEnd - right;
                }

                buffer.blendPixel(x, y, color, Math.max(0.0, Math.min(1.0, coverage)));
            }
        }

        /**
         * Renders all visible vector paths of a SceneGraph into a pixel target buffer.
         */
        public static function renderScene(buffer:PixelBuffer, scene:SceneGraph):void
        {
            if (buffer == null || scene == null) return;

            buffer.clear(scene.backgroundColor);

            scene.traversePreOrder(function(node:SceneNode):void {
                if (!node.visible || node.opacity <= 0.0) return;

                if (node is PathNode)
                {
                    var pn:PathNode = node as PathNode;
                    if (pn.pathData != null && pn.hasFill)
                    {
                        var contours:Array = pn.pathData.flatten(0.5);
                        for (var c:int = 0; c < contours.length; c++)
                        {
                            var poly:Polygon2D = new Polygon2D(contours[c]);
                            renderPolygon(buffer, poly, pn.fillColor, pn.pathData.windingRule == "evenOdd");
                        }
                    }
                }
            });
        }
    }
}
