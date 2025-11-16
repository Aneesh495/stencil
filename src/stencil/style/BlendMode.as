package stencil.style
{
    import stencil.core.MathUtil;

    /**
     * BlendMode defines composite equations for Porter-Duff and color blending algorithms.
     */
    public class BlendMode
    {
        public static const NORMAL:String      = "normal";
        public static const MULTIPLY:String    = "multiply";
        public static const SCREEN:String      = "screen";
        public static const OVERLAY:String     = "overlay";
        public static const DARKEN:String      = "darken";
        public static const LIGHTEN:String     = "lighten";
        public static const COLOR_DODGE:String = "colorDodge";
        public static const COLOR_BURN:String  = "colorBurn";
        public static const HARD_LIGHT:String  = "hardLight";
        public static const SOFT_LIGHT:String  = "softLight";
        public static const DIFFERENCE:String  = "difference";
        public static const EXCLUSION:String   = "exclusion";

        /**
         * Blends a source color onto a destination color according to specified blend mode.
         */
        public static function blend(dst:Color, src:Color, mode:String = "normal"):Color
        {
            var sa:Number = src.alpha;
            var da:Number = dst.alpha;

            var r:Number = blendChannel(dst.red, src.red, mode);
            var g:Number = blendChannel(dst.green, src.green, mode);
            var b:Number = blendChannel(dst.blue, src.blue, mode);

            // Composite alpha: outA = sa + da*(1 - sa)
            var outA:Number = sa + da * (1.0 - sa);
            if (outA <= 0.0) return new Color(0x00000000);

            // Standard Porter-Duff source-over mixing:
            // C_out = (sa*Cs + da*(1-sa)*Cd) / outA
            var finalR:Number = (sa * r + da * (1.0 - sa) * dst.red);
            var finalG:Number = (sa * g + da * (1.0 - sa) * dst.green);
            var finalB:Number = (sa * b + da * (1.0 - sa) * dst.blue);

            return Color.fromFloats(finalR, finalG, finalB, outA);
        }

        private static function blendChannel(cb:Number, cs:Number, mode:String):Number
        {
            switch (mode)
            {
                case MULTIPLY:
                    return cb * cs;

                case SCREEN:
                    return 1.0 - (1.0 - cb) * (1.0 - cs);

                case DARKEN:
                    return Math.min(cb, cs);

                case LIGHTEN:
                    return Math.max(cb, cs);

                case OVERLAY:
                    return (cb <= 0.5) ? (2.0 * cb * cs) : (1.0 - 2.0 * (1.0 - cb) * (1.0 - cs));

                case HARD_LIGHT:
                    return (cs <= 0.5) ? (2.0 * cb * cs) : (1.0 - 2.0 * (1.0 - cb) * (1.0 - cs));

                case DIFFERENCE:
                    return Math.abs(cb - cs);

                case EXCLUSION:
                    return cb + cs - 2.0 * cb * cs;

                case NORMAL:
                default:
                    return cs;
            }
        }
    }
}
