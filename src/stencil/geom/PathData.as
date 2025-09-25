package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * PathData represents a resolution-independent composite 2D vector path.
     * Supports SVG path string parsing, bounds caching, polygon flattening, and affine transforms.
     */
    public class PathData implements ICloneable, ISerializable
    {
        public static const WINDING_EVEN_ODD:String = "evenOdd";
        public static const WINDING_NON_ZERO:String = "nonZero";

        protected var _segments:Array;
        protected var _windingRule:String;
        protected var _cachedBounds:Rect2D;
        protected var _dirty:Boolean;

        public function PathData()
        {
            _segments = [];
            _windingRule = WINDING_NON_ZERO;
            _cachedBounds = null;
            _dirty = true;
        }

        public function get segments():Array { return _segments; }

        public function get windingRule():String { return _windingRule; }
        public function set windingRule(val:String):void { _windingRule = val; }

        public function get segmentCount():int { return _segments.length; }

        public function clear():void
        {
            _segments = [];
            _cachedBounds = null;
            _dirty = true;
        }

        public function moveTo(x:Number, y:Number):PathData
        {
            _segments.push(new PathSegment(PathCommand.MOVE_TO, [new Point2D(x, y)]));
            _dirty = true;
            return this;
        }

        public function lineTo(x:Number, y:Number):PathData
        {
            _segments.push(new PathSegment(PathCommand.LINE_TO, [new Point2D(x, y)]));
            _dirty = true;
            return this;
        }

        public function curveTo(cx:Number, cy:Number, ax:Number, ay:Number):PathData
        {
            _segments.push(new PathSegment(PathCommand.CURVE_TO, [
                new Point2D(cx, cy),
                new Point2D(ax, ay)
            ]));
            _dirty = true;
            return this;
        }

        public function cubicTo(c1x:Number, c1y:Number, c2x:Number, c2y:Number, ax:Number, ay:Number):PathData
        {
            _segments.push(new PathSegment(PathCommand.CUBIC_TO, [
                new Point2D(c1x, c1y),
                new Point2D(c2x, c2y),
                new Point2D(ax, ay)
            ]));
            _dirty = true;
            return this;
        }

        public function closePath():PathData
        {
            _segments.push(new PathSegment(PathCommand.CLOSE, []));
            _dirty = true;
            return this;
        }

        /**
         * Computes exact tight bounding box enclosing all path segments.
         */
        public function bounds():Rect2D
        {
            if (!_dirty && _cachedBounds != null)
            {
                return _cachedBounds.clone() as Rect2D;
            }

            if (_segments.length == 0)
            {
                _cachedBounds = new Rect2D(0.0, 0.0, 0.0, 0.0);
                _dirty = false;
                return _cachedBounds;
            }

            var unionBox:Rect2D = new Rect2D(0.0, 0.0, 0.0, 0.0);
            var hasBox:Boolean = false;
            var currentPt:Point2D = new Point2D(0.0, 0.0);

            for (var i:int = 0; i < _segments.length; i++)
            {
                var seg:PathSegment = _segments[i] as PathSegment;
                switch (seg.command)
                {
                    case PathCommand.MOVE_TO:
                        currentPt = seg.points[0] as Point2D;
                        if (!hasBox)
                        {
                            unionBox = new Rect2D(currentPt.x, currentPt.y, 0.0, 0.0);
                            hasBox = true;
                        }
                        else
                        {
                            unionBox.unionPoint(currentPt);
                        }
                        break;

                    case PathCommand.LINE_TO:
                        var endPt:Point2D = seg.points[0] as Point2D;
                        unionBox.unionPoint(endPt);
                        currentPt = endPt;
                        break;

                    case PathCommand.CURVE_TO:
                        var qBez:Bezier2D = Bezier2D.quadratic(currentPt, seg.points[0] as Point2D, seg.points[1] as Point2D);
                        var qBox:Rect2D = qBez.bounds();
                        unionBox = unionBox.union(qBox);
                        currentPt = seg.points[1] as Point2D;
                        break;

                    case PathCommand.CUBIC_TO:
                        var cBez:Bezier2D = Bezier2D.cubic(currentPt, seg.points[0] as Point2D, seg.points[1] as Point2D, seg.points[2] as Point2D);
                        var cBox:Rect2D = cBez.bounds();
                        unionBox = unionBox.union(cBox);
                        currentPt = seg.points[2] as Point2D;
                        break;

                    case PathCommand.CLOSE:
                        break;
                }
            }

            _cachedBounds = unionBox;
            _dirty = false;
            return _cachedBounds.clone() as Rect2D;
        }

        /**
         * Flattens entire path into an array of polygonal contours (arrays of Point2D).
         */
        public function flatten(tolerance:Number = 0.5):Array
        {
            var contours:Array = [];
            var currentContour:Array = [];
            var currentPt:Point2D = new Point2D(0.0, 0.0);
            var startPt:Point2D = new Point2D(0.0, 0.0);

            for (var i:int = 0; i < _segments.length; i++)
            {
                var seg:PathSegment = _segments[i] as PathSegment;
                switch (seg.command)
                {
                    case PathCommand.MOVE_TO:
                        if (currentContour.length > 0)
                        {
                            contours.push(currentContour);
                            currentContour = [];
                        }
                        currentPt = (seg.points[0] as Point2D).clone() as Point2D;
                        startPt = currentPt.clone() as Point2D;
                        currentContour.push(currentPt);
                        break;

                    case PathCommand.LINE_TO:
                        currentPt = (seg.points[0] as Point2D).clone() as Point2D;
                        currentContour.push(currentPt);
                        break;

                    case PathCommand.CURVE_TO:
                        var qBez:Bezier2D = Bezier2D.quadratic(currentPt, seg.points[0] as Point2D, seg.points[1] as Point2D);
                        var qPts:Array = qBez.flatten(tolerance);
                        for (var q:int = 1; q < qPts.length; q++)
                        {
                            currentContour.push(qPts[q]);
                        }
                        currentPt = (seg.points[1] as Point2D).clone() as Point2D;
                        break;

                    case PathCommand.CUBIC_TO:
                        var cBez:Bezier2D = Bezier2D.cubic(currentPt, seg.points[0] as Point2D, seg.points[1] as Point2D, seg.points[2] as Point2D);
                        var cPts:Array = cBez.flatten(tolerance);
                        for (var c:int = 1; c < cPts.length; c++)
                        {
                            currentContour.push(cPts[c]);
                        }
                        currentPt = (seg.points[2] as Point2D).clone() as Point2D;
                        break;

                    case PathCommand.CLOSE:
                        if (currentContour.length > 0)
                        {
                            currentContour.push(startPt.clone() as Point2D);
                            contours.push(currentContour);
                            currentContour = [];
                        }
                        break;
                }
            }

            if (currentContour.length > 0)
            {
                contours.push(currentContour);
            }

            return contours;
        }

        /**
         * Applies affine transformation to all points in this path.
         */
        public function transform(m:Matrix2D):PathData
        {
            var res:PathData = new PathData();
            res.windingRule = this._windingRule;

            for (var i:int = 0; i < _segments.length; i++)
            {
                var seg:PathSegment = _segments[i] as PathSegment;
                var transformedPts:Array = [];
                for (var j:int = 0; j < seg.points.length; j++)
                {
                    transformedPts.push(m.transformPoint(seg.points[j] as Point2D));
                }
                res.segments.push(new PathSegment(seg.command, transformedPts));
            }

            return res;
        }

        /**
         * Converts path segments to standard SVG path data attribute format ("M ... L ... C ... Z").
         */
        public function toSVGPathString():String
        {
            var parts:Array = [];
            for (var i:int = 0; i < _segments.length; i++)
            {
                var seg:PathSegment = _segments[i] as PathSegment;
                switch (seg.command)
                {
                    case PathCommand.MOVE_TO:
                        parts.push("M " + MathUtil.roundTo(seg.points[0].x, 2) + " " + MathUtil.roundTo(seg.points[0].y, 2));
                        break;
                    case PathCommand.LINE_TO:
                        parts.push("L " + MathUtil.roundTo(seg.points[0].x, 2) + " " + MathUtil.roundTo(seg.points[0].y, 2));
                        break;
                    case PathCommand.CURVE_TO:
                        parts.push("Q " + MathUtil.roundTo(seg.points[0].x, 2) + " " + MathUtil.roundTo(seg.points[0].y, 2) +
                                   " " + MathUtil.roundTo(seg.points[1].x, 2) + " " + MathUtil.roundTo(seg.points[1].y, 2));
                        break;
                    case PathCommand.CUBIC_TO:
                        parts.push("C " + MathUtil.roundTo(seg.points[0].x, 2) + " " + MathUtil.roundTo(seg.points[0].y, 2) +
                                   " " + MathUtil.roundTo(seg.points[1].x, 2) + " " + MathUtil.roundTo(seg.points[1].y, 2) +
                                   " " + MathUtil.roundTo(seg.points[2].x, 2) + " " + MathUtil.roundTo(seg.points[2].y, 2));
                        break;
                    case PathCommand.CLOSE:
                        parts.push("Z");
                        break;
                }
            }
            return parts.join(" ");
        }

        public function clone():Object
        {
            var c:PathData = new PathData();
            c.windingRule = this._windingRule;
            for (var i:int = 0; i < _segments.length; i++)
            {
                c.segments.push((_segments[i] as PathSegment).clone());
            }
            return c;
        }

        public function toJSON():Object
        {
            var rawSegs:Array = [];
            for (var i:int = 0; i < _segments.length; i++)
            {
                rawSegs.push((_segments[i] as PathSegment).toJSON());
            }
            return {
                windingRule: _windingRule,
                segments: rawSegs
            };
        }

        public function fromJSON(data:Object):void
        {
            clear();
            if (data != null)
            {
                if (data.windingRule != null) _windingRule = String(data.windingRule);
                if (data.segments is Array)
                {
                    var arr:Array = data.segments as Array;
                    for (var i:int = 0; i < arr.length; i++)
                    {
                        var seg:PathSegment = new PathSegment();
                        seg.fromJSON(arr[i]);
                        _segments.push(seg);
                    }
                }
            }
        }
    }
}
