package stencil.scene
{
    import stencil.geom.Rect2D;

    /**
     * GroupNode aggregates multiple scene nodes into a single structural container.
     * Supports isolated rendering passes and rectangular boundary clipping.
     */
    public class GroupNode extends SceneNode
    {
        protected var _isolated:Boolean;
        protected var _clipChildren:Boolean;
        protected var _clipBounds:Rect2D;

        public function GroupNode(name:String = "Group")
        {
            super(name);
            _isolated = false;
            _clipChildren = false;
            _clipBounds = null;
        }

        public function get isIsolated():Boolean { return _isolated; }
        public function set isIsolated(val:Boolean):void { _isolated = val; }

        public function get clipChildren():Boolean { return _clipChildren; }
        public function set clipChildren(val:Boolean):void { _clipChildren = val; invalidate(true); }

        public function get clipBounds():Rect2D { return _clipBounds; }
        public function set clipBounds(val:Rect2D):void { _clipBounds = (val != null) ? val.clone() as Rect2D : null; invalidate(true); }

        override protected function computeNodeContentBounds():Rect2D
        {
            if (_clipChildren && _clipBounds != null)
            {
                return _clipBounds.clone() as Rect2D;
            }
            return new Rect2D(0.0, 0.0, 0.0, 0.0);
        }

        override public function localBounds():Rect2D
        {
            var raw:Rect2D = super.localBounds();
            if (_clipChildren && _clipBounds != null)
            {
                return raw.intersection(_clipBounds);
            }
            return raw;
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.isolated = _isolated;
            data.clipChildren = _clipChildren;
            data.clipBounds = (_clipBounds != null) ? _clipBounds.toJSON() : null;
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.isolated != null) _isolated = Boolean(data.isolated);
                if (data.clipChildren != null) _clipChildren = Boolean(data.clipChildren);
                if (data.clipBounds != null)
                {
                    _clipBounds = new Rect2D();
                    _clipBounds.fromJSON(data.clipBounds);
                }
            }
        }

        override protected function getClassName():String
        {
            return "GroupNode";
        }
    }
}
