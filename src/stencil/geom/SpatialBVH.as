package stencil.geom
{
    /**
     * Internal node of the SpatialBVH hierarchy.
     */
    class BVHNode
    {
        public var bounds:Rect2D;
        public var item:Object;
        public var left:BVHNode;
        public var right:BVHNode;
        public var isLeaf:Boolean;

        public function BVHNode(bounds:Rect2D, item:Object = null)
        {
            this.bounds = bounds.clone() as Rect2D;
            this.item = item;
            this.left = null;
            this.right = null;
            this.isLeaf = (item != null);
        }
    }

    /**
     * SpatialBVH provides a 2D Bounding Volume Hierarchy for accelerated spatial queries.
     * Yields logarithmic O(log N) viewport culling, frustum testing, and mouse picking.
     */
    public class SpatialBVH
    {
        protected var _root:BVHNode;
        protected var _items:Array;

        public function SpatialBVH()
        {
            _root = null;
            _items = [];
        }

        public function get count():int
        {
            return _items.length;
        }

        public function clear():void
        {
            _root = null;
            _items = [];
        }

        /**
         * Inserts an item with its 2D bounding rectangle.
         */
        public function insert(item:Object, bounds:Rect2D):void
        {
            if (item == null || bounds == null) return;
            _items.push({ item: item, bounds: bounds.clone() as Rect2D });
            _root = rebuildSubtree(_items);
        }

        /**
         * Removes an item from the hierarchy.
         */
        public function remove(item:Object):Boolean
        {
            var idx:int = -1;
            for (var i:int = 0; i < _items.length; i++)
            {
                if (_items[i].item === item)
                {
                    idx = i;
                    break;
                }
            }

            if (idx != -1)
            {
                _items.splice(idx, 1);
                _root = (_items.length > 0) ? rebuildSubtree(_items) : null;
                return true;
            }
            return false;
        }

        /**
         * Rebuilds the entire hierarchy using recursive spatial median splits.
         */
        public function rebuild():void
        {
            _root = (_items.length > 0) ? rebuildSubtree(_items) : null;
        }

        protected function rebuildSubtree(entries:Array):BVHNode
        {
            if (entries.length == 0) return null;
            if (entries.length == 1)
            {
                return new BVHNode(entries[0].bounds, entries[0].item);
            }

            // Compute total enclosing bounds
            var totalBounds:Rect2D = entries[0].bounds.clone() as Rect2D;
            for (var i:int = 1; i < entries.length; i++)
            {
                totalBounds = totalBounds.union(entries[i].bounds);
            }

            var node:BVHNode = new BVHNode(totalBounds, null);

            // Split along largest axis
            var splitX:Boolean = totalBounds.width >= totalBounds.height;

            entries.sort(function(a:Object, b:Object):int {
                var cA:Number = splitX ? a.bounds.centerX : a.bounds.centerY;
                var cB:Number = splitX ? b.bounds.centerX : b.bounds.centerY;
                if (cA < cB) return -1;
                if (cA > cB) return 1;
                return 0;
            });

            var mid:int = entries.length >> 1;
            var leftEntries:Array = entries.slice(0, mid);
            var rightEntries:Array = entries.slice(mid);

            node.left = rebuildSubtree(leftEntries);
            node.right = rebuildSubtree(rightEntries);

            return node;
        }

        /**
         * Queries all items whose bounding box intersects queryRect.
         */
        public function queryRect(query:Rect2D, outItems:Array = null):Array
        {
            var results:Array = (outItems != null) ? outItems : [];
            if (_root == null || query == null || query.isEmpty()) return results;

            queryNode(_root, query, results);
            return results;
        }

        protected function queryNode(node:BVHNode, query:Rect2D, outItems:Array):void
        {
            if (node == null) return;
            if (!node.bounds.intersects(query)) return;

            if (node.isLeaf)
            {
                if (node.item != null)
                {
                    outItems.push(node.item);
                }
                return;
            }

            if (node.left != null) queryNode(node.left, query, outItems);
            if (node.right != null) queryNode(node.right, query, outItems);
        }

        /**
         * Queries all items whose bounding box contains the target point.
         */
        public function queryPoint(pt:Point2D, outItems:Array = null):Array
        {
            var results:Array = (outItems != null) ? outItems : [];
            if (_root == null || pt == null) return results;

            queryPointNode(_root, pt, results);
            return results;
        }

        protected function queryPointNode(node:BVHNode, pt:Point2D, outItems:Array):void
        {
            if (node == null) return;
            if (!node.bounds.containsPoint(pt)) return;

            if (node.isLeaf)
            {
                if (node.item != null)
                {
                    outItems.push(node.item);
                }
                return;
            }

            if (node.left != null) queryPointNode(node.left, pt, outItems);
            if (node.right != null) queryPointNode(node.right, pt, outItems);
        }
    }
}
