package stencil.scene
{
    import stencil.core.MathUtil;
    import stencil.geom.Matrix2D;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;

    /**
     * Camera2D provides viewport navigation and coordinate transformation for infinite 2D canvases.
     * Manages pan offsets, zoom levels, rotation angles, and anchored focal zooming.
     */
    public class Camera2D
    {
        protected var _x:Number;
        protected var _y:Number;
        protected var _zoom:Number;
        protected var _rotation:Number;
        protected var _viewportWidth:Number;
        protected var _viewportHeight:Number;

        protected var _minZoom:Number;
        protected var _maxZoom:Number;

        public function Camera2D(width:Number = 1920.0, height:Number = 1080.0)
        {
            _viewportWidth = width;
            _viewportHeight = height;
            _x = width * 0.5;
            _y = height * 0.5;
            _zoom = 1.0;
            _rotation = 0.0;
            _minZoom = 0.05;
            _maxZoom = 64.0;
        }

        public function get x():Number { return _x; }
        public function set x(val:Number):void { _x = val; }

        public function get y():Number { return _y; }
        public function set y(val:Number):void { _y = val; }

        public function get zoom():Number { return _zoom; }
        public function set zoom(val:Number):void
        {
            _zoom = MathUtil.clamp(val, _minZoom, _maxZoom);
        }

        public function get rotation():Number { return _rotation; }
        public function set rotation(val:Number):void { _rotation = val; }

        public function get viewportWidth():Number { return _viewportWidth; }
        public function set viewportWidth(val:Number):void { _viewportWidth = val; }

        public function get viewportHeight():Number { return _viewportHeight; }
        public function set viewportHeight(val:Number):void { _viewportHeight = val; }

        /**
         * Translates camera position in world units.
         */
        public function pan(dx:Number, dy:Number):void
        {
            _x += dx;
            _y += dy;
        }

        /**
         * Zooms camera centered around a specific screen anchor point.
         */
        public function zoomAt(screenAnchor:Point2D, factor:Number):void
        {
            var worldBefore:Point2D = screenToWorld(screenAnchor);
            this.zoom = _zoom * factor;
            var worldAfter:Point2D = screenToWorld(screenAnchor);

            _x += (worldBefore.x - worldAfter.x);
            _y += (worldBefore.y - worldAfter.y);
        }

        /**
         * Computes world-to-screen view matrix:
         * Screen = T(viewportCenter) * S(zoom) * R(rot) * T(-cameraPos) * World
         */
        public function getViewMatrix():Matrix2D
        {
            var m:Matrix2D = Matrix2D.translation(-_x, -_y);
            if (_rotation != 0.0)
            {
                m.rotate(_rotation);
            }
            if (_zoom != 1.0)
            {
                m.scale(_zoom, _zoom);
            }
            m.translate(_viewportWidth * 0.5, _viewportHeight * 0.5);
            return m;
        }

        /**
         * Computes screen-to-world inverse view matrix.
         */
        public function getInverseViewMatrix():Matrix2D
        {
            return getViewMatrix().getInverse();
        }

        /**
         * Converts screen pixel coordinate to world space point.
         */
        public function screenToWorld(screenPt:Point2D):Point2D
        {
            return getInverseViewMatrix().transformPoint(screenPt);
        }

        /**
         * Converts world space point to screen pixel coordinate.
         */
        public function worldToScreen(worldPt:Point2D):Point2D
        {
            return getViewMatrix().transformPoint(worldPt);
        }

        /**
         * Computes the bounding rectangle in world space currently visible in viewport.
         */
        public function getVisibleWorldBounds():Rect2D
        {
            var inv:Matrix2D = getInverseViewMatrix();
            var p1:Point2D = inv.transformPoint(new Point2D(0.0, 0.0));
            var p2:Point2D = inv.transformPoint(new Point2D(_viewportWidth, 0.0));
            var p3:Point2D = inv.transformPoint(new Point2D(_viewportWidth, _viewportHeight));
            var p4:Point2D = inv.transformPoint(new Point2D(0.0, _viewportHeight));

            var bounds:Rect2D = Rect2D.fromPoints(p1, p2);
            bounds.unionPoint(p3);
            bounds.unionPoint(p4);
            return bounds;
        }
    }
}
