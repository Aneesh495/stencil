package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * Bezier2D provides numerical evaluation for quadratic and cubic planar Bezier curves.
     * Implements Bernstein polynomial evaluation, parametric tangents, and degree elevation.
     */
    public class Bezier2D implements ICloneable, ISerializable
    {
        public var p0:Point2D;
        public var p1:Point2D;
        public var p2:Point2D;
        public var p3:Point2D; // Null for quadratic curves
        public var order:int;  // 2 for quadratic, 3 for cubic

        public function Bezier2D(p0:Point2D, p1:Point2D, p2:Point2D, p3:Point2D = null)
        {
            this.p0 = p0.clone() as Point2D;
            this.p1 = p1.clone() as Point2D;
            this.p2 = p2.clone() as Point2D;
            if (p3 != null)
            {
                this.p3 = p3.clone() as Point2D;
                this.order = 3;
            }
            else
            {
                this.p3 = null;
                this.order = 2;
            }
        }

        public static function quadratic(p0:Point2D, p1:Point2D, p2:Point2D):Bezier2D
        {
            return new Bezier2D(p0, p1, p2, null);
        }

        public static function cubic(p0:Point2D, p1:Point2D, p2:Point2D, p3:Point2D):Bezier2D
        {
            return new Bezier2D(p0, p1, p2, p3);
        }

        public function isCubic():Boolean
        {
            return order == 3;
        }

        public function isQuadratic():Boolean
        {
            return order == 2;
        }

        /**
         * Evaluates point B(t) at parameter t in [0.0, 1.0].
         */
        public function pointAt(t:Number):Point2D
        {
            var u:Number = 1.0 - t;
            if (order == 2)
            {
                // B(t) = u^2*p0 + 2*u*t*p1 + t^2*p2
                var u2:Number = u * u;
                var t2:Number = t * t;
                var ut2:Number = 2.0 * u * t;
                return new Point2D(
                    u2 * p0.x + ut2 * p1.x + t2 * p2.x,
                    u2 * p0.y + ut2 * p1.y + t2 * p2.y
                );
            }
            else
            {
                // B(t) = u^3*p0 + 3*u^2*t*p1 + 3*u*t^2*p2 + t^3*p3
                var u3:Number = u * u * u;
                var t3:Number = t * t * t;
                var c1:Number = 3.0 * u * u * t;
                var c2:Number = 3.0 * u * t * t;
                return new Point2D(
                    u3 * p0.x + c1 * p1.x + c2 * p2.x + t3 * p3.x,
                    u3 * p0.y + c1 * p1.y + c2 * p2.y + t3 * p3.y
                );
            }
        }

        /**
         * Computes first derivative vector B'(t).
         */
        public function derivative(t:Number):Vector2D
        {
            var u:Number = 1.0 - t;
            if (order == 2)
            {
                // B'(t) = 2*(1-t)*(p1 - p0) + 2*t*(p2 - p1)
                var dx:Number = 2.0 * u * (p1.x - p0.x) + 2.0 * t * (p2.x - p1.x);
                var dy:Number = 2.0 * u * (p1.y - p0.y) + 2.0 * t * (p2.y - p1.y);
                return new Vector2D(dx, dy);
            }
            else
            {
                // B'(t) = 3*(1-t)^2*(p1 - p0) + 6*(1-t)*t*(p2 - p1) + 3*t^2*(p3 - p2)
                var u2_3:Number = 3.0 * u * u;
                var ut_6:Number = 6.0 * u * t;
                var t2_3:Number = 3.0 * t * t;
                var ddx:Number = u2_3 * (p1.x - p0.x) + ut_6 * (p2.x - p1.x) + t2_3 * (p3.x - p2.x);
                var ddy:Number = u2_3 * (p1.y - p0.y) + ut_6 * (p2.y - p1.y) + t2_3 * (p3.y - p2.y);
                return new Vector2D(ddx, ddy);
            }
        }

        /**
         * Computes normalized tangent direction at parameter t.
         */
        public function tangent(t:Number):Vector2D
        {
            return derivative(t).normalize();
        }

        /**
         * Computes normalized normal vector (perpendicular left) at parameter t.
         */
        public function normal(t:Number):Vector2D
        {
            return tangent(t).perpendicularLeft();
        }

        /**
         * Elevates a quadratic curve to an equivalent cubic curve.
         */
        public function toCubic():Bezier2D
        {
            if (order == 3) return this.clone() as Bezier2D;

            // Q to C: C0 = Q0, C1 = Q0 + 2/3*(Q1 - Q0), C2 = Q2 + 2/3*(Q1 - Q2), C3 = Q2
            var c0:Point2D = p0.clone() as Point2D;
            var c1:Point2D = new Point2D(
                p0.x + (2.0 / 3.0) * (p1.x - p0.x),
                p0.y + (2.0 / 3.0) * (p1.y - p0.y)
            );
            var c2:Point2D = new Point2D(
                p2.x + (2.0 / 3.0) * (p1.x - p2.x),
                p2.y + (2.0 / 3.0) * (p1.y - p2.y)
            );
            var c3:Point2D = p2.clone() as Point2D;

            return new Bezier2D(c0, c1, c2, c3);
        }

        public function clone():Object
        {
            return new Bezier2D(p0, p1, p2, p3);
        }

        public function toJSON():Object
        {
            return {
                order: order,
                p0: p0.toJSON(),
                p1: p1.toJSON(),
                p2: p2.toJSON(),
                p3: (p3 != null) ? p3.toJSON() : null
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                order = int(data.order);
                p0.fromJSON(data.p0);
                p1.fromJSON(data.p1);
                p2.fromJSON(data.p2);
                if (data.p3 != null)
                {
                    if (p3 == null) p3 = new Point2D();
                    p3.fromJSON(data.p3);
                }
                else
                {
                    p3 = null;
                }
            }
        }
    }
}
