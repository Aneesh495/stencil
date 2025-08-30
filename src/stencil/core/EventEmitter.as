package stencil.core
{
    /**
     * High performance typed event dispatcher.
     * Supports priority-ordered listeners, one-shot subscriptions, and fast traversal.
     */
    public class EventEmitter implements IDisposable
    {
        private var _listeners:Object;
        private var _target:Object;
        private var _disposed:Boolean;

        public function EventEmitter(target:Object = null)
        {
            _listeners = {};
            _target = (target != null) ? target : this;
            _disposed = false;
        }

        public function get isDisposed():Boolean
        {
            return _disposed;
        }

        /**
         * Subscribes an event listener callback.
         * 
         * @param type Event name string.
         * @param listener Callback function receiving an Event parameter.
         * @param priority Higher priority listeners fire first (default 0).
         * @param once If true, automatically unbinds after first invocation.
         */
        public function addEventListener(type:String, listener:Function, priority:int = 0, once:Boolean = false):void
        {
            if (_disposed || type == null || listener == null) return;

            if (!_listeners.hasOwnProperty(type))
            {
                _listeners[type] = [];
            }

            var list:Array = _listeners[type];
            // Prevent duplicate listener registration
            for (var i:int = 0; i < list.length; i++)
            {
                if (list[i].listener === listener)
                {
                    return;
                }
            }

            var entry:Object = {
                listener: listener,
                priority: priority,
                once: once
            };

            // Insert sorted by descending priority
            var inserted:Boolean = false;
            for (var j:int = 0; j < list.length; j++)
            {
                if (priority > list[j].priority)
                {
                    list.splice(j, 0, entry);
                    inserted = true;
                    break;
                }
            }
            if (!inserted)
            {
                list.push(entry);
            }
        }

        /**
         * Unsubscribes an event listener callback.
         */
        public function removeEventListener(type:String, listener:Function):Boolean
        {
            if (_disposed || !_listeners.hasOwnProperty(type) || listener == null) return false;

            var list:Array = _listeners[type];
            for (var i:int = 0; i < list.length; i++)
            {
                if (list[i].listener === listener)
                {
                    list.splice(i, 1);
                    if (list.length == 0)
                    {
                        delete _listeners[type];
                    }
                    return true;
                }
            }
            return false;
        }

        /**
         * Checks whether any listeners are registered for an event type.
         */
        public function hasEventListener(type:String):Boolean
        {
            return _listeners.hasOwnProperty(type) && _listeners[type].length > 0;
        }

        /**
         * Dispatches an event to all registered listeners.
         * 
         * @param event The Event to dispatch.
         * @return True if event was dispatched and default action was not prevented.
         */
        public function dispatchEvent(event:Event):Boolean
        {
            if (_disposed || event == null) return false;

            var type:String = event.type;
            if (!_listeners.hasOwnProperty(type)) return true;

            if (event.target == null)
            {
                event.target = _target;
            }
            event.currentTarget = _target;

            // Clone listener list to protect against mid-dispatch mutations
            var list:Array = _listeners[type].slice();
            var toRemove:Array = [];

            for (var i:int = 0; i < list.length; i++)
            {
                var entry:Object = list[i];
                if (entry.once)
                {
                    toRemove.push(entry.listener);
                }

                try
                {
                    if (entry.listener.length == 0)
                    {
                        entry.listener();
                    }
                    else
                    {
                        entry.listener(event);
                    }
                }
                catch (err:Error)
                {
                    // Fail-safe logging for listener error isolation
                }

                if (event.isPropagationStopped)
                {
                    break;
                }
            }

            for (var j:int = 0; j < toRemove.length; j++)
            {
                removeEventListener(type, toRemove[j]);
            }

            return !event.isDefaultPrevented;
        }

        /**
         * Removes all listeners for all event types.
         */
        public function removeAllListeners():void
        {
            _listeners = {};
        }

        public function dispose():void
        {
            if (_disposed) return;
            _disposed = true;
            _listeners = null;
            _target = null;
        }
    }
}
