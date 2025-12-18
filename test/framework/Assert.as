package test.framework
{
    import stencil.core.MathUtil;
    import stencil.core.StencilError;

    /**
     * Assertion utilities for automated testing of the Stencil ActionScript engine.
     */
    public class Assert
    {
        public static function isTrue(condition:Boolean, message:String = ""):void
        {
            if (!condition)
            {
                throw new StencilError("Assertion failed: expected true, got false. " + message);
            }
        }

        public static function isFalse(condition:Boolean, message:String = ""):void
        {
            if (condition)
            {
                throw new StencilError("Assertion failed: expected false, got true. " + message);
            }
        }

        public static function equals(expected:Object, actual:Object, message:String = ""):void
        {
            if (expected !== actual)
            {
                throw new StencilError("Assertion failed: expected [" + expected + "], got [" + actual + "]. " + message);
            }
        }

        public static function fuzzyEquals(expected:Number, actual:Number, tolerance:Number = 1e-4, message:String = ""):void
        {
            if (!MathUtil.fuzzyEqual(expected, actual, tolerance))
            {
                throw new StencilError("Assertion failed: expected [" + expected + "] approx equal to [" + actual + "] within " + tolerance + ". " + message);
            }
        }

        public static function notNull(val:Object, message:String = ""):void
        {
            if (val == null)
            {
                throw new StencilError("Assertion failed: expected non-null value. " + message);
            }
        }

        public static function isNull(val:Object, message:String = ""):void
        {
            if (val != null)
            {
                throw new StencilError("Assertion failed: expected null value, got [" + val + "]. " + message);
            }
        }

        public static function throwsError(func:Function, message:String = ""):void
        {
            var threw:Boolean = false;
            try
            {
                func();
            }
            catch (e:Error)
            {
                threw = true;
            }
            if (!threw)
            {
                throw new StencilError("Assertion failed: expected function to throw error. " + message);
            }
        }
    }
}
