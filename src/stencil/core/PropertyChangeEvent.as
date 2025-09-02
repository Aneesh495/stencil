package stencil.core
{
    /**
     * PropertyChangeEvent encapsulates detailed mutation payloads for reactive data bindings,
     * undo-redo capture, and dirty-region invalidation.
     */
    public class PropertyChangeEvent extends Event
    {
        public static const PROPERTY_CHANGE:String = "propertyChange";

        protected var _propertyName:String;
        protected var _oldValue:Object;
        protected var _newValue:Object;

        /**
         * Creates a new PropertyChangeEvent.
         * 
         * @param propertyName The identifier of the mutated field.
         * @param oldValue Previous state before mutation.
         * @param newValue Current state after mutation.
         * @param bubbles Whether the event bubbles up the scene tree.
         * @param cancelable Whether the mutation event can be canceled.
         */
        public function PropertyChangeEvent(
            propertyName:String,
            oldValue:Object,
            newValue:Object,
            bubbles:Boolean = false,
            cancelable:Boolean = false
        )
        {
            super(PROPERTY_CHANGE, bubbles, cancelable);
            _propertyName = propertyName;
            _oldValue = oldValue;
            _newValue = newValue;
        }

        public function get propertyName():String
        {
            return _propertyName;
        }

        public function get oldValue():Object
        {
            return _oldValue;
        }

        public function get newValue():Object
        {
            return _newValue;
        }

        override public function clone():Event
        {
            var e:PropertyChangeEvent = new PropertyChangeEvent(
                _propertyName,
                _oldValue,
                _newValue,
                _bubbles,
                _cancelable
            );
            e.target = _target;
            e.currentTarget = _currentTarget;
            return e;
        }

        override public function toString():String
        {
            return "[PropertyChangeEvent prop=" + _propertyName +
                   " old=" + _oldValue +
                   " new=" + _newValue + "]";
        }
    }
}
