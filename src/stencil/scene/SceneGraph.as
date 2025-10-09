package stencil.scene
{
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.geom.SpatialBVH;

    /**
     * Root document graph container for Stencil vector scenes.
     * Manages global node lookup dictionaries, pre/post-order hierarchical traversals,
     * and spatial indexing for fast viewport queries.
     */
    public class SceneGraph extends SceneNode
    {
        protected var _nodeIndex:Object;
        protected var _viewportWidth:Number;
        protected var _viewportHeight:Number;
        protected var _backgroundColor:uint;
        protected var _spatialIndex:SpatialBVH;

        public function SceneGraph(name:String = "RootScene", width:Number = 1920.0, height:Number = 1080.0)
        {
            super(name);
            _nodeIndex = {};
            _viewportWidth = width;
            _viewportHeight = height;
            _backgroundColor = 0xFFFFFFFF; // White default
            _spatialIndex = new SpatialBVH();
            registerNode(this);
        }

        public function get viewportWidth():Number { return _viewportWidth; }
        public function set viewportWidth(val:Number):void { _viewportWidth = val; }

        public function get viewportHeight():Number { return _viewportHeight; }
        public function set viewportHeight(val:Number):void { _viewportHeight = val; }

        public function get backgroundColor():uint { return _backgroundColor; }
        public function set backgroundColor(val:uint):void { _backgroundColor = val; }

        public function get spatialIndex():SpatialBVH { return _spatialIndex; }

        public function registerNode(node:SceneNode):void
        {
            if (node != null && node.id != null)
            {
                _nodeIndex[node.id] = node;
            }
        }

        public function unregisterNode(node:SceneNode):void
        {
            if (node != null && node.id != null && _nodeIndex.hasOwnProperty(node.id))
            {
                delete _nodeIndex[node.id];
            }
        }

        public function findNodeById(id:String):SceneNode
        {
            if (id != null && _nodeIndex.hasOwnProperty(id))
            {
                return _nodeIndex[id] as SceneNode;
            }
            return null;
        }

        override public function addChildAt(child:SceneNode, index:int):SceneNode
        {
            var res:SceneNode = super.addChildAt(child, index);
            if (res != null)
            {
                registerRecursive(res);
                rebuildSpatialIndex();
            }
            return res;
        }

        override public function removeChildAt(index:int):SceneNode
        {
            var res:SceneNode = super.removeChildAt(index);
            if (res != null)
            {
                unregisterRecursive(res);
                rebuildSpatialIndex();
            }
            return res;
        }

        private function registerRecursive(node:SceneNode):void
        {
            registerNode(node);
            for (var i:int = 0; i < node.numChildren; i++)
            {
                registerRecursive(node.getChildAt(i));
            }
        }

        private function unregisterRecursive(node:SceneNode):void
        {
            unregisterNode(node);
            for (var i:int = 0; i < node.numChildren; i++)
            {
                unregisterRecursive(node.getChildAt(i));
            }
        }

        /**
         * Rebuilds spatial BVH index over all leaf or content nodes.
         */
        public function rebuildSpatialIndex():void
        {
            _spatialIndex.clear();
            traversePreOrder(function(node:SceneNode):void {
                if (node !== this && node.visible)
                {
                    var wb:Rect2D = node.worldBounds();
                    if (!wb.isEmpty())
                    {
                        _spatialIndex.insert(node, wb);
                    }
                }
            });
        }

        /**
         * Traverses hierarchy in depth-first pre-order.
         */
        public function traversePreOrder(callback:Function):void
        {
            traversePreOrderInternal(this, callback);
        }

        private static function traversePreOrderInternal(node:SceneNode, callback:Function):void
        {
            if (node == null || callback == null) return;
            callback(node);
            for (var i:int = 0; i < node.numChildren; i++)
            {
                traversePreOrderInternal(node.getChildAt(i), callback);
            }
        }

        /**
         * Traverses hierarchy in depth-first post-order.
         */
        public function traversePostOrder(callback:Function):void
        {
            traversePostOrderInternal(this, callback);
        }

        private static function traversePostOrderInternal(node:SceneNode, callback:Function):void
        {
            if (node == null || callback == null) return;
            for (var i:int = 0; i < node.numChildren; i++)
            {
                traversePostOrderInternal(node.getChildAt(i), callback);
            }
            callback(node);
        }

        public function queryViewport(viewportRect:Rect2D):Array
        {
            return _spatialIndex.queryRect(viewportRect);
        }

        override protected function getClassName():String
        {
            return "SceneGraph";
        }
    }
}
