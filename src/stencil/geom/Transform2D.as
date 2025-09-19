package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * Transform2D manages decomposed geometric transformation properties (position, pivot,
     * scale, rotation, and skew) while caching affine matrices.
     */
    public class Transform2D implements ICloneable, ISerializable
    {
        protected var _position:Point2D;
        protected var _pivot:Point2D;
        protected var _scale:Point2D;
        protected var _rotation:Number;
        protected var _skew:Point2D;

        protected var _localMatrix:Matrix2D;
        protected var _worldMatrix:Matrix2D;
        protected var _dirty:Boolean;

        public function Transform2D()
        {
            _position = new Point2D(0.0, 0.0);
            _pivot = new Point2D(0.0, 0.0);
            _scale = new Point2D(1.0, 1.0);
            _rotation = 0.0;
            _skew = new Point2D(0.0, 0.0);

            _localMatrix = Matrix2D.identity();
            _worldMatrix = Matrix2D.identity();
            _dirty = true;
        }

        public function get position():Point2D { return _position; }
        public function set position(val:Point2D):void { _position.copyFrom(val); _dirty = true; }

        public function get x():Number { return _position.x; }
        public function set x(val:Number):void { _position.x = val; _dirty = true; }

        public function get y():Number { return _position.y; }
        public function set y(val:Number):void { _position.y = val; _dirty = true; }

        public function get pivot():Point2D { return _pivot; }
        public function set pivot(val:Point2D):void { _pivot.copyFrom(val); _dirty = true; }

        public function get scale():Point2D { return _scale; }
        public function set scale(val:Point2D):void { _scale.copyFrom(val); _dirty = true; }

        public function get scaleX():Number { return _scale.x; }
        public function set scaleX(val:Number):void { _scale.x = val; _dirty = true; }

        public function get scaleY():Number { return _scale.y; }
        public function set scaleY(val:Number):void { _scale.y = val; _dirty = true; }

        public function get rotation():Number { return _rotation; }
        public function set rotation(val:Number):void { _rotation = val; _dirty = true; }

        public function get skew():Point2D { return _skew; }
        public function set skew(val:Point2D):void { _skew.copyFrom(val); _dirty = true; }

        public function invalidate():void
        {
            _dirty = true;
        }

        public function get isDirty():Boolean
        {
            return _dirty;
        }

        /**
         * Recomputes local affine matrix if invalidated:
         * T(pos) * T(pivot) * R(rot) * Skew * Scale * T(-pivot)
         */
        public function get localMatrix():Matrix2D
        {
            if (_dirty)
            {
                recomputeLocalMatrix();
            }
            return _localMatrix;
        }

        public function get worldMatrix():Matrix2D
        {
            return _worldMatrix;
        }

        protected function recomputeLocalMatrix():void
        {
            _localMatrix.setIdentity();

            var px:Number = _pivot.x;
            var py:Number = _pivot.y;

            // Translate to position + pivot
            _localMatrix.translate(_position.x + px, _position.y + py);

            if (_rotation != 0.0)
            {
                _localMatrix.rotate(_rotation);
            }

            if (_skew.x != 0.0 || _skew.y != 0.0)
            {
                var skewMat:Matrix2D = Matrix2D.skew(_skew.x, _skew.y);
                _localMatrix.concat(skewMat);
            }

            if (_scale.x != 1.0 || _scale.y != 1.0)
            {
                _localMatrix.scale(_scale.x, _scale.y);
            }

            // Translate back from pivot
            if (px != 0.0 || py != 0.0)
            {
                _localMatrix.translate(-px, -py);
            }

            _dirty = false;
        }

        /**
         * Propagates world matrix from parent: World = ParentWorld * Local.
         */
        public function updateWorldMatrix(parentWorld:Matrix2D = null):void
        {
            var local:Matrix2D = localMatrix;
            if (parentWorld != null)
            {
                _worldMatrix = parentWorld.multiply(local);
            }
            else
            {
                _worldMatrix = local.clone() as Matrix2D;
            }
        }

        public function clone():Object
        {
            var c:Transform2D = new Transform2D();
            c.position = _position;
            c.pivot = _pivot;
            c.scale = _scale;
            c.rotation = _rotation;
            c.skew = _skew;
            return c;
        }

        public function toJSON():Object
        {
            return {
                x: _position.x,
                y: _position.y,
                pivotX: _pivot.x,
                pivotY: _pivot.y,
                scaleX: _scale.x,
                scaleY: _scale.y,
                rotation: _rotation,
                skewX: _skew.x,
                skewY: _skew.y
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                _position.set(Number(data.x), Number(data.y));
                _pivot.set(Number(data.pivotX), Number(data.pivotY));
                _scale.set(Number(data.scaleX), Number(data.scaleY));
                _rotation = Number(data.rotation);
                _skew.set(Number(data.skewX), Number(data.skewY));
                _dirty = true;
            }
        }
    }
}
