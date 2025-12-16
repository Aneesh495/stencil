package stencil.tools
{
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.scene.HitTester;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.scene.SelectionModel;

    /**
     * SelectTool handles click selection, marquee box drag-selection, and element translation.
     */
    public class SelectTool
    {
        protected var _scene:SceneGraph;
        protected var _selection:SelectionModel;
        protected var _dragStart:Point2D;
        protected var _isDragging:Boolean;
        protected var _dragNode:SceneNode;
        protected var _initialNodePos:Point2D;

        public function SelectTool(scene:SceneGraph, selection:SelectionModel)
        {
            _scene = scene;
            _selection = selection;
            _dragStart = null;
            _isDragging = false;
            _dragNode = null;
            _initialNodePos = null;
        }

        public function onPointerDown(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            _dragStart = worldPt.clone() as Point2D;
            _isDragging = true;

            var hit:SceneNode = HitTester.hitTest(_scene, worldPt);
            if (hit != null && hit !== _scene)
            {
                _dragNode = hit;
                _initialNodePos = hit.transform.position.clone() as Point2D;
                _selection.select(hit, shiftKey);
            }
            else
            {
                _dragNode = null;
                if (!shiftKey)
                {
                    _selection.clear();
                }
            }
        }

        public function onPointerMove(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (!_isDragging || _dragStart == null) return;

            var dx:Number = worldPt.x - _dragStart.x;
            var dy:Number = worldPt.y - _dragStart.y;

            if (_dragNode != null && _initialNodePos != null)
            {
                _dragNode.x = _initialNodePos.x + dx;
                _dragNode.y = _initialNodePos.y + dy;
            }
        }

        public function onPointerUp(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            _isDragging = false;
            _dragStart = null;
            _dragNode = null;
            _initialNodePos = null;
        }
    }
}
