package stencil.style
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * StrokeStyle configures stroke rasterization and path outline extrusion parameters.
     */
    public class StrokeStyle implements ICloneable, ISerializable
    {
        public static const CAP_BUTT:String = "butt";
        public static const CAP_ROUND:String = "round";
        public static const CAP_SQUARE:String = "square";

        public static const JOIN_MITER:String = "miter";
        public static const JOIN_ROUND:String = "round";
        public static const JOIN_BEVEL:String = "bevel";

        public var width:Number;
        public var cap:String;
        public var join:String;
        public var miterLimit:Number;
        public var dashArray:Array; // Array of Numbers
        public var dashOffset:Number;
        public var paint:Paint;

        public function StrokeStyle(
            width:Number = 1.0,
            paint:Paint = null,
            cap:String = "round",
            join:String = "round",
            miterLimit:Number = 4.0
        )
        {
            this.width = Math.max(0.0, width);
            this.paint = (paint != null) ? (paint.clone() as Paint) : new SolidPaint(new Color(0xFF000000));
            this.cap = cap;
            this.join = join;
            this.miterLimit = miterLimit;
            this.dashArray = [];
            this.dashOffset = 0.0;
        }

        public function isDashed():Boolean
        {
            return dashArray != null && dashArray.length > 0;
        }

        public function clone():Object
        {
            var s:StrokeStyle = new StrokeStyle(width, paint.clone() as Paint, cap, join, miterLimit);
            s.dashArray = (dashArray != null) ? dashArray.slice() : [];
            s.dashOffset = dashOffset;
            return s;
        }

        public function toJSON():Object
        {
            return {
                width: width,
                cap: cap,
                join: join,
                miterLimit: miterLimit,
                dashArray: dashArray.slice(),
                dashOffset: dashOffset,
                paint: paint.toJSON()
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                if (data.width != null) width = Number(data.width);
                if (data.cap != null) cap = String(data.cap);
                if (data.join != null) join = String(data.join);
                if (data.miterLimit != null) miterLimit = Number(data.miterLimit);
                if (data.dashOffset != null) dashOffset = Number(data.dashOffset);
                if (data.dashArray is Array) dashArray = (data.dashArray as Array).slice();
            }
        }
    }
}
