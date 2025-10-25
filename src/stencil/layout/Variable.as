package stencil.layout
{
    /**
     * Variable represents an unknown scalar quantity in the Cassowary constraint system.
     * Classified into external domain variables, slack/surplus variables, and artificial/error variables.
     */
    public class Variable
    {
        private static var _idCounter:int = 0;

        protected var _id:int;
        protected var _name:String;
        public var value:Number;

        public var isExternal:Boolean;
        public var isSlack:Boolean;
        public var isError:Boolean;
        public var isDummy:Boolean;

        public function Variable(name:String = "", value:Number = 0.0)
        {
            _id = ++_idCounter;
            _name = (name != null && name.length > 0) ? name : ("v" + _id);
            this.value = value;

            isExternal = true;
            isSlack = false;
            isError = false;
            isDummy = false;
        }

        public function get id():int { return _id; }
        public function get name():String { return _name; }

        public static function createSlack(prefix:String = "s"):Variable
        {
            var v:Variable = new Variable(prefix + "_" + (++_idCounter));
            v.isExternal = false;
            v.isSlack = true;
            return v;
        }

        public static function createError(prefix:String = "e"):Variable
        {
            var v:Variable = new Variable(prefix + "_" + (++_idCounter));
            v.isExternal = false;
            v.isError = true;
            return v;
        }

        public static function createDummy(prefix:String = "d"):Variable
        {
            var v:Variable = new Variable(prefix + "_" + (++_idCounter));
            v.isExternal = false;
            v.isDummy = true;
            return v;
        }

        public function toString():String
        {
            return _name + "[" + value + "]";
        }
    }
}
