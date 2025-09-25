package stencil.geom
{
    /**
     * Enumeration of vector path primitive command types.
     */
    public class PathCommand
    {
        public static const MOVE_TO:int = 1;
        public static const LINE_TO:int = 2;
        public static const CURVE_TO:int = 3;  // Quadratic Bezier
        public static const CUBIC_TO:int = 4;  // Cubic Bezier
        public static const ARC_TO:int = 5;    // Elliptical arc
        public static const CLOSE:int = 6;     // Closes current contour

        public static function toString(cmd:int):String
        {
            switch (cmd)
            {
                case MOVE_TO: return "MOVE_TO";
                case LINE_TO: return "LINE_TO";
                case CURVE_TO: return "CURVE_TO";
                case CUBIC_TO: return "CUBIC_TO";
                case ARC_TO: return "ARC_TO";
                case CLOSE: return "CLOSE";
                default: return "UNKNOWN";
            }
        }
    }
}
