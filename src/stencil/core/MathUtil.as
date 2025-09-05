package stencil.core
{
    /**
     * High performance numerical and geometric utilities.
     * Provides stable floating point comparisons, root solving, and angular transformations.
     */
    public class MathUtil
    {
        public static const EPSILON:Number = 1e-9;
        public static const PI:Number = 3.14159265358979323846;
        public static const TWO_PI:Number = 6.28318530717958647692;
        public static const HALF_PI:Number = 1.57079632679489661923;
        public static const DEG2RAD:Number = 0.017453292519943295; // PI / 180
        public static const RAD2DEG:Number = 57.29577951308232;    // 180 / PI

        /**
         * Floating point equality check within default or specified tolerance.
         */
        public static function fuzzyEqual(a:Number, b:Number, tolerance:Number = 1e-9):Boolean
        {
            var diff:Number = a - b;
            return (diff < 0 ? -diff : diff) <= tolerance;
        }

        /**
         * Floating point zero check.
         */
        public static function fuzzyZero(val:Number, tolerance:Number = 1e-9):Boolean
        {
            return (val < 0 ? -val : val) <= tolerance;
        }

        /**
         * Clamps a value within inclusive lower and upper bounds.
         */
        public static function clamp(val:Number, min:Number, max:Number):Number
        {
            if (val < min) return min;
            if (val > max) return max;
            return val;
        }

        /**
         * Linear interpolation between two scalars.
         */
        public static function lerp(a:Number, b:Number, t:Number):Number
        {
            return a + (b - a) * t;
        }

        /**
         * Hermite smoothstep interpolation between edge0 and edge1.
         */
        public static function smoothstep(edge0:Number, edge1:Number, x:Number):Number
        {
            var t:Number = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
            return t * t * (3.0 - 2.0 * t);
        }

        /**
         * Converts degrees to radians.
         */
        public static function degToRad(degrees:Number):Number
        {
            return degrees * DEG2RAD;
        }

        /**
         * Converts radians to degrees.
         */
        public static function radToDeg(radians:Number):Number
        {
            return radians * RAD2DEG;
        }

        /**
         * Normalizes an angle in radians to the range [0, 2*PI).
         */
        public static function normalizeAngle(radians:Number):Number
        {
            radians = radians % TWO_PI;
            if (radians < 0)
            {
                radians += TWO_PI;
            }
            return radians;
        }

        /**
         * Snaps a scalar value to the nearest increment.
         */
        public static function snap(val:Number, step:Number):Number
        {
            if (step <= 0) return val;
            return Math.round(val / step) * step;
        }

        /**
         * Rounds a value to a fixed number of decimal digits.
         */
        public static function roundTo(val:Number, decimals:int = 4):Number
        {
            var p:Number = Math.pow(10, decimals);
            return Math.round(val * p) / p;
        }

        /**
         * Euclidean 2D distance helper: sqrt(x*x + y*y).
         */
        public static function hypot(x:Number, y:Number):Number
        {
            return Math.sqrt(x * x + y * y);
        }

        /**
         * Extracts sign of scalar (-1, 0, or 1).
         */
        public static function sign(val:Number):int
        {
            if (val > 0) return 1;
            if (val < 0) return -1;
            return 0;
        }

        /**
         * Solves quadratic equation: a*t^2 + b*t + c = 0.
         * Returns an array of real roots.
         */
        public static function solveQuadratic(a:Number, b:Number, c:Number):Array
        {
            var roots:Array = [];
            if (fuzzyZero(a))
            {
                if (!fuzzyZero(b))
                {
                    roots.push(-c / b);
                }
                return roots;
            }

            var discriminant:Number = b * b - 4.0 * a * c;
            if (fuzzyZero(discriminant))
            {
                roots.push(-b / (2.0 * a));
            }
            else if (discriminant > 0)
            {
                var sqrtD:Number = Math.sqrt(discriminant);
                roots.push((-b - sqrtD) / (2.0 * a));
                roots.push((-b + sqrtD) / (2.0 * a));
            }
            return roots;
        }

        /**
         * Solves cubic equation: a*t^3 + b*t^2 + c*t + d = 0 using Cardano's method.
         * Returns an array of unique real roots.
         */
        public static function solveCubic(a:Number, b:Number, c:Number, d:Number):Array
        {
            if (fuzzyZero(a))
            {
                return solveQuadratic(b, c, d);
            }

            var roots:Array = [];
            // Normalize: t^3 + A*t^2 + B*t + C = 0
            var A:Number = b / a;
            var B:Number = c / a;
            var C:Number = d / a;

            // Substitute t = y - A/3 -> y^3 + p*y + q = 0
            var p:Number = B - (A * A) / 3.0;
            var q:Number = (2.0 * A * A * A) / 27.0 - (A * B) / 3.0 + C;

            var halfQ:Number = q / 2.0;
            var thirdP:Number = p / 3.0;
            var disc:Number = halfQ * halfQ + thirdP * thirdP * thirdP;

            var shift:Number = A / 3.0;

            if (fuzzyZero(disc))
            {
                if (fuzzyZero(halfQ))
                {
                    roots.push(-shift);
                }
                else
                {
                    var u:Number = Math.cbrt ? Math.cbrt(-halfQ) : Math.pow(Math.abs(-halfQ), 1.0/3.0) * sign(-halfQ);
                    roots.push(2.0 * u - shift);
                    roots.push(-u - shift);
                }
            }
            else if (disc > 0)
            {
                var sqrtDisc:Number = Math.sqrt(disc);
                var u1:Number = -halfQ + sqrtDisc;
                var u2:Number = -halfQ - sqrtDisc;
                var root1:Number = (u1 >= 0 ? Math.pow(u1, 1.0/3.0) : -Math.pow(-u1, 1.0/3.0)) +
                                  (u2 >= 0 ? Math.pow(u2, 1.0/3.0) : -Math.pow(-u2, 1.0/3.0));
                roots.push(root1 - shift);
            }
            else
            {
                // Three distinct real roots (casus irreducibilis)
                var phi:Number = Math.acos(-halfQ / Math.sqrt(-(thirdP * thirdP * thirdP)));
                var t0:Number = 2.0 * Math.sqrt(-thirdP);
                roots.push(t0 * Math.cos(phi / 3.0) - shift);
                roots.push(t0 * Math.cos((phi + TWO_PI) / 3.0) - shift);
                roots.push(t0 * Math.cos((phi + 2.0 * TWO_PI) / 3.0) - shift);
            }

            return roots;
        }
    }
}
