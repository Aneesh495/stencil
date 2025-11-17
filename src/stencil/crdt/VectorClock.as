package stencil.crdt
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * VectorClock maintains causal relationship tracking across distributed peers.
     * Evaluates strict partial ordering, causal precedence, and concurrency detection.
     */
    public class VectorClock implements ICloneable, ISerializable
    {
        public static const ORDER_EQUAL:int      = 0;
        public static const ORDER_BEFORE:int     = -1;
        public static const ORDER_AFTER:int      = 1;
        public static const ORDER_CONCURRENT:int = 2;

        protected var _clock:Object; // replicaId (String) -> counter (uint)

        public function VectorClock(clock:Object = null)
        {
            _clock = {};
            if (clock != null)
            {
                for (var k:String in clock)
                {
                    _clock[k] = uint(clock[k]);
                }
            }
        }

        public function getCounter(replicaId:String):uint
        {
            if (replicaId != null && _clock.hasOwnProperty(replicaId))
            {
                return uint(_clock[replicaId]);
            }
            return 0;
        }

        public function setCounter(replicaId:String, counter:uint):void
        {
            if (replicaId != null)
            {
                _clock[replicaId] = counter;
            }
        }

        /**
         * Increments local replica clock counter.
         */
        public function tick(replicaId:String):uint
        {
            var next:uint = getCounter(replicaId) + 1;
            setCounter(replicaId, next);
            return next;
        }

        /**
         * Merges another vector clock by taking pairwise maximums.
         */
        public function merge(other:VectorClock):void
        {
            if (other == null) return;

            var otherRaw:Object = other._clock;
            for (var k:String in otherRaw)
            {
                var localVal:uint = getCounter(k);
                var remoteVal:uint = uint(otherRaw[k]);
                if (remoteVal > localVal)
                {
                    _clock[k] = remoteVal;
                }
            }
        }

        /**
         * Compares causal relationship with another vector clock.
         * Returns ORDER_EQUAL, ORDER_BEFORE, ORDER_AFTER, or ORDER_CONCURRENT.
         */
        public function compare(other:VectorClock):int
        {
            if (other == null) return ORDER_AFTER;

            var thisDominated:Boolean = false; // this has some < other
            var otherDominated:Boolean = false; // other has some < this

            // Collect union of replica keys
            var allKeys:Object = {};
            for (var k1:String in _clock) allKeys[k1] = true;
            for (var k2:String in other._clock) allKeys[k2] = true;

            for (var key:String in allKeys)
            {
                var v1:uint = getCounter(key);
                var v2:uint = other.getCounter(key);

                if (v1 < v2)
                {
                    thisDominated = true;
                }
                else if (v1 > v2)
                {
                    otherDominated = true;
                }
            }

            if (thisDominated && !otherDominated) return ORDER_BEFORE;
            if (!thisDominated && otherDominated) return ORDER_AFTER;
            if (!thisDominated && !otherDominated) return ORDER_EQUAL;
            return ORDER_CONCURRENT;
        }

        public function clone():Object
        {
            return new VectorClock(_clock);
        }

        public function toJSON():Object
        {
            var copy:Object = {};
            for (var k:String in _clock)
            {
                copy[k] = _clock[k];
            }
            return copy;
        }

        public function fromJSON(data:Object):void
        {
            _clock = {};
            if (data != null)
            {
                for (var k:String in data)
                {
                    _clock[k] = uint(data[k]);
                }
            }
        }

        public function toString():String
        {
            var pairs:Array = [];
            for (var k:String in _clock)
            {
                pairs.push(k + ":" + _clock[k]);
            }
            return "VectorClock{" + pairs.join(", ") + "}";
        }
    }
}
