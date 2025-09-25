package stencil.geom
{
    import stencil.core.MathUtil;

    /**
     * Fluent geometric construction builder for PathData models.
     * Implements standard geometric primitives: circles, rounded rectangles, stars, regular polygons, and arcs.
     */
    public class PathBuilder
    {
        protected var _path:PathData;

        public function PathBuilder(target:PathData = null)
        {
            _path = (target != null) ? target : new PathData();
        }

        public function get path():PathData
        {
            return _path;
        }

        public function build():PathData
        {
            return _path;
        }

        public function moveTo(x:Number, y:Number):PathBuilder
        {
            _path.moveTo(x, y);
            return this;
        }

        public function lineTo(x:Number, y:Number):PathBuilder
        {
            _path.lineTo(x, y);
            return this;
        }

        public function curveTo(cx:Number, cy:Number, ax:Number, ay:Number):PathBuilder
        {
            _path.curveTo(cx, cy, ax, ay);
            return this;
        }

        public function cubicTo(c1x:Number, c1y:Number, c2x:Number, c2y:Number, ax:Number, ay:Number):PathBuilder
        {
            _path.cubicTo(c1x, c1y, c2x, c2y, ax, ay);
            return this;
        }

        public function close():PathBuilder
        {
            _path.closePath();
            return this;
        }

        /**
         * Appends an axis-aligned rectangle contour.
         */
        public function rect(x:Number, y:Number, width:Number, height:Number):PathBuilder
        {
            _path.moveTo(x, y)
                 .lineTo(x + width, y)
                 .lineTo(x + width, y + height)
                 .lineTo(x, y + height)
                 .closePath();
            return this;
        }

        /**
         * Appends a rounded rectangle with corner radii.
         */
        public function roundedRect(
            x:Number,
            y:Number,
            width:Number,
            height:Number,
            radiusX:Number,
            radiusY:Number = -1
        ):PathBuilder
        {
            if (radiusY < 0) radiusY = radiusX;

            var maxRx:Number = width * 0.5;
            var maxRy:Number = height * 0.5;
            var rx:Number = Math.min(radiusX, maxRx);
            var ry:Number = Math.min(radiusY, maxRy);

            if (rx <= 0 || ry <= 0)
            {
                return rect(x, y, width, height);
            }

            // Approximate quarter ellipse using cubic Bezier with magic constant kappa = 4*(sqrt(2)-1)/3 = ~0.55228475
            var kx:Number = rx * 0.55228475;
            var ky:Number = ry * 0.55228475;

            var right:Number = x + width;
            var bottom:Number = y + height;

            _path.moveTo(x + rx, y)
                 .lineTo(right - rx, y)
                 .cubicTo(right - rx + kx, y, right, y + ry - ky, right, y + ry)
                 .lineTo(right, bottom - ry)
                 .cubicTo(right, bottom - ry + ky, right - rx + kx, bottom, right - rx, bottom)
                 .lineTo(x + rx, bottom)
                 .cubicTo(x + rx - kx, bottom, x, bottom - ry + ky, x, bottom - ry)
                 .lineTo(x, y + ry)
                 .cubicTo(x, y + ry - ky, x + rx - kx, y, x + rx, y)
                 .closePath();

            return this;
        }

        /**
         * Appends a circular contour.
         */
        public function circle(cx:Number, cy:Number, radius:Number):PathBuilder
        {
            return ellipse(cx, cy, radius, radius);
        }

        /**
         * Appends an elliptical contour using four cubic Bezier quarter-arcs.
         */
        public function ellipse(cx:Number, cy:Number, rx:Number, ry:Number):PathBuilder
        {
            var kx:Number = rx * 0.55228475;
            var ky:Number = ry * 0.55228475;

            _path.moveTo(cx, cy - ry)
                 .cubicTo(cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy)
                 .cubicTo(cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry)
                 .cubicTo(cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy)
                 .cubicTo(cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry)
                 .closePath();

            return this;
        }

        /**
         * Appends a regular n-sided polygon centered at (cx, cy).
         */
        public function regularPolygon(cx:Number, cy:Number, radius:Number, sides:int = 5):PathBuilder
        {
            if (sides < 3) sides = 3;
            var step:Number = MathUtil.TWO_PI / sides;
            var startAngle:Number = -MathUtil.HALF_PI; // Align vertex to top

            for (var i:int = 0; i < sides; i++)
            {
                var a:Number = startAngle + i * step;
                var px:Number = cx + Math.cos(a) * radius;
                var py:Number = cy + Math.sin(a) * radius;
                if (i == 0)
                {
                    _path.moveTo(px, py);
                }
                else
                {
                    _path.lineTo(px, py);
                }
            }
            _path.closePath();
            return this;
        }

        /**
         * Appends a regular star with alternating outer and inner vertices.
         */
        public function star(
            cx:Number,
            cy:Number,
            outerRadius:Number,
            innerRadius:Number,
            points:int = 5
        ):PathBuilder
        {
            if (points < 3) points = 3;
            var totalVertices:int = points * 2;
            var step:Number = MathUtil.PI / points;
            var startAngle:Number = -MathUtil.HALF_PI;

            for (var i:int = 0; i < totalVertices; i++)
            {
                var r:Number = (i % 2 == 0) ? outerRadius : innerRadius;
                var a:Number = startAngle + i * step;
                var px:Number = cx + Math.cos(a) * r;
                var py:Number = cy + Math.sin(a) * r;

                if (i == 0)
                {
                    _path.moveTo(px, py);
                }
                else
                {
                    _path.lineTo(px, py);
                }
            }
            _path.closePath();
            return this;
        }

        /**
         * Appends an elliptical or circular arc from startAngle to endAngle.
         */
        public function arc(
            cx:Number,
            cy:Number,
            radius:Number,
            startAngle:Number,
            endAngle:Number,
            counterClockwise:Boolean = false
        ):PathBuilder
        {
            var sweep:Number = endAngle - startAngle;
            if (counterClockwise)
            {
                if (sweep > 0) sweep -= MathUtil.TWO_PI;
            }
            else
            {
                if (sweep < 0) sweep += MathUtil.TWO_PI;
            }

            var numSegments:int = Math.max(1, Math.ceil(Math.abs(sweep) / (MathUtil.PI * 0.5)));
            var segSweep:Number = sweep / numSegments;

            var currentAngle:Number = startAngle;
            var startX:Number = cx + Math.cos(currentAngle) * radius;
            var startY:Number = cy + Math.sin(currentAngle) * radius;

            if (_path.segmentCount == 0)
            {
                _path.moveTo(startX, startY);
            }
            else
            {
                _path.lineTo(startX, startY);
            }

            for (var i:int = 0; i < numSegments; i++)
            {
                var nextAngle:Number = currentAngle + segSweep;
                var halfSweep:Number = segSweep * 0.5;
                var k:Number = (4.0 / 3.0) * Math.tan(halfSweep * 0.5) * radius;

                var c1x:Number = cx + Math.cos(currentAngle) * radius - Math.sin(currentAngle) * k;
                var c1y:Number = cy + Math.sin(currentAngle) * radius + Math.cos(currentAngle) * k;

                var c2x:Number = cx + Math.cos(nextAngle) * radius + Math.sin(nextAngle) * k;
                var c2y:Number = cy + Math.sin(nextAngle) * radius - Math.cos(nextAngle) * k;

                var endX:Number = cx + Math.cos(nextAngle) * radius;
                var endY:Number = cy + Math.sin(nextAngle) * radius;

                _path.cubicTo(c1x, c1y, c2x, c2y, endX, endY);
                currentAngle = nextAngle;
            }

            return this;
        }
    }
}
