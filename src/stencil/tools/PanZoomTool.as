package stencil.tools
{
    import stencil.geom.Point2D;
    import stencil.geom.Vector2D;
    import stencil.scene.Camera2D;

    /**
     * PanZoomTool manages canvas navigation with velocity momentum and friction damping.
     */
    public class PanZoomTool
    {
        protected var _camera:Camera2D;
        protected var _lastPointer:Point2D;
        protected var _velocity:Vector2D;
        protected var _isPanning:Boolean;
        protected var _friction:Number;

        public function PanZoomTool(camera:Camera2D)
        {
            _camera = camera;
            _lastPointer = null;
            _velocity = new Vector2D(0.0, 0.0);
            _isPanning = false;
            _friction = 0.92;
        }

        public function get isPanning():Boolean
        {
            return _isPanning;
        }

        public function onPointerDown(screenPt:Point2D):void
        {
            _lastPointer = screenPt.clone() as Point2D;
            _isPanning = true;
            _velocity.dx = 0.0;
            _velocity.dy = 0.0;
        }

        public function onPointerMove(screenPt:Point2D):void
        {
            if (!_isPanning || _lastPointer == null) return;

            var dx:Number = screenPt.x - _lastPointer.x;
            var dy:Number = screenPt.y - _lastPointer.y;

            // Pan camera inversely to screen motion
            var worldDx:Number = -dx / _camera.zoom;
            var worldDy:Number = -dy / _camera.zoom;

            _camera.pan(worldDx, worldDy);

            _velocity.dx = worldDx;
            _velocity.dy = worldDy;

            _lastPointer.copyFrom(screenPt);
        }

        public function onPointerUp():void
        {
            _isPanning = false;
            _lastPointer = null;
        }

        public function onWheel(screenPt:Point2D, deltaZoom:Number):void
        {
            var factor:Number = (deltaZoom > 0) ? 1.1 : 0.9;
            _camera.zoomAt(screenPt, factor);
        }

        /**
         * Physics step: applies velocity decay and momentum coasting.
         */
        public function update(dt:Number):void
        {
            if (!_isPanning && _velocity.magnitudeSquared > 0.01)
            {
                _camera.pan(_velocity.dx, _velocity.dy);
                _velocity.dx *= _friction;
                _velocity.dy *= _friction;
            }
        }
    }
}
