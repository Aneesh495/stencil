package stencil.scene
{
    import stencil.geom.PathData;
    import stencil.geom.Rect2D;

    /**
     * PathNode renders arbitrary vector contours with stroke and fill paints.
     */
    public class PathNode extends SceneNode
    {
        protected var _pathData:PathData;
        protected var _fillColor:uint;
        protected var _hasFill:Boolean;
        protected var _strokeColor:uint;
        protected var _strokeWidth:Number;
        protected var _hasStroke:Boolean;
        protected var _strokeCap:String;
        protected var _strokeJoin:String;
        protected var _miterLimit:Number;

        public function PathNode(name:String = "Path", pathData:PathData = null)
        {
            super(name);
            _pathData = (pathData != null) ? pathData : new PathData();
            _fillColor = 0xFF336699;
            _hasFill = true;
            _strokeColor = 0xFF000000;
            _strokeWidth = 1.0;
            _hasStroke = true;
            _strokeCap = "round";
            _strokeJoin = "round";
            _miterLimit = 4.0;
        }

        public function get pathData():PathData { return _pathData; }
        public function set pathData(val:PathData):void { _pathData = val; invalidate(true); }

        public function get fillColor():uint { return _fillColor; }
        public function set fillColor(val:uint):void { _fillColor = val; invalidate(false); }

        public function get hasFill():Boolean { return _hasFill; }
        public function set hasFill(val:Boolean):void { _hasFill = val; invalidate(false); }

        public function get strokeColor():uint { return _strokeColor; }
        public function set strokeColor(val:uint):void { _strokeColor = val; invalidate(false); }

        public function get strokeWidth():Number { return _strokeWidth; }
        public function set strokeWidth(val:Number):void { _strokeWidth = val; invalidate(true); }

        public function get hasStroke():Boolean { return _hasStroke; }
        public function set hasStroke(val:Boolean):void { _hasStroke = val; invalidate(true); }

        public function get strokeCap():String { return _strokeCap; }
        public function set strokeCap(val:String):void { _strokeCap = val; }

        public function get strokeJoin():String { return _strokeJoin; }
        public function set strokeJoin(val:String):void { _strokeJoin = val; }

        public function get miterLimit():Number { return _miterLimit; }
        public function set miterLimit(val:Number):void { _miterLimit = val; }

        override protected function computeNodeContentBounds():Rect2D
        {
            if (_pathData == null) return new Rect2D(0.0, 0.0, 0.0, 0.0);

            var b:Rect2D = _pathData.bounds();
            if (_hasStroke && _strokeWidth > 0.0)
            {
                var pad:Number = _strokeWidth * 0.5;
                if (_strokeJoin == "miter")
                {
                    pad *= _miterLimit;
                }
                b = b.inflate(pad, pad);
            }
            return b;
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.pathData = (_pathData != null) ? _pathData.toJSON() : null;
            data.fillColor = _fillColor;
            data.hasFill = _hasFill;
            data.strokeColor = _strokeColor;
            data.strokeWidth = _strokeWidth;
            data.hasStroke = _hasStroke;
            data.strokeCap = _strokeCap;
            data.strokeJoin = _strokeJoin;
            data.miterLimit = _miterLimit;
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.pathData != null)
                {
                    _pathData = new PathData();
                    _pathData.fromJSON(data.pathData);
                }
                if (data.fillColor != null) _fillColor = uint(data.fillColor);
                if (data.hasFill != null) _hasFill = Boolean(data.hasFill);
                if (data.strokeColor != null) _strokeColor = uint(data.strokeColor);
                if (data.strokeWidth != null) _strokeWidth = Number(data.strokeWidth);
                if (data.hasStroke != null) _hasStroke = Boolean(data.hasStroke);
                if (data.strokeCap != null) _strokeCap = String(data.strokeCap);
                if (data.strokeJoin != null) _strokeJoin = String(data.strokeJoin);
                if (data.miterLimit != null) _miterLimit = Number(data.miterLimit);
                invalidate(true);
            }
        }

        override protected function getClassName():String
        {
            return "PathNode";
        }
    }
}
