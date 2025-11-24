package stencil.crdt
{
    import stencil.core.EventEmitter;
    import stencil.core.Event;

    /**
     * HistoryManager provides transaction-aware undo and redo navigation for vector mutations.
     * Manages reversible command history stacks with snapshot checkpoints.
     */
    public class HistoryManager extends EventEmitter
    {
        public static const HISTORY_CHANGE:String = "historyChange";

        protected var _undoStack:Array;
        protected var _redoStack:Array;
        protected var _maxHistory:int;
        protected var _activeTransaction:Array;
        protected var _inTransaction:Boolean;

        public function HistoryManager(maxHistory:int = 100)
        {
            super(this);
            _undoStack = [];
            _redoStack = [];
            _maxHistory = Math.max(1, maxHistory);
            _activeTransaction = null;
            _inTransaction = false;
        }

        public function get canUndo():Boolean
        {
            return _undoStack.length > 0;
        }

        public function get canRedo():Boolean
        {
            return _redoStack.length > 0;
        }

        public function get undoCount():int
        {
            return _undoStack.length;
        }

        public function get redoCount():int
        {
            return _redoStack.length;
        }

        /**
         * Begins a multi-step transaction that will collapse into a single undoable action.
         */
        public function beginTransaction():void
        {
            if (!_inTransaction)
            {
                _activeTransaction = [];
                _inTransaction = true;
            }
        }

        /**
         * Commits the current active transaction.
         */
        public function commitTransaction():void
        {
            if (_inTransaction && _activeTransaction != null)
            {
                if (_activeTransaction.length > 0)
                {
                    pushAction({
                        isBatch: true,
                        actions: _activeTransaction
                    });
                }
                _activeTransaction = null;
                _inTransaction = false;
            }
        }

        /**
         * Records an executable command with forward and inverse execute handlers.
         */
        public function record(doAction:Function, undoAction:Function):void
        {
            var actionObj:Object = {
                doAction: doAction,
                undoAction: undoAction
            };

            if (_inTransaction && _activeTransaction != null)
            {
                _activeTransaction.push(actionObj);
            }
            else
            {
                pushAction(actionObj);
            }
        }

        protected function pushAction(action:Object):void
        {
            _undoStack.push(action);
            if (_undoStack.length > _maxHistory)
            {
                _undoStack.shift();
            }
            _redoStack = []; // Clear redo stack on new action
            dispatchEvent(new Event(HISTORY_CHANGE));
        }

        /**
         * Undoes the most recent command or batch.
         */
        public function undo():Boolean
        {
            if (!canUndo) return false;

            var action:Object = _undoStack.pop();
            _redoStack.push(action);

            executeUndo(action);
            dispatchEvent(new Event(HISTORY_CHANGE));
            return true;
        }

        /**
         * Redoes the previously undone command or batch.
         */
        public function redo():Boolean
        {
            if (!canRedo) return false;

            var action:Object = _redoStack.pop();
            _undoStack.push(action);

            executeDo(action);
            dispatchEvent(new Event(HISTORY_CHANGE));
            return true;
        }

        protected function executeUndo(action:Object):void
        {
            if (action.isBatch && action.actions is Array)
            {
                var arr:Array = action.actions as Array;
                for (var i:int = arr.length - 1; i >= 0; i--)
                {
                    if (arr[i].undoAction != null)
                    {
                        arr[i].undoAction();
                    }
                }
            }
            else if (action.undoAction != null)
            {
                action.undoAction();
            }
        }

        protected function executeDo(action:Object):void
        {
            if (action.isBatch && action.actions is Array)
            {
                var arr:Array = action.actions as Array;
                for (var i:int = 0; i < arr.length; i++)
                {
                    if (arr[i].doAction != null)
                    {
                        arr[i].doAction();
                    }
                }
            }
            else if (action.doAction != null)
            {
                action.doAction();
            }
        }

        public function clear():void
        {
            _undoStack = [];
            _redoStack = [];
            _activeTransaction = null;
            _inTransaction = false;
            dispatchEvent(new Event(HISTORY_CHANGE));
        }
    }
}
