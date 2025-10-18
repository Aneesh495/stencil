package stencil.scene
{
    import stencil.geom.Rect2D;

    /**
     * ImageNode renders bitmap or vector image assets within responsive bounds.
     * Supports 9-slice scaling and aspect ratio locking.
     */
    public class ImageNode extends SceneNode
    {
        protected var _source:String;
        protected var _imageWidth:Number;
        protected var _imageHeight:Number;
        protected var _aspectRatioLocked:Boolean;
        protected var _nineSlice:Boolean;
        protected var _nineSliceInsets:Array; // [top, right, bottom, left]

        public function ImageNode(name:String = "Image", source:String = "")
        {
            super(name);
            _source = source;
            _imageWidth = 200.0;
            _imageHeight = 150.0;
            _aspectRatioLocked = true;
            _nineSlice = false;
            _nineSliceInsets = [10.0, 10.0, 10.0, 10.0];
        }

        public function get source():String { return _source; }
        public function set source(val:String):void { _source = val; invalidate(false); }

        public function get imageWidth():Number { return _imageWidth; }
        public function set imageWidth(val:Number):void { _imageWidth = val; invalidate(true); }

        public function get imageHeight():Number { return _imageHeight; }
        public function set imageHeight(val:Number):void { _imageHeight = val; invalidate(true); }

        public function get aspectRatioLocked():Boolean { return _aspectRatioLocked; }
        public function set aspectRatioLocked(val:Boolean):void { _aspectRatioLocked = val; }

        public function get nineSlice():Boolean { return _nineSlice; }
        public function set nineSlice(val:Boolean):void { _nineSlice = val; invalidate(true); }

        public function get nineSliceInsets():Array { return _nineSliceInsets; }
        public function set nineSliceInsets(val:Array):void { _nineSliceInsets = val; invalidate(true); }

        override protected function computeNodeContentBounds():Rect2D
        {
            return new Rect2D(0.0, 0.0, _imageWidth, _imageHeight);
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.source = _source;
            data.imageWidth = _imageWidth;
            data.imageHeight = _imageHeight;
            data.aspectRatioLocked = _aspectRatioLocked;
            data.nineSlice = _nineSlice;
            data.nineSliceInsets = _nineSliceInsets.slice();
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.source != null) _source = String(data.source);
                if (data.imageWidth != null) _imageWidth = Number(data.imageWidth);
                if (data.imageHeight != null) _imageHeight = Number(data.imageHeight);
                if (data.aspectRatioLocked != null) _aspectRatioLocked = Boolean(data.aspectRatioLocked);
                if (data.nineSlice != null) _nineSlice = Boolean(data.nineSlice);
                if (data.nineSliceInsets is Array) _nineSliceInsets = (data.nineSliceInsets as Array).slice();
                invalidate(true);
            }
        }

        override protected function getClassName():String
        {
            return "ImageNode";
        }
    }
}
