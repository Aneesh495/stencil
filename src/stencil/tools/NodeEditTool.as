package stencil.tools
{
    import stencil.geom.PathSegment;
    import stencil.geom.Point2D;
    import stencil.scene.PathNode;

    /**
     * NodeEditTool provides sub-object editing of individual vector vertices and control points.
     */
    public class NodeEditTool
    {
        protected var _targetPath:PathNode;
        protected var _selectedSegmentIdx:int;
        protected var _selectedPointIdx:int;
        protected var _isDragging:Boolean;

        public function NodeEditTool()
        {
            _targetPath = null;
            _selectedSegmentIdx = -1;
            _selectedPointIdx = -1;
            _isDragging = false;
        }

        public function setTarget(path:PathNode):void
        {
            _targetPath = path;
            _selectedSegmentIdx = -1;
            _selectedPointIdx = -1;
        }

        public function onPointerDown(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (_targetPath == null || _targetPath.pathData == null) return;

            var localPt:Point2D = _targetPath.worldToLocal(worldPt);
            var segs:Array = _targetPath.pathData.segments;
            var tol:Number = 8.0;

            for (var i:int = 0; i < segs.length; i++)
            {
                var seg:PathSegment = segs[i] as PathSegment;
                for (var j:int = 0; j < seg.points.length; j++)
                {
                    var pt:Point2D = seg.points[j] as Point2D;
                    if (pt.distanceTo(localPt) <= tol)
                    {
                        _selectedSegmentIdx = i;
                        _selectedPointIdx = j;
                        _isDragging = true;
                        return;
                    }
                }
            }

            _selectedSegmentIdx = -1;
            _selectedPointIdx = -1;
        }

        public function onPointerMove(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (!_isDragging || _targetPath == null || _selectedSegmentIdx == -1) return;

            var localPt:Point2D = _targetPath.worldToLocal(worldPt);
            var seg:PathSegment = _targetPath.pathData.segments[_selectedSegmentIdx] as PathSegment;
            var pt:Point2D = seg.points[_selectedPointIdx] as Point2D;
            pt.x = localPt.x;
            pt.y = localPt.y;
            _targetPath.invalidate(true);
        }

        public function onPointerUp(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            _isDragging = false;
        }
    }
}
