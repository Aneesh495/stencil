package stencil.core
{
    /**
     * StencilObject provides the root base class for all domain entities in the Stencil runtime.
     * Manages object identity, lifecycle flags, metadata tagging, and serialization scaffolding.
     */
    public class StencilObject implements IDisposable, ICloneable, ISerializable
    {
        private static var _idCounter:uint = 0;

        protected var _id:String;
        protected var _name:String;
        protected var _disposed:Boolean;
        protected var _metadata:Object;
        protected var _tags:Array;

        /**
         * Creates a new StencilObject with a default unique identifier.
         * 
         * @param name Optional human-readable name for the object.
         */
        public function StencilObject(name:String = "")
        {
            _idCounter++;
            _id = "obj_" + _idCounter + "_" + int(Math.random() * 1000000).toString(16);
            _name = (name != null && name.length > 0) ? name : ("Object_" + _idCounter);
            _disposed = false;
            _metadata = {};
            _tags = [];
        }

        /**
         * Global unique identifier for this instance.
         */
        public function get id():String
        {
            return _id;
        }

        public function set id(value:String):void
        {
            if (value != null && value.length > 0)
            {
                _id = value;
            }
        }

        /**
         * Human-readable label for debugging and inspection.
         */
        public function get name():String
        {
            return _name;
        }

        public function set name(value:String):void
        {
            _name = (value != null) ? value : "";
        }

        /**
         * Indicates whether this object has been disposed.
         */
        public function get isDisposed():Boolean
        {
            return _disposed;
        }

        /**
         * Set of arbitrary metadata properties associated with this object.
         */
        public function get metadata():Object
        {
            return _metadata;
        }

        /**
         * List of string tags attached to this object for grouping and querying.
         */
        public function get tags():Array
        {
            return _tags;
        }

        /**
         * Adds a tag if not already present.
         * 
         * @param tag String identifier to attach.
         */
        public function addTag(tag:String):void
        {
            if (tag != null && _tags.indexOf(tag) == -1)
            {
                _tags.push(tag);
            }
        }

        /**
         * Removes a tag if present.
         * 
         * @param tag String identifier to remove.
         * @return True if tag was found and removed.
         */
        public function removeTag(tag:String):Boolean
        {
            var idx:int = _tags.indexOf(tag);
            if (idx != -1)
            {
                _tags.splice(idx, 1);
                return true;
            }
            return false;
        }

        /**
         * Checks whether a tag is attached.
         * 
         * @param tag String identifier to query.
         */
        public function hasTag(tag:String):Boolean
        {
            return _tags.indexOf(tag) != -1;
        }

        /**
         * Sets an arbitrary metadata property.
         */
        public function setMeta(key:String, val:Object):void
        {
            if (key != null)
            {
                _metadata[key] = val;
            }
        }

        /**
         * Retrieves an arbitrary metadata property.
         */
        public function getMeta(key:String, defaultVal:Object = null):Object
        {
            if (key != null && _metadata.hasOwnProperty(key))
            {
                return _metadata[key];
            }
            return defaultVal;
        }

        /**
         * Clones this object, generating a new unique identifier while copying attributes.
         */
        public function clone():Object
        {
            var copy:StencilObject = new StencilObject(_name + "_copy");
            copy.fromJSON(this.toJSON());
            // Ensure unique ID for clone
            _idCounter++;
            copy._id = "obj_" + _idCounter + "_" + int(Math.random() * 1000000).toString(16);
            return copy;
        }

        /**
         * Serializes object state to JSON dictionary.
         */
        public function toJSON():Object
        {
            var metaCopy:Object = {};
            for (var k:String in _metadata)
            {
                metaCopy[k] = _metadata[k];
            }

            return {
                id: _id,
                name: _name,
                tags: _tags.slice(),
                metadata: metaCopy
            };
        }

        /**
         * Deserializes object state from JSON dictionary.
         */
        public function fromJSON(data:Object):void
        {
            if (data == null) return;
            if (data.id != null) _id = String(data.id);
            if (data.name != null) _name = String(data.name);
            if (data.tags is Array)
            {
                _tags = (data.tags as Array).slice();
            }
            if (data.metadata != null)
            {
                _metadata = {};
                for (var k:String in data.metadata)
                {
                    _metadata[k] = data.metadata[k];
                }
            }
        }

        /**
         * Cleans up internal structures.
         */
        public function dispose():void
        {
            if (_disposed) return;
            _disposed = true;
            _metadata = null;
            _tags = null;
        }

        public function toString():String
        {
            return "[" + getClassName() + " id=" + _id + " name=" + _name + "]";
        }

        protected function getClassName():String
        {
            return "StencilObject";
        }
    }
}
