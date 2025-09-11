package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * Immutable-friendly 2D Cartesian coordinate point.
     * Core primitive for vector path geometry, transform vertices, and layout coordinates.
     */
    public class Point2D implements ICloneable, ISerializable
    {
        public var x:Number;
        public var y:Number;

        public function Point2D(x:Number = 0.0, y:Number = 0.0)
        {
            this.x = x;
            this.y = y;
        }

        public function set(newX:Number, newY:Number):Point2D
        {
            this.x = newX;
            this.y = newY;
            return this;
        }

        public function copyFrom(other:Point2D):Point2D
        {
            if (other != null)
            {
                this.x = other.x;
                this.y = other.y;
            }
            return this;
        }

        public function add(other:Point2D):Point2D
        {
            return new Point2D(this.x + other.x, this.y + other.y);
        }

        public function subtract(other:Point2D):Point2D
        {
            return new Point2D(this.x - other.x, this.y - other.y);
        }

        public function multiply(scalar:Number):Point2D
        {
            return new Point2D(this.x * scalar, this.y * scalar);
        }

        public function divide(scalar:Number):Point2D
        {
            if (MathUtil.fuzzyZero(scalar))
            {
                return new Point2D(0.0, 0.0);
            }
            return new Point2D(this.x / scalar, this.y / scalar);
        }

        public function negate():Point2D
        {
            return new Point2D(-this.x, -this.y);
        }

        public function dot(other:Point2D):Number
        {
            return this.x * other.x + this.y * other.y;
        }

        public function cross(other:Point2D):Number
        {
            return this.x * other.y - this.y * other.x;
        }

        public function length():Number
        {
            return Math.sqrt(this.x * this.x + this.y * this.y);
        }

        public function lengthSquared():Number
        {
            return this.x * this.x + this.y * this.y;
        }

        public function normalize():Point2D
        {
            var len:Number = length();
            if (MathUtil.fuzzyZero(len))
            {
                return new Point2D(0.0, 0.0);
            }
            return new Point2D(this.x / len, this.y / len);
        }

        public function distanceTo(other:Point2D):Number
        {
            var dx:Number = this.x - other.x;
            var dy:Number = this.y - other.y;
            return Math.sqrt(dx * dx + dy * dy);
        }

        public function distanceSquaredTo(other:Point2D):Number
        {
            var dx:Number = this.x - other.x;
            var dy:Number = this.y - other.y;
            return dx * dx + dy * dy;
        }

        public function angleTo(other:Point2D):Number
        {
            return Math.atan2(other.y - this.y, other.x - this.x);
        }

        public function midpoint(other:Point2D):Point2D
        {
            return new Point2D((this.x + other.x) * 0.5, (this.y + other.y) * 0.5);
        }

        public function lerp(other:Point2D, t:Number):Point2D
        {
            return new Point2D(
                MathUtil.lerp(this.x, other.x, t),
                MathUtil.lerp(this.y, other.y, t)
            );
        }

        public function rotateAround(origin:Point2D, radians:Number):Point2D
        {
            var cosA:Number = Math.cos(radians);
            var sinA:Number = Math.sin(radians);
            var dx:Number = this.x - origin.x;
            var dy:Number = this.y - origin.y;

            return new Point2D(
                origin.x + (dx * cosA - dy * sinA),
                origin.y + (dx * sinA + dy * cosA)
            );
        }

        public function fuzzyEquals(other:Point2D, tolerance:Number = 1e-9):Boolean
        {
            if (other == null) return false;
            return MathUtil.fuzzyEqual(this.x, other.x, tolerance) &&
                   MathUtil.fuzzyEqual(this.y, other.y, tolerance);
        }

        public function clone():Object
        {
            return new Point2D(this.x, this.y);
        }

        public function toJSON():Object
        {
            return { x: this.x, y: this.y };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                this.x = Number(data.x);
                this.y = Number(data.y);
            }
        }

        public function toString():String
        {
            return "Point2D(" + MathUtil.roundTo(this.x, 3) + ", " + MathUtil.roundTo(this.y, 3) + ")";
        }
    }
}
