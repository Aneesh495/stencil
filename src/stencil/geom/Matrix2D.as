package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * 3x3 Affine transformation matrix in 2D Cartesian space.
     * Represented as:
     * [ a   c   tx ]
     * [ b   d   ty ]
     * [ 0   0   1  ]
     */
    public class Matrix2D implements ICloneable, ISerializable
    {
        public var a:Number;  // Scale X
        public var b:Number;  // Shear Y
        public var c:Number;  // Shear X
        public var d:Number;  // Scale Y
        public var tx:Number; // Translate X
        public var ty:Number; // Translate Y

        public function Matrix2D(
            a:Number = 1.0,
            b:Number = 0.0,
            c:Number = 0.0,
            d:Number = 1.0,
            tx:Number = 0.0,
            ty:Number = 0.0
        )
        {
            this.a = a;
            this.b = b;
            this.c = c;
            this.d = d;
            this.tx = tx;
            this.ty = ty;
        }

        public static function identity():Matrix2D
        {
            return new Matrix2D(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
        }

        public static function translation(tx:Number, ty:Number):Matrix2D
        {
            return new Matrix2D(1.0, 0.0, 0.0, 1.0, tx, ty);
        }

        public static function scaling(sx:Number, sy:Number):Matrix2D
        {
            return new Matrix2D(sx, 0.0, 0.0, sy, 0.0, 0.0);
        }

        public static function rotation(radians:Number):Matrix2D
        {
            var cosA:Number = Math.cos(radians);
            var sinA:Number = Math.sin(radians);
            return new Matrix2D(cosA, sinA, -sinA, cosA, 0.0, 0.0);
        }

        public static function skew(skewX:Number, skewY:Number):Matrix2D
        {
            return new Matrix2D(1.0, Math.tan(skewY), Math.tan(skewX), 1.0, 0.0, 0.0);
        }

        public function setIdentity():Matrix2D
        {
            this.a = 1.0;
            this.b = 0.0;
            this.c = 0.0;
            this.d = 1.0;
            this.tx = 0.0;
            this.ty = 0.0;
            return this;
        }

        public function translate(dx:Number, dy:Number):Matrix2D
        {
            this.tx += dx;
            this.ty += dy;
            return this;
        }

        public function scale(sx:Number, sy:Number):Matrix2D
        {
            this.a *= sx;
            this.b *= sx;
            this.c *= sy;
            this.d *= sy;
            return this;
        }

        public function rotate(radians:Number):Matrix2D
        {
            var cosA:Number = Math.cos(radians);
            var sinA:Number = Math.sin(radians);

            var a1:Number = this.a * cosA - this.b * sinA;
            var b1:Number = this.a * sinA + this.b * cosA;
            var c1:Number = this.c * cosA - this.d * sinA;
            var d1:Number = this.c * sinA + this.d * cosA;

            this.a = a1;
            this.b = b1;
            this.c = c1;
            this.d = d1;
            return this;
        }

        /**
         * Concatenates another matrix to the right of this matrix: This = This * M.
         */
        public function concat(m:Matrix2D):Matrix2D
        {
            var a1:Number = this.a * m.a + this.c * m.b;
            var b1:Number = this.b * m.a + this.d * m.b;
            var c1:Number = this.a * m.c + this.c * m.d;
            var d1:Number = this.b * m.c + this.d * m.d;
            var tx1:Number = this.a * m.tx + this.c * m.ty + this.tx;
            var ty1:Number = this.b * m.tx + this.d * m.ty + this.ty;

            this.a = a1;
            this.b = b1;
            this.c = c1;
            this.d = d1;
            this.tx = tx1;
            this.ty = ty1;
            return this;
        }

        /**
         * Multiplies two matrices and returns a new Matrix2D.
         */
        public function multiply(other:Matrix2D):Matrix2D
        {
            var res:Matrix2D = this.clone() as Matrix2D;
            return res.concat(other);
        }

        /**
         * Computes determinant: a*d - b*c.
         */
        public function determinant():Number
        {
            return this.a * this.d - this.b * this.c;
        }

        /**
         * Inverts the affine matrix in place.
         */
        public function invert():Matrix2D
        {
            var det:Number = determinant();
            if (MathUtil.fuzzyZero(det))
            {
                // Singular matrix: fallback to identity
                return setIdentity();
            }

            var invDet:Number = 1.0 / det;

            var a1:Number = this.d * invDet;
            var b1:Number = -this.b * invDet;
            var c1:Number = -this.c * invDet;
            var d1:Number = this.a * invDet;
            var tx1:Number = (this.c * this.ty - this.d * this.tx) * invDet;
            var ty1:Number = (this.b * this.tx - this.a * this.ty) * invDet;

            this.a = a1;
            this.b = b1;
            this.c = c1;
            this.d = d1;
            this.tx = tx1;
            this.ty = ty1;
            return this;
        }

        public function getInverse():Matrix2D
        {
            var m:Matrix2D = this.clone() as Matrix2D;
            return m.invert();
        }

        /**
         * Transforms a 2D point: [x', y'] = [x, y, 1] * M.
         */
        public function transformPoint(p:Point2D):Point2D
        {
            return new Point2D(
                this.a * p.x + this.c * p.y + this.tx,
                this.b * p.x + this.d * p.y + this.ty
            );
        }

        /**
         * Decomposes matrix into translation, scale, rotation, and skew components.
         */
        public function decompose():Object
        {
            var translation:Point2D = new Point2D(this.tx, this.ty);
            var scaleX:Number = Math.sqrt(this.a * this.a + this.b * this.b);
            var scaleY:Number = Math.sqrt(this.c * this.c + this.d * this.d);

            var rotation:Number = Math.atan2(this.b, this.a);

            // Check reflection / negative determinant
            var det:Number = determinant();
            if (det < 0)
            {
                scaleY = -scaleY;
            }

            var skewX:Number = Math.atan2(this.a * this.c + this.b * this.d, scaleX * scaleX);

            return {
                translation: translation,
                scale: new Point2D(scaleX, scaleY),
                rotation: rotation,
                skew: new Point2D(skewX, 0.0)
            };
        }

        public function clone():Object
        {
            return new Matrix2D(this.a, this.b, this.c, this.d, this.tx, this.ty);
        }

        public function toJSON():Object
        {
            return {
                a: this.a,
                b: this.b,
                c: this.c,
                d: this.d,
                tx: this.tx,
                ty: this.ty
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                this.a = Number(data.a);
                this.b = Number(data.b);
                this.c = Number(data.c);
                this.d = Number(data.d);
                this.tx = Number(data.tx);
                this.ty = Number(data.ty);
            }
        }

        public function toString():String
        {
            return "Matrix2D([" +
                   MathUtil.roundTo(a, 3) + ", " + MathUtil.roundTo(c, 3) + ", " + MathUtil.roundTo(tx, 3) + "; " +
                   MathUtil.roundTo(b, 3) + ", " + MathUtil.roundTo(d, 3) + ", " + MathUtil.roundTo(ty, 3) + "])";
        }
    }
}
