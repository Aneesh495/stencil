package stencil.scene
{
    import stencil.geom.Rect2D;

    /**
     * TextNode represents styled typographic vector text.
     * Integrates with OpenType SFNT parsers and Knuth-Plass line layout formatters.
     */
    public class TextNode extends SceneNode
    {
        protected var _text:String;
        protected var _fontFamily:String;
        protected var _fontSize:Number;
        protected var _fontWeight:String;
        protected var _textColor:uint;
        protected var _lineHeight:Number;
        protected var _letterSpacing:Number;
        protected var _textAlign:String;
        protected var _maxWidth:Number;

        public function TextNode(name:String = "Text", text:String = "Hello Stencil")
        {
            super(name);
            _text = text;
            _fontFamily = "Inter";
            _fontSize = 16.0;
            _fontWeight = "normal";
            _textColor = 0xFF111827;
            _lineHeight = 1.4;
            _letterSpacing = 0.0;
            _textAlign = "left";
            _maxWidth = 0.0; // 0.0 means unconstrained
        }

        public function get text():String { return _text; }
        public function set text(val:String):void { _text = (val != null) ? val : ""; invalidate(true); }

        public function get fontFamily():String { return _fontFamily; }
        public function set fontFamily(val:String):void { _fontFamily = val; invalidate(true); }

        public function get fontSize():Number { return _fontSize; }
        public function set fontSize(val:Number):void { _fontSize = Math.max(1.0, val); invalidate(true); }

        public function get fontWeight():String { return _fontWeight; }
        public function set fontWeight(val:String):void { _fontWeight = val; }

        public function get textColor():uint { return _textColor; }
        public function set textColor(val:uint):void { _textColor = val; invalidate(false); }

        public function get lineHeight():Number { return _lineHeight; }
        public function set lineHeight(val:Number):void { _lineHeight = val; invalidate(true); }

        public function get letterSpacing():Number { return _letterSpacing; }
        public function set letterSpacing(val:Number):void { _letterSpacing = val; invalidate(true); }

        public function get textAlign():String { return _textAlign; }
        public function set textAlign(val:String):void { _textAlign = val; }

        public function get maxWidth():Number { return _maxWidth; }
        public function set maxWidth(val:Number):void { _maxWidth = val; invalidate(true); }

        override protected function computeNodeContentBounds():Rect2D
        {
            if (_text == null || _text.length == 0)
            {
                return new Rect2D(0.0, 0.0, 0.0, 0.0);
            }

            var charWidth:Number = _fontSize * 0.6 + _letterSpacing;
            var lineH:Number = _fontSize * _lineHeight;
            var lines:Array = _text.split("\n");

            var maxLineLen:int = 0;
            for (var i:int = 0; i < lines.length; i++)
            {
                if (lines[i].length > maxLineLen)
                {
                    maxLineLen = lines[i].length;
                }
            }

            var w:Number = maxLineLen * charWidth;
            if (_maxWidth > 0.0 && w > _maxWidth)
            {
                w = _maxWidth;
            }

            var h:Number = lines.length * lineH;
            return new Rect2D(0.0, 0.0, w, h);
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.text = _text;
            data.fontFamily = _fontFamily;
            data.fontSize = _fontSize;
            data.fontWeight = _fontWeight;
            data.textColor = _textColor;
            data.lineHeight = _lineHeight;
            data.letterSpacing = _letterSpacing;
            data.textAlign = _textAlign;
            data.maxWidth = _maxWidth;
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.text != null) _text = String(data.text);
                if (data.fontFamily != null) _fontFamily = String(data.fontFamily);
                if (data.fontSize != null) _fontSize = Number(data.fontSize);
                if (data.fontWeight != null) _fontWeight = String(data.fontWeight);
                if (data.textColor != null) _textColor = uint(data.textColor);
                if (data.lineHeight != null) _lineHeight = Number(data.lineHeight);
                if (data.letterSpacing != null) _letterSpacing = Number(data.letterSpacing);
                if (data.textAlign != null) _textAlign = String(data.textAlign);
                if (data.maxWidth != null) _maxWidth = Number(data.maxWidth);
                invalidate(true);
            }
        }

        override protected function getClassName():String
        {
            return "TextNode";
        }
    }
}
