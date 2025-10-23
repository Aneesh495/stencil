package stencil.scene
{
    import stencil.core.EventEmitter;
    import stencil.core.Event;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;

    /**
     * SelectionModel manages active multi-selection states, bounding box handles,
     * and geometric alignment/distribution transformations.
     */
    public class SelectionModel extends EventEmitter
    {
        public static const SELECTION_CHANGE:String = "selectionChange";

        protected var _selectedNodes:Array;

        public function SelectionModel()
        {
            super(this);
            _selectedNodes = [];
        }

        public function get selectedNodes():Array
        {
            return _selectedNodes.slice();
        }

        public function get count():int
        {
            return _selectedNodes.length;
        }

        public function isSelected(node:SceneNode):Boolean
        {
            return _selectedNodes.indexOf(node) != -1;
        }

        public function select(node:SceneNode, additive:Boolean = false):void
        {
            if (node == null) return;

            if (!additive)
            {
                _selectedNodes = [node];
            }
            else
            {
                if (!isSelected(node))
                {
                    _selectedNodes.push(node);
                }
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        public function deselect(node:SceneNode):void
        {
            var idx:int = _selectedNodes.indexOf(node);
            if (idx != -1)
            {
                _selectedNodes.splice(idx, 1);
                dispatchEvent(new Event(SELECTION_CHANGE));
            }
        }

        public function toggle(node:SceneNode):void
        {
            if (isSelected(node))
            {
                deselect(node);
            }
            else
            {
                select(node, true);
            }
        }

        public function setSelection(nodes:Array):void
        {
            _selectedNodes = (nodes != null) ? nodes.slice() : [];
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        public function clear():void
        {
            if (_selectedNodes.length > 0)
            {
                _selectedNodes = [];
                dispatchEvent(new Event(SELECTION_CHANGE));
            }
        }

        /**
         * Computes combined world bounding box of all selected nodes.
         */
        public function getSelectionBounds():Rect2D
        {
            if (_selectedNodes.length == 0) return new Rect2D(0.0, 0.0, 0.0, 0.0);

            var total:Rect2D = (_selectedNodes[0] as SceneNode).worldBounds();
            for (var i:int = 1; i < _selectedNodes.length; i++)
            {
                total = total.union((_selectedNodes[i] as SceneNode).worldBounds());
            }
            return total;
        }

        /**
         * Aligns selected nodes to the leftmost edge.
         */
        public function alignLeft():void
        {
            if (_selectedNodes.length < 2) return;
            var bounds:Rect2D = getSelectionBounds();
            var targetX:Number = bounds.left;

            for (var i:int = 0; i < _selectedNodes.length; i++)
            {
                var node:SceneNode = _selectedNodes[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                node.x += (targetX - nb.left);
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Aligns selected nodes horizontally to the center.
         */
        public function alignCenter():void
        {
            if (_selectedNodes.length < 2) return;
            var bounds:Rect2D = getSelectionBounds();
            var targetCenterX:Number = bounds.centerX;

            for (var i:int = 0; i < _selectedNodes.length; i++)
            {
                var node:SceneNode = _selectedNodes[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                node.x += (targetCenterX - nb.centerX);
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Aligns selected nodes to the rightmost edge.
         */
        public function alignRight():void
        {
            if (_selectedNodes.length < 2) return;
            var bounds:Rect2D = getSelectionBounds();
            var targetRight:Number = bounds.right;

            for (var i:int = 0; i < _selectedNodes.length; i++)
            {
                var node:SceneNode = _selectedNodes[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                node.x += (targetRight - nb.right);
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Aligns selected nodes to the topmost edge.
         */
        public function alignTop():void
        {
            if (_selectedNodes.length < 2) return;
            var bounds:Rect2D = getSelectionBounds();
            var targetTop:Number = bounds.top;

            for (var i:int = 0; i < _selectedNodes.length; i++)
            {
                var node:SceneNode = _selectedNodes[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                node.y += (targetTop - nb.top);
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Aligns selected nodes vertically to the middle.
         */
        public function alignMiddle():void
        {
            if (_selectedNodes.length < 2) return;
            var bounds:Rect2D = getSelectionBounds();
            var targetMiddleY:Number = bounds.centerY;

            for (var i:int = 0; i < _selectedNodes.length; i++)
            {
                var node:SceneNode = _selectedNodes[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                node.y += (targetMiddleY - nb.centerY);
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Aligns selected nodes to the bottommost edge.
         */
        public function alignBottom():void
        {
            if (_selectedNodes.length < 2) return;
            var bounds:Rect2D = getSelectionBounds();
            var targetBottom:Number = bounds.bottom;

            for (var i:int = 0; i < _selectedNodes.length; i++)
            {
                var node:SceneNode = _selectedNodes[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                node.y += (targetBottom - nb.bottom);
            }
            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Distributes selected nodes with equal horizontal spacing between adjacent elements.
         */
        public function distributeHorizontally():void
        {
            if (_selectedNodes.length < 3) return;

            // Sort nodes by worldBounds.left
            var sorted:Array = _selectedNodes.slice();
            sorted.sort(function(a:SceneNode, b:SceneNode):int {
                var aL:Number = a.worldBounds().left;
                var bL:Number = b.worldBounds().left;
                if (aL < bL) return -1;
                if (aL > bL) return 1;
                return 0;
            });

            var firstBox:Rect2D = (sorted[0] as SceneNode).worldBounds();
            var lastBox:Rect2D = (sorted[sorted.length - 1] as SceneNode).worldBounds();

            var totalSpan:Number = lastBox.left - firstBox.left;
            var step:Number = totalSpan / (sorted.length - 1);

            for (var i:int = 1; i < sorted.length - 1; i++)
            {
                var node:SceneNode = sorted[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                var desiredLeft:Number = firstBox.left + i * step;
                node.x += (desiredLeft - nb.left);
            }

            dispatchEvent(new Event(SELECTION_CHANGE));
        }

        /**
         * Distributes selected nodes with equal vertical spacing between adjacent elements.
         */
        public function distributeVertically():void
        {
            if (_selectedNodes.length < 3) return;

            var sorted:Array = _selectedNodes.slice();
            sorted.sort(function(a:SceneNode, b:SceneNode):int {
                var aT:Number = a.worldBounds().top;
                var bT:Number = b.worldBounds().top;
                if (aT < bT) return -1;
                if (aT > bT) return 1;
                return 0;
            });

            var firstBox:Rect2D = (sorted[0] as SceneNode).worldBounds();
            var lastBox:Rect2D = (sorted[sorted.length - 1] as SceneNode).worldBounds();

            var totalSpan:Number = lastBox.top - firstBox.top;
            var step:Number = totalSpan / (sorted.length - 1);

            for (var i:int = 1; i < sorted.length - 1; i++)
            {
                var node:SceneNode = sorted[i] as SceneNode;
                var nb:Rect2D = node.worldBounds();
                var desiredTop:Number = firstBox.top + i * step;
                node.y += (desiredTop - nb.top);
            }

            dispatchEvent(new Event(SELECTION_CHANGE));
        }
    }
}
