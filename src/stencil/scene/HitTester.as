package stencil.scene
{
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.geom.PathData;
    import stencil.geom.Polygon2D;

    /**
     * HitTester provides geometric hit testing and interactive object picking.
     * Evaluates point containment against fill areas, stroked vector paths, and clipping masks.
     */
    public class HitTester
    {
        /**
         * Finds the topmost visible node at a given world point.
         */
        public static function hitTest(root:SceneGraph, worldPt:Point2D, tolerance:Number = 4.0):SceneNode
        {
            var candidates:Array = hitTestAll(root, worldPt, tolerance);
            if (candidates.length > 0)
            {
                return candidates[0] as SceneNode; // Topmost
            }
            return null;
        }

        /**
         * Returns all visible nodes under worldPt ordered from topmost to bottommost.
         */
        public static function hitTestAll(root:SceneGraph, worldPt:Point2D, tolerance:Number = 4.0):Array
        {
            var hits:Array = [];
            if (root == null || worldPt == null) return hits;

            testNodeRecursive(root, worldPt, tolerance, hits);
            return hits;
        }

        private static function testNodeRecursive(
            node:SceneNode,
            worldPt:Point2D,
            tol:Number,
            outHits:Array
        ):void
        {
            if (!node.visible || node.opacity <= 0.0) return;

            // Broadphase AABB test
            var wb:Rect2D = node.worldBounds();
            if (!wb.isEmpty())
            {
                var expandedBounds:Rect2D = wb.inflate(tol, tol);
                if (!expandedBounds.containsPoint(worldPt))
                {
                    return;
                }
            }

            // Test children in reverse z-order (topmost first)
            for (var i:int = node.numChildren - 1; i >= 0; i--)
            {
                testNodeRecursive(node.getChildAt(i), worldPt, tol, outHits);
            }

            // Test node itself if it's a content leaf
            if (node is PathNode)
            {
                if (testPathNode(node as PathNode, worldPt, tol))
                {
                    outHits.push(node);
                }
            }
            else if (node is TextNode || node is ImageNode)
            {
                // Box hit test for text and images
                if (wb.inflate(tol, tol).containsPoint(worldPt))
                {
                    outHits.push(node);
                }
            }
        }

        private static function testPathNode(pathNode:PathNode, worldPt:Point2D, tol:Number):Boolean
        {
            var localPt:Point2D = pathNode.worldToLocal(worldPt);
            var path:PathData = pathNode.pathData;
            if (path == null) return false;

            // Test fill containment
            if (pathNode.hasFill)
            {
                var contours:Array = path.flatten(1.0);
                for (var i:int = 0; i < contours.length; i++)
                {
                    var poly:Polygon2D = new Polygon2D(contours[i]);
                    if (poly.containsPoint(localPt))
                    {
                        return true;
                    }
                }
            }

            // Test stroke proximity
            if (pathNode.hasStroke)
            {
                var strokeTol:Number = (pathNode.strokeWidth * 0.5) + tol;
                var flatContours:Array = path.flatten(0.5);
                for (var c:int = 0; c < flatContours.length; c++)
                {
                    var pts:Array = flatContours[c];
                    for (var j:int = 0; j < pts.length - 1; j++)
                    {
                        var p1:Point2D = pts[j] as Point2D;
                        var p2:Point2D = pts[j + 1] as Point2D;
                        var dist:Number = distanceToSegment(localPt, p1, p2);
                        if (dist <= strokeTol)
                        {
                            return true;
                        }
                    }
                }
            }

            return false;
        }

        private static function distanceToSegment(p:Point2D, a:Point2D, b:Point2D):Number
        {
            var dx:Number = b.x - a.x;
            var dy:Number = b.y - a.y;
            var lenSq:Number = dx * dx + dy * dy;

            if (lenSq <= 1e-9)
            {
                return p.distanceTo(a);
            }

            var t:Number = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
            t = Math.max(0.0, Math.min(1.0, t));

            var projX:Number = a.x + t * dx;
            var projY:Number = a.y + t * dy;

            var px:Number = p.x - projX;
            var py:Number = p.y - projY;
            return Math.sqrt(px * px + py * py);
        }
    }
}
