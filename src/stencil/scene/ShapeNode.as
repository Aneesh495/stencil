package stencil.scene
{
    import stencil.geom.PathBuilder;
    import stencil.geom.Rect2D;

    /**
     * ShapeNode represents editable parametric primitives (rectangles, rounded boxes, circles, stars).
     * Automatically regenerates vector contours on parameter modifications.
     */
    public class ShapeNode extends PathNode
    {
        public static const SHAPE_RECT:String = "rect";
        public static const SHAPE_ROUNDED_RECT:String = "roundedRect";
        public static const SHAPE_CIRCLE:String = "circle";
        public static const SHAPE_ELLIPSE:String = "ellipse";
        public static const SHAPE_POLYGON:String = "polygon";
        public static const SHAPE_STAR:String = "star";

        protected var _shapeType:String;
        protected var _shapeWidth:Number;
        protected var _shapeHeight:Number;
        protected var _cornerRadius:Number;
        protected var _sides:int;
        protected var _innerRadius:Number;

        public function ShapeNode(name:String = "Shape", shapeType:String = "rect")
        {
            super(name);
            _shapeType = shapeType;
            _shapeWidth = 100.0;
            _shapeHeight = 100.0;
            _cornerRadius = 8.0;
            _sides = 5;
            _innerRadius = 25.0;
            rebuildGeometry();
        }

        public function get shapeType():String { return _shapeType; }
        public function set shapeType(val:String):void { _shapeType = val; rebuildGeometry(); }

        public function get shapeWidth():Number { return _shapeWidth; }
        public function set shapeWidth(val:Number):void { _shapeWidth = val; rebuildGeometry(); }

        public function get shapeHeight():Number { return _shapeHeight; }
        public function set shapeHeight(val:Number):void { _shapeHeight = val; rebuildGeometry(); }

        public function get cornerRadius():Number { return _cornerRadius; }
        public function set cornerRadius(val:Number):void { _cornerRadius = val; rebuildGeometry(); }

        public function get sides():int { return _sides; }
        public function set sides(val:int):void { _sides = val; rebuildGeometry(); }

        public function get innerRadius():Number { return _innerRadius; }
        public function set innerRadius(val:Number):void { _innerRadius = val; rebuildGeometry(); }

        public function rebuildGeometry():void
        {
            _pathData.clear();
            var builder:PathBuilder = new PathBuilder(_pathData);

            switch (_shapeType)
            {
                case SHAPE_RECT:
                    builder.rect(0.0, 0.0, _shapeWidth, _shapeHeight);
                    break;

                case SHAPE_ROUNDED_RECT:
                    builder.roundedRect(0.0, 0.0, _shapeWidth, _shapeHeight, _cornerRadius);
                    break;

                case SHAPE_CIRCLE:
                    var r:Number = Math.min(_shapeWidth, _shapeHeight) * 0.5;
                    builder.circle(r, r, r);
                    break;

                case SHAPE_ELLIPSE:
                    builder.ellipse(_shapeWidth * 0.5, _shapeHeight * 0.5, _shapeWidth * 0.5, _shapeHeight * 0.5);
                    break;

                case SHAPE_POLYGON:
                    builder.regularPolygon(_shapeWidth * 0.5, _shapeHeight * 0.5, Math.min(_shapeWidth, _shapeHeight) * 0.5, _sides);
                    break;

                case SHAPE_STAR:
                    builder.star(_shapeWidth * 0.5, _shapeHeight * 0.5, Math.min(_shapeWidth, _shapeHeight) * 0.5, _innerRadius, _sides);
                    break;
            }

            invalidate(true);
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.shapeType = _shapeType;
            data.shapeWidth = _shapeWidth;
            data.shapeHeight = _shapeHeight;
            data.cornerRadius = _cornerRadius;
            data.sides = _sides;
            data.innerRadius = _innerRadius;
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.shapeType != null) _shapeType = String(data.shapeType);
                if (data.shapeWidth != null) _shapeWidth = Number(data.shapeWidth);
                if (data.shapeHeight != null) _shapeHeight = Number(data.shapeHeight);
                if (data.cornerRadius != null) _cornerRadius = Number(data.cornerRadius);
                if (data.sides != null) _sides = int(data.sides);
                if (data.innerRadius != null) _innerRadius = Number(data.innerRadius);
                rebuildGeometry();
            }
        }

        override protected function getClassName():String
        {
            return "ShapeNode";
        }
    }
}
