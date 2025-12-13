package stencil.tools
{
    import stencil.core.EventEmitter;
    import stencil.core.Event;
    import stencil.geom.Point2D;
    import stencil.scene.SceneGraph;

    /**
     * ToolManager orchestrates interactive manipulation tools and pointer event dispatching.
     */
    public class ToolManager extends EventEmitter
    {
        public static const TOOL_CHANGE:String = "toolChange";

        public static const TOOL_SELECT:String   = "select";
        public static const TOOL_PEN:String      = "pen";
        public static const TOOL_NODE_EDIT:String = "nodeEdit";
        public static const TOOL_SHAPE:String    = "shape";
        public static const TOOL_PAN_ZOOM:String = "panZoom";

        protected var _tools:Object;
        protected var _activeToolName:String;
        protected var _activeTool:Object;
        protected var _scene:SceneGraph;

        public function ToolManager(scene:SceneGraph = null)
        {
            super(this);
            _scene = scene;
            _tools = {};
            _activeToolName = "";
            _activeTool = null;
        }

        public function get scene():SceneGraph { return _scene; }
        public function set scene(val:SceneGraph):void { _scene = val; }

        public function get activeToolName():String { return _activeToolName; }
        public function get activeTool():Object { return _activeTool; }

        public function registerTool(name:String, toolInstance:Object):void
        {
            if (name != null && toolInstance != null)
            {
                _tools[name] = toolInstance;
            }
        }

        public function activateTool(name:String):Boolean
        {
            if (!_tools.hasOwnProperty(name)) return false;

            if (_activeTool != null && _activeTool.hasOwnProperty("deactivate"))
            {
                _activeTool.deactivate();
            }

            _activeToolName = name;
            _activeTool = _tools[name];

            if (_activeTool != null && _activeTool.hasOwnProperty("activate"))
            {
                _activeTool.activate();
            }

            dispatchEvent(new Event(TOOL_CHANGE));
            return true;
        }

        public function onPointerDown(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (_activeTool != null && _activeTool.hasOwnProperty("onPointerDown"))
            {
                _activeTool.onPointerDown(worldPt, shiftKey, altKey);
            }
        }

        public function onPointerMove(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (_activeTool != null && _activeTool.hasOwnProperty("onPointerMove"))
            {
                _activeTool.onPointerMove(worldPt, shiftKey, altKey);
            }
        }

        public function onPointerUp(worldPt:Point2D, shiftKey:Boolean = false, altKey:Boolean = false):void
        {
            if (_activeTool != null && _activeTool.hasOwnProperty("onPointerUp"))
            {
                _activeTool.onPointerUp(worldPt, shiftKey, altKey);
            }
        }

        public function onKeyDown(keyCode:int):void
        {
            if (_activeTool != null && _activeTool.hasOwnProperty("onKeyDown"))
            {
                _activeTool.onKeyDown(keyCode);
            }
        }
    }
}
