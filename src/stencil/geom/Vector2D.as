package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * Vector2D encapsulates directional vectors, tangent velocities, and normal physics.
     */
    public class Vector2D implements ICloneable, ISerializable
    {
        public var dx:Number;
        public var dy:Number;

        public function Vector2D(dx:Number = 0.0, dy:Number = 0.0)
        {
            this.dx = dx;
            this.dy = dy;
        }

        public static function fromAngle(radians:Number, magnitude:Number = 1.0):Vector2D
        {
            return new Vector2D(Math.cos(radians) * magnitude, Math.sin(radians) * magnitude);
        }

        public static function fromPoints(from:Point2D, to:Point2D):Vector2D
        {
            return new Vector2D(to.x - from.x, to.y - from.y);
        }

        public function get angle():Number
        {
            return Math.atan2(dy, dx);
        }

        public function set angle(radians:Number):void
        {
            var len:Number = magnitude;
            this.dx = Math.cos(radians) * len;
            this.dy = Math.sin(radians) * len;
        }

        public function get magnitude():Number
        {
            return Math.sqrt(dx * dx + dy * dy);
        }

        public function set magnitude(len:Number):void
        {
            var currentAngle:Number = angle;
            this.dx = Math.cos(currentAngle) * len;
            this.dy = Math.sin(currentAngle) * len;
        }

        public function get magnitudeSquared():Number
        {
            return dx * dx + dy * dy;
        }

        public function normalize():Vector2D
        {
            var len:Number = magnitude;
            if (MathUtil.fuzzyZero(len))
            {
                return new Vector2D(0.0, 0.0);
            }
            return new Vector2D(dx / len, dy / len);
        }

        public function perpendicularLeft():Vector2D
        {
            return new Vector2D(-dy, dx);
        }

        public function perpendicularRight():Vector2D
        {
            return new Vector2D(dy, -dx);
        }

        public function dot(other:Vector2D):Number
        {
            return this.dx * other.dx + this.dy * other.dy;
        }

        public function cross(other:Vector2D):Number
        {
            return this.dx * other.dy - this.dy * other.dx;
        }

        public function angleBetween(other:Vector2D):Number
        {
            var dotVal:Number = dot(other);
            var lenProduct:Number = magnitude * other.magnitude;
            if (MathUtil.fuzzyZero(lenProduct))
            {
                return 0.0;
            }
            var cosTheta:Number = MathUtil.clamp(dotVal / lenProduct, -1.0, 1.0);
            return Math.acos(cosTheta);
        }

        /**
         * Reflects this vector across a surface normal.
         * R = V - 2 * (V . N) * N
         */
        public function reflect(normal:Vector2D):Vector2D
        {
            var n:Vector2D = normal.normalize();
            var d:Number = 2.0 * this.dot(n);
            return new Vector2D(this.dx - d * n.dx, this.dy - d * n.dy);
        }

        /**
         * Projects this vector onto target axis vector.
         */
        public function project(target:Vector2D):Vector2D
        {
            var lenSq:Number = target.magnitudeSquared;
            if (MathUtil.fuzzyZero(lenSq))
            {
                return new Vector2D(0.0, 0.0);
            }
            var scalar:Number = this.dot(target) / lenSq;
            return new Vector2D(target.dx * scalar, target.dy * scalar);
        }

        public function clampMagnitude(maxLen:Number):Vector2D
        {
            var currentLenSq:Number = magnitudeSquared;
            if (currentLenSq > maxLen * maxLen && currentLenSq > 0)
            {
                var factor:Number = maxLen / Math.sqrt(currentLenSq);
                return new Vector2D(this.dx * factor, this.dy * factor);
            }
            return new Vector2D(this.dx, this.dy);
        }

        public function clone():Object
        {
            return new Vector2D(this.dx, this.dy);
        }

        public function toJSON():Object
        {
            return { dx: this.dx, dy: this.dy };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                this.dx = Number(data.dx);
                this.dy = Number(data.dy);
            }
        }

        public function toString():String
        {
            return "Vector2D(" + MathUtil.roundTo(this.dx, 3) + ", " + MathUtil.roundTo(this.dy, 3) + ")";
        }
    }
}
