package stencil.crdt
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * LamportTimestamp establishes a totally ordered logical timestamp for distributed events.
     * Breaks counter ties deterministically using unique replica identifier strings.
     */
    public class LamportTimestamp implements ICloneable, ISerializable
    {
        public var counter:uint;
        public var replicaId:String;

        public function LamportTimestamp(counter:uint = 0, replicaId:String = "")
        {
            this.counter = counter;
            this.replicaId = (replicaId != null) ? replicaId : "";
        }

        public function tick():LamportTimestamp
        {
            counter++;
            return this;
        }

        public function update(remoteCounter:uint):void
        {
            if (remoteCounter > counter)
            {
                counter = remoteCounter;
            }
            counter++;
        }

        /**
         * Compares total order: counter first, then deterministic lexicographical replicaId.
         * Returns -1 if this < other, 1 if this > other, 0 if equal.
         */
        public function compare(other:LamportTimestamp):int
        {
            if (other == null) return 1;

            if (this.counter < other.counter) return -1;
            if (this.counter > other.counter) return 1;

            // Tie-break by replicaId
            if (this.replicaId < other.replicaId) return -1;
            if (this.replicaId > other.replicaId) return 1;
            return 0;
        }

        public function clone():Object
        {
            return new LamportTimestamp(counter, replicaId);
        }

        public function toJSON():Object
        {
            return { counter: counter, replicaId: replicaId };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                counter = uint(data.counter);
                replicaId = String(data.replicaId);
            }
        }

        public function toString():String
        {
            return counter + "@" + replicaId;
        }
    }
}
