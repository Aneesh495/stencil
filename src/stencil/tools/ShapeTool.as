package stencil.tools
{
    import stencil.geom.Point2D;
    import stencil.scene.SceneGraph;
    import stencil.scene.ShapeNode;

    /**
     * ShapeTool creates parametric geometric primitives (rectangles, circles, stars) via click-and-drag.
     */
    public class ShapeTool
    {
        protected var _scene:SceneGraph;
        protected var _shapeType:String;
        protected var _startPt:Point2D;
        protected var _currentShape:ShapeNode;
        protected var _isDrawing:Boolean;

        public function ShapeTool(scene:SceneGraph, shapeType:String = "rect")
        {
            _scene = scene;
            _shapeType = shapeType;
            _startPt = null;
            _currentShape = null;
            _isDrawing = false;
        }

        public function set shapeType(val:String):void
        {
            _shapeType = val;
        }

        public function onPointerDown(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            _startPt = worldPt.clone() as Point2D;
            _isDrawing = true;

            _currentShape = new ShapeNode("CreatedShape", _shapeType);
            _currentShape.x = worldPt.x;
            _currentShape.y = worldPt.y;
            _currentShape.shapeWidth = 1.0;
            _currentShape.shapeHeight = 1.0;
            _currentShape.rebuildGeometry();

            _scene.addChild(_currentShape);
        }

        public function onPointerMove(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (!_isDrawing || _currentShape == null || _startPt == null) return;

            var w:Number = worldPt.x - _startPt.x;
            var h:Number = worldPt.y - _startPt.y;

            if (shiftKey)
            {
                // Constrain aspect ratio 1:1
                var side:Number = Math.max(Math.abs(w), Math.abs(h));
                w = (w >= 0 ? 1 : -1) * side;
                h = (h >= 0 ? 1 : -1) * side;
            }

            var left:Number = (w >= 0) ? _startPt.x : (_startPt.x + w);
            var top:Number = (h >= 0) ? _startPt.y : (_startPt.y + h);

            _currentShape.x = left;
            _currentShape.y = top;
            _currentShape.shapeWidth = Math.max(1.0, Math.abs(w));
            _currentShape.shapeHeight = Math.max(1.0, Math.abs(h));
            _currentShape.rebuildGeometry();
        }

        public function onPointerUp(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            _isDrawing = false;
            _startPt = null;
            _currentShape = null;
        }
    }
}
