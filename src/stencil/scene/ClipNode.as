package stencil.scene
{
    import stencil.geom.PathData;
    import stencil.geom.Rect2D;

    /**
     * ClipNode applies an arbitrary vector path clipping mask to all child scene nodes.
     */
    public class ClipNode extends SceneNode
    {
        protected var _clipPath:PathData;

        public function ClipNode(name:String = "Clip", clipPath:PathData = null)
        {
            super(name);
            _clipPath = (clipPath != null) ? clipPath : new PathData();
        }

        public function get clipPath():PathData { return _clipPath; }
        public function set clipPath(val:PathData):void { _clipPath = val; invalidate(true); }

        override protected function computeNodeContentBounds():Rect2D
        {
            if (_clipPath == null) return new Rect2D(0.0, 0.0, 0.0, 0.0);
            return _clipPath.bounds();
        }

        override public function localBounds():Rect2D
        {
            var raw:Rect2D = super.localBounds();
            if (_clipPath != null)
            {
                var maskBounds:Rect2D = _clipPath.bounds();
                return raw.intersection(maskBounds);
            }
            return raw;
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.clipPath = (_clipPath != null) ? _clipPath.toJSON() : null;
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null && data.clipPath != null)
            {
                _clipPath = new PathData();
                _clipPath.fromJSON(data.clipPath);
                invalidate(true);
            }
        }

        override protected function getClassName():String
        {
            return "ClipNode";
        }
    }
}
