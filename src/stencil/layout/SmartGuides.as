package stencil.layout
{
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;

    /**
     * SmartGuides provides dynamic snapping and alignment guides during interactive dragging.
     * Detects edge-to-edge alignments, center alignments, and equidistant spacing intervals.
     */
    public class SmartGuides
    {
        public static function snap(
            draggedBox:Rect2D,
            otherBoxes:Array,
            threshold:Number = 6.0
        ):Object
        {
            var result:Object = {
                dx: 0.0,
                dy: 0.0,
                guidelines: [] // Array of { p1: Point2D, p2: Point2D, orientation: String }
            };

            if (draggedBox == null || otherBoxes == null || otherBoxes.length == 0)
            {
                return result;
            }

            var bestDx:Number = threshold + 1.0;
            var bestDy:Number = threshold + 1.0;
            var snapDx:Number = 0.0;
            var snapDy:Number = 0.0;

            var dL:Number = draggedBox.left;
            var dC:Number = draggedBox.centerX;
            var dR:Number = draggedBox.right;
            var dT:Number = draggedBox.top;
            var dM:Number = draggedBox.centerY;
            var dB:Number = draggedBox.bottom;

            for (var i:int = 0; i < otherBoxes.length; i++)
            {
                var target:Rect2D = otherBoxes[i] as Rect2D;
                if (target === draggedBox) continue;

                var tL:Number = target.left;
                var tC:Number = target.centerX;
                var tR:Number = target.right;
                var tT:Number = target.top;
                var tM:Number = target.centerY;
                var tB:Number = target.bottom;

                // X alignments: L-L, L-R, C-C, R-L, R-R
                var xPairs:Array = [
                    { diff: tL - dL, snapLine: tL },
                    { diff: tR - dL, snapLine: tR },
                    { diff: tC - dC, snapLine: tC },
                    { diff: tL - dR, snapLine: tL },
                    { diff: tR - dR, snapLine: tR }
                ];

                for (var xIdx:int = 0; xIdx < xPairs.length; xIdx++)
                {
                    var pairX:Object = xPairs[xIdx];
                    var absDiffX:Number = Math.abs(pairX.diff);
                    if (absDiffX <= threshold && absDiffX < bestDx)
                    {
                        bestDx = absDiffX;
                        snapDx = pairX.diff;
                        result.guidelines.push({
                            p1: new Point2D(pairX.snapLine, Math.min(dT, tT) - 20.0),
                            p2: new Point2D(pairX.snapLine, Math.max(dB, tB) + 20.0),
                            orientation: "vertical"
                        });
                    }
                }

                // Y alignments: T-T, T-B, M-M, B-T, B-B
                var yPairs:Array = [
                    { diff: tT - dT, snapLine: tT },
                    { diff: tB - dT, snapLine: tB },
                    { diff: tM - dM, snapLine: tM },
                    { diff: tT - dB, snapLine: tT },
                    { diff: tB - dB, snapLine: tB }
                ];

                for (var yIdx:int = 0; yIdx < yPairs.length; yIdx++)
                {
                    var pairY:Object = yPairs[yIdx];
                    var absDiffY:Number = Math.abs(pairY.diff);
                    if (absDiffY <= threshold && absDiffY < bestDy)
                    {
                        bestDy = absDiffY;
                        snapDy = pairY.diff;
                        result.guidelines.push({
                            p1: new Point2D(Math.min(dL, tL) - 20.0, pairY.snapLine),
                            p2: new Point2D(Math.max(dR, tR) + 20.0, pairY.snapLine),
                            orientation: "horizontal"
                        });
                    }
                }
            }

            if (bestDx <= threshold) result.dx = snapDx;
            if (bestDy <= threshold) result.dy = snapDy;

            return result;
        }
    }
}
