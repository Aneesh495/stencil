package stencil.scene
{
    import stencil.core.PropertyChangeEvent;
    import stencil.core.StencilObject;
    import stencil.geom.Matrix2D;
    import stencil.geom.Point2D;
    import stencil.geom.Rect2D;
    import stencil.geom.Transform2D;

    /**
     * SceneNode provides the foundational DAG element for the Stencil scene hierarchy.
     * Manages parent-child relationships, hierarchical affine transforms, bounds caching,
     * opacity, visibility, and dirty region invalidation propagation.
     */
    public class SceneNode extends StencilObject
    {
        protected var _parent:SceneNode;
        protected var _children:Array;
        protected var _transform:Transform2D;

        protected var _opacity:Number;
        protected var _visible:Boolean;
        protected var _zIndex:int;
        protected var _blendMode:String;

        protected var _cachedLocalBounds:Rect2D;
        protected var _cachedWorldBounds:Rect2D;
        protected var _boundsDirty:Boolean;
        protected var _transformDirty:Boolean;

        public function SceneNode(name:String = "")
        {
            super(name);
            _parent = null;
            _children = [];
            _transform = new Transform2D();

            _opacity = 1.0;
            _visible = true;
            _zIndex = 0;
            _blendMode = "normal";

            _cachedLocalBounds = null;
            _cachedWorldBounds = null;
            _boundsDirty = true;
            _transformDirty = true;
        }

        public function get parent():SceneNode { return _parent; }
        public function set parent(val:SceneNode):void { _parent = val; invalidate(); }

        public function get children():Array { return _children; }
        public function get numChildren():int { return _children.length; }

        public function get transform():Transform2D { return _transform; }

        public function get x():Number { return _transform.x; }
        public function set x(val:Number):void { _transform.x = val; invalidate(); }

        public function get y():Number { return _transform.y; }
        public function set y(val:Number):void { _transform.y = val; invalidate(); }

        public function get scaleX():Number { return _transform.scaleX; }
        public function set scaleX(val:Number):void { _transform.scaleX = val; invalidate(); }

        public function get scaleY():Number { return _transform.scaleY; }
        public function set scaleY(val:Number):void { _transform.scaleY = val; invalidate(); }

        public function get rotation():Number { return _transform.rotation; }
        public function set rotation(val:Number):void { _transform.rotation = val; invalidate(); }

        public function get opacity():Number { return _opacity; }
        public function set opacity(val:Number):void
        {
            if (_opacity != val)
            {
                var oldVal:Number = _opacity;
                _opacity = Math.max(0.0, Math.min(1.0, val));
                invalidate(false);
            }
        }

        public function get visible():Boolean { return _visible; }
        public function set visible(val:Boolean):void
        {
            if (_visible != val)
            {
                _visible = val;
                invalidate(true);
            }
        }

        public function get zIndex():int { return _zIndex; }
        public function set zIndex(val:int):void
        {
            if (_zIndex != val)
            {
                _zIndex = val;
                if (_parent != null)
                {
                    _parent.sortChildrenByZIndex();
                }
            }
        }

        public function get blendMode():String { return _blendMode; }
        public function set blendMode(val:String):void { _blendMode = val; }

        /**
         * Adds a child node to the end of the children list.
         */
        public function addChild(child:SceneNode):SceneNode
        {
            return addChildAt(child, _children.length);
        }

        /**
         * Inserts a child node at a specific index.
         */
        public function addChildAt(child:SceneNode, index:int):SceneNode
        {
            if (child == null || child === this) return null;

            if (child.parent != null)
            {
                child.parent.removeChild(child);
            }

            index = Math.max(0, Math.min(_children.length, index));
            _children.splice(index, 0, child);
            child.parent = this;
            invalidate();

            return child;
        }

        /**
         * Removes a child node.
         */
        public function removeChild(child:SceneNode):SceneNode
        {
            var idx:int = _children.indexOf(child);
            if (idx != -1)
            {
                return removeChildAt(idx);
            }
            return null;
        }

        /**
         * Removes child at specific index.
         */
        public function removeChildAt(index:int):SceneNode
        {
            if (index >= 0 && index < _children.length)
            {
                var child:SceneNode = _children.splice(index, 1)[0] as SceneNode;
                child.parent = null;
                invalidate();
                return child;
            }
            return null;
        }

        /**
         * Retrieves child at specific index.
         */
        public function getChildAt(index:int):SceneNode
        {
            if (index >= 0 && index < _children.length)
            {
                return _children[index] as SceneNode;
            }
            return null;
        }

        /**
         * Sorts child list in ascending order of zIndex.
         */
        public function sortChildrenByZIndex():void
        {
            _children.sort(function(a:SceneNode, b:SceneNode):int {
                if (a.zIndex < b.zIndex) return -1;
                if (a.zIndex > b.zIndex) return 1;
                return 0;
            });
        }

        /**
         * Invalidates transform and bounds caches down through descendant branches.
         */
        public function invalidate(invalidateBounds:Boolean = true):void
        {
            _transformDirty = true;
            if (invalidateBounds)
            {
                _boundsDirty = true;
            }

            for (var i:int = 0; i < _children.length; i++)
            {
                (_children[i] as SceneNode).invalidate(invalidateBounds);
            }

            if (_parent != null && invalidateBounds)
            {
                _parent.invalidateBoundsOnly();
            }
        }

        protected function invalidateBoundsOnly():void
        {
            _boundsDirty = true;
            if (_parent != null)
            {
                _parent.invalidateBoundsOnly();
            }
        }

        /**
         * Computes and caches world transform matrix by chaining parent world transforms.
         */
        public function getWorldMatrix():Matrix2D
        {
            if (_parent != null)
            {
                _transform.updateWorldMatrix(_parent.getWorldMatrix());
            }
            else
            {
                _transform.updateWorldMatrix(null);
            }
            _transformDirty = false;
            return _transform.worldMatrix;
        }

        /**
         * Converts local coordinate point to world space.
         */
        public function localToWorld(pt:Point2D):Point2D
        {
            return getWorldMatrix().transformPoint(pt);
        }

        /**
         * Converts world coordinate point to local space.
         */
        public function worldToLocal(pt:Point2D):Point2D
        {
            return getWorldMatrix().getInverse().transformPoint(pt);
        }

        /**
         * Computes local untransformed bounding rectangle for this node.
         * Default implementation encompasses union of all child local bounds.
         */
        public function localBounds():Rect2D
        {
            if (!_boundsDirty && _cachedLocalBounds != null)
            {
                return _cachedLocalBounds.clone() as Rect2D;
            }

            var total:Rect2D = computeNodeContentBounds();

            for (var i:int = 0; i < _children.length; i++)
            {
                var child:SceneNode = _children[i] as SceneNode;
                if (child.visible)
                {
                    var childBounds:Rect2D = child.localBounds();
                    if (!childBounds.isEmpty())
                    {
                        var childWorldInThis:Matrix2D = child.transform.localMatrix;
                        var p1:Point2D = childWorldInThis.transformPoint(new Point2D(childBounds.left, childBounds.top));
                        var p2:Point2D = childWorldInThis.transformPoint(new Point2D(childBounds.right, childBounds.top));
                        var p3:Point2D = childWorldInThis.transformPoint(new Point2D(childBounds.right, childBounds.bottom));
                        var p4:Point2D = childWorldInThis.transformPoint(new Point2D(childBounds.left, childBounds.bottom));

                        var transformedChildBox:Rect2D = Rect2D.fromPoints(p1, p2);
                        transformedChildBox.unionPoint(p3);
                        transformedChildBox.unionPoint(p4);

                        total = total.union(transformedChildBox);
                    }
                }
            }

            _cachedLocalBounds = total;
            _boundsDirty = false;
            return _cachedLocalBounds.clone() as Rect2D;
        }

        /**
         * Subclasses override this to supply their intrinsic geometric bounds.
         */
        protected function computeNodeContentBounds():Rect2D
        {
            return new Rect2D(0.0, 0.0, 0.0, 0.0);
        }

        /**
         * Computes world axis-aligned bounding box.
         */
        public function worldBounds():Rect2D
        {
            var lb:Rect2D = localBounds();
            if (lb.isEmpty()) return new Rect2D(0.0, 0.0, 0.0, 0.0);

            var wm:Matrix2D = getWorldMatrix();
            var p1:Point2D = wm.transformPoint(new Point2D(lb.left, lb.top));
            var p2:Point2D = wm.transformPoint(new Point2D(lb.right, lb.top));
            var p3:Point2D = wm.transformPoint(new Point2D(lb.right, lb.bottom));
            var p4:Point2D = wm.transformPoint(new Point2D(lb.left, lb.bottom));

            var wb:Rect2D = Rect2D.fromPoints(p1, p2);
            wb.unionPoint(p3);
            wb.unionPoint(p4);
            return wb;
        }

        override public function toJSON():Object
        {
            var base:Object = super.toJSON();
            base.type = getClassName();
            base.transform = _transform.toJSON();
            base.opacity = _opacity;
            base.visible = _visible;
            base.zIndex = _zIndex;
            base.blendMode = _blendMode;

            var childArr:Array = [];
            for (var i:int = 0; i < _children.length; i++)
            {
                childArr.push((_children[i] as SceneNode).toJSON());
            }
            base.children = childArr;

            return base;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.transform != null) _transform.fromJSON(data.transform);
                if (data.opacity != null) _opacity = Number(data.opacity);
                if (data.visible != null) _visible = Boolean(data.visible);
                if (data.zIndex != null) _zIndex = int(data.zIndex);
                if (data.blendMode != null) _blendMode = String(data.blendMode);
                invalidate();
            }
        }

        override protected function getClassName():String
        {
            return "SceneNode";
        }
    }
}
