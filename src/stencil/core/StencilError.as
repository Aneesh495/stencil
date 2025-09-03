package stencil.core
{
    /**
     * StencilError represents structured, classified diagnostic failures across the Stencil pipeline.
     */
    public class StencilError extends Error
    {
        public static const CATEGORY_GENERAL:String = "GENERAL";
        public static const CATEGORY_GEOMETRY:String = "GEOMETRY";
        public static const CATEGORY_SCENE:String = "SCENE";
        public static const CATEGORY_LAYOUT:String = "LAYOUT";
        public static const CATEGORY_TYPOGRAPHY:String = "TYPOGRAPHY";
        public static const CATEGORY_CRDT:String = "CRDT";
        public static const CATEGORY_FORMAT:String = "FORMAT";
        public static const CATEGORY_RASTER:String = "RASTER";

        protected var _category:String;
        protected var _code:int;
        protected var _details:Object;

        /**
         * Constructs a classified StencilError.
         * 
         * @param message Diagnostic narrative.
         * @param category Classification domain code.
         * @param code Numeric error identification.
         * @param details Additional context payload.
         */
        public function StencilError(
            message:String = "",
            category:String = "GENERAL",
            code:int = 0,
            details:Object = null
        )
        {
            super(message, code);
            _category = category;
            _code = code;
            _details = (details != null) ? details : {};
        }

        public function get category():String
        {
            return _category;
        }

        public function get code():int
        {
            return _code;
        }

        public function get details():Object
        {
            return _details;
        }

        public function getDetail(key:String, defaultVal:Object = null):Object
        {
            if (_details != null && _details.hasOwnProperty(key))
            {
                return _details[key];
            }
            return defaultVal;
        }

        public function toString():String
        {
            return "[StencilError category=" + _category +
                   " code=" + _code +
                   " message=" + message + "]";
        }
    }
}
