package stencil.core
{
    /**
     * Base event class representing state transitions and interactive notifications in Stencil.
     */
    public class Event
    {
        public static const CHANGE:String = "change";
        public static const UPDATE:String = "update";
        public static const DISPOSE:String = "dispose";
        public static const RENDER:String = "render";
        public static const RESIZE:String = "resize";

        protected var _type:String;
        protected var _target:Object;
        protected var _currentTarget:Object;
        protected var _bubbles:Boolean;
        protected var _cancelable:Boolean;
        protected var _defaultPrevented:Boolean;
        protected var _propagationStopped:Boolean;
        protected var _timestamp:Number;

        /**
         * Constructs an Event instance.
         * 
         * @param type Event identifier string.
         * @param bubbles Whether the event propagates up hierarchy trees.
         * @param cancelable Whether preventDefault can cancel default actions.
         */
        public function Event(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            _type = type;
            _bubbles = bubbles;
            _cancelable = cancelable;
            _defaultPrevented = false;
            _propagationStopped = false;
            _timestamp = new Date().time;
        }

        public function get type():String
        {
            return _type;
        }

        public function get target():Object
        {
            return _target;
        }

        public function set target(value:Object):void
        {
            _target = value;
        }

        public function get currentTarget():Object
        {
            return _currentTarget;
        }

        public function set currentTarget(value:Object):void
        {
            _currentTarget = value;
        }

        public function get bubbles():Boolean
        {
            return _bubbles;
        }

        public function get cancelable():Boolean
        {
            return _cancelable;
        }

        public function get isDefaultPrevented():Boolean
        {
            return _defaultPrevented;
        }

        public function get isPropagationStopped():Boolean
        {
            return _propagationStopped;
        }

        public function get timestamp():Number
        {
            return _timestamp;
        }

        public function preventDefault():void
        {
            if (_cancelable)
            {
                _defaultPrevented = true;
            }
        }

        public function stopPropagation():void
        {
            _propagationStopped = true;
        }

        public function clone():Event
        {
            var e:Event = new Event(_type, _bubbles, _cancelable);
            e.target = _target;
            e.currentTarget = _currentTarget;
            return e;
        }

        public function toString():String
        {
            return "[Event type=" + _type + " bubbles=" + _bubbles + " cancelable=" + _cancelable + "]";
        }
    }
}
