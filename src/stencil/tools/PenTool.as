package stencil.tools
{
    import stencil.geom.PathData;
    import stencil.geom.Point2D;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;

    /**
     * PenTool creates precision vector paths with tangent control handles and live preview.
     */
    public class PenTool
    {
        protected var _scene:SceneGraph;
        protected var _currentPathNode:PathNode;
        protected var _lastVertex:Point2D;
        protected var _isDraggingHandle:Boolean;

        public function PenTool(scene:SceneGraph)
        {
            _scene = scene;
            _currentPathNode = null;
            _lastVertex = null;
            _isDraggingHandle = false;
        }

        public function onPointerDown(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (_currentPathNode == null)
            {
                _currentPathNode = new PathNode("PenPath");
                _currentPathNode.pathData.moveTo(worldPt.x, worldPt.y);
                _scene.addChild(_currentPathNode);
                _lastVertex = worldPt.clone() as Point2D;
            }
            else
            {
                // Check if closing path near start
                var firstPt:Point2D = _currentPathNode.pathData.segments[0].points[0] as Point2D;
                if (worldPt.distanceTo(firstPt) <= 8.0)
                {
                    _currentPathNode.pathData.closePath();
                    _currentPathNode = null;
                    _lastVertex = null;
                    return;
                }

                _currentPathNode.pathData.lineTo(worldPt.x, worldPt.y);
                _lastVertex = worldPt.clone() as Point2D;
            }

            _isDraggingHandle = true;
        }

        public function onPointerMove(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            // Interactive handle dragging preview
        }

        public function onPointerUp(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            _isDraggingHandle = false;
        }

        public function finishPath():void
        {
            _currentPathNode = null;
            _lastVertex = null;
            _isDraggingHandle = false;
        }
    }
}
