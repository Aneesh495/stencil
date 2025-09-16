package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * 2D Axis-Aligned Bounding Box (AABB).
     * Used for spatial tree indexing, dirty region culling, and hit testing.
     */
    public class Rect2D implements ICloneable, ISerializable
    {
        public var x:Number;
        public var y:Number;
        public var width:Number;
        public var height:Number;

        public function Rect2D(x:Number = 0.0, y:Number = 0.0, width:Number = 0.0, height:Number = 0.0)
        {
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }

        public static function fromBounds(left:Number, top:Number, right:Number, bottom:Number):Rect2D
        {
            var minX:Number = Math.min(left, right);
            var maxX:Number = Math.max(left, right);
            var minY:Number = Math.min(top, bottom);
            var maxY:Number = Math.max(top, bottom);
            return new Rect2D(minX, minY, maxX - minX, maxY - minY);
        }

        public static function fromPoints(p1:Point2D, p2:Point2D):Rect2D
        {
            return fromBounds(p1.x, p1.y, p2.x, p2.y);
        }

        public function get left():Number { return x; }
        public function set left(val:Number):void { width += (x - val); x = val; }

        public function get right():Number { return x + width; }
        public function set right(val:Number):void { width = val - x; }

        public function get top():Number { return y; }
        public function set top(val:Number):void { height += (y - val); y = val; }

        public function get bottom():Number { return y + height; }
        public function set bottom(val:Number):void { height = val - y; }

        public function get centerX():Number { return x + width * 0.5; }
        public function get centerY():Number { return y + height * 0.5; }
        public function get center():Point2D { return new Point2D(centerX, centerY); }

        public function isEmpty():Boolean
        {
            return width <= 0.0 || height <= 0.0;
        }

        public function area():Number
        {
            if (isEmpty()) return 0.0;
            return width * height;
        }

        public function containsPoint(p:Point2D):Boolean
        {
            return p.x >= x && p.x <= (x + width) &&
                   p.y >= y && p.y <= (y + height);
        }

        public function containsRect(other:Rect2D):Boolean
        {
            if (other.isEmpty()) return true;
            return other.left >= left && other.right <= right &&
                   other.top >= top && other.bottom <= bottom;
        }

        public function intersects(other:Rect2D):Boolean
        {
            if (isEmpty() || other.isEmpty()) return false;
            return !(other.left > right || other.right < left ||
                     other.top > bottom || other.bottom < top);
        }

        public function intersection(other:Rect2D):Rect2D
        {
            if (!intersects(other))
            {
                return new Rect2D(0.0, 0.0, 0.0, 0.0);
            }

            var l:Number = Math.max(left, other.left);
            var t:Number = Math.max(top, other.top);
            var r:Number = Math.min(right, other.right);
            var b:Number = Math.min(bottom, other.bottom);

            return new Rect2D(l, t, r - l, b - t);
        }

        public function union(other:Rect2D):Rect2D
        {
            if (isEmpty()) return other.clone() as Rect2D;
            if (other.isEmpty()) return this.clone() as Rect2D;

            var l:Number = Math.min(left, other.left);
            var t:Number = Math.min(top, other.top);
            var r:Number = Math.max(right, other.right);
            var b:Number = Math.max(bottom, other.bottom);

            return new Rect2D(l, t, r - l, b - t);
        }

        public function unionPoint(p:Point2D):void
        {
            if (isEmpty())
            {
                x = p.x;
                y = p.y;
                width = 0.0;
                height = 0.0;
                return;
            }

            var l:Number = Math.min(left, p.x);
            var t:Number = Math.min(top, p.y);
            var r:Number = Math.max(right, p.x);
            var b:Number = Math.max(bottom, p.y);

            x = l;
            y = t;
            width = r - l;
            height = b - t;
        }

        public function inflate(dx:Number, dy:Number):Rect2D
        {
            return new Rect2D(x - dx, y - dy, width + 2.0 * dx, height + 2.0 * dy);
        }

        public function inset(dx:Number, dy:Number):Rect2D
        {
            return inflate(-dx, -dy);
        }

        public function clone():Object
        {
            return new Rect2D(x, y, width, height);
        }

        public function toJSON():Object
        {
            return { x: x, y: y, width: width, height: height };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                x = Number(data.x);
                y = Number(data.y);
                width = Number(data.width);
                height = Number(data.height);
            }
        }

        public function toString():String
        {
            return "Rect2D(" + MathUtil.roundTo(x, 2) + ", " + MathUtil.roundTo(y, 2) + ", " +
                   MathUtil.roundTo(width, 2) + ", " + MathUtil.roundTo(height, 2) + ")";
        }
    }
}
