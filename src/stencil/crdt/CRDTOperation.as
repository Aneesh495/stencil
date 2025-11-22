package stencil.crdt
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * CRDTOperation encapsulates an atomic, serializable tree mutation message
     * broadcast between collaborative editing peers.
     */
    public class CRDTOperation implements ICloneable, ISerializable
    {
        public static const OP_INSERT:int = 1;
        public static const OP_MOVE:int   = 2;
        public static const OP_DELETE:int = 3;
        public static const OP_UPDATE:int = 4;

        public var opType:int;
        public var nodeId:String;
        public var parentId:String;
        public var timestamp:LamportTimestamp;
        public var payload:Object;
        public var nodeType:String;

        public function CRDTOperation(
            opType:int = 1,
            nodeId:String = "",
            parentId:String = null,
            timestamp:LamportTimestamp = null,
            payload:Object = null,
            nodeType:String = "PathNode"
        )
        {
            this.opType = opType;
            this.nodeId = nodeId;
            this.parentId = parentId;
            this.timestamp = (timestamp != null) ? (timestamp.clone() as LamportTimestamp) : new LamportTimestamp();
            this.payload = (payload != null) ? payload : {};
            this.nodeType = nodeType;
        }

        public function clone():Object
        {
            var pCopy:Object = {};
            for (var k:String in payload)
            {
                pCopy[k] = payload[k];
            }
            return new CRDTOperation(opType, nodeId, parentId, timestamp.clone() as LamportTimestamp, pCopy, nodeType);
        }

        public function toJSON():Object
        {
            return {
                opType: opType,
                nodeId: nodeId,
                parentId: parentId,
                timestamp: timestamp.toJSON(),
                payload: payload,
                nodeType: nodeType
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                opType = int(data.opType);
                nodeId = String(data.nodeId);
                parentId = (data.parentId != null) ? String(data.parentId) : null;
                nodeType = (data.nodeType != null) ? String(data.nodeType) : "PathNode";
                if (data.timestamp != null)
                {
                    timestamp = new LamportTimestamp();
                    timestamp.fromJSON(data.timestamp);
                }
                payload = (data.payload != null) ? data.payload : {};
            }
        }
    }
}
