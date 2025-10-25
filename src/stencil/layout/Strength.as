package stencil.layout
{
    /**
     * Strength hierarchy for Cassowary constraint prioritization.
     * Expressed as symbolic weights driving the multi-priority simplex objective function.
     */
    public class Strength
    {
        public static const REQUIRED:Number = 1000000000.0;
        public static const STRONG:Number   = 1000000.0;
        public static const MEDIUM:Number   = 1000.0;
        public static const WEAK:Number     = 1.0;

        public static function create(a:Number, b:Number, c:Number):Number
        {
            return a * STRONG + b * MEDIUM + c * WEAK;
        }
    }
}
