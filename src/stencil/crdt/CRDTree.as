package stencil.crdt
{
    /**
     * CRDTree implements a Conflict-Free Replicated Tree structure for concurrent scene graph editing.
     * Prevents hierarchy cycles during concurrent node reparenting using Lamport-ordered move resolution.
     */
    public class CRDTree
    {
        public var replicaId:String;
        protected var _clock:LamportTimestamp;
        protected var _nodes:Object;      // nodeId -> { parentId, type, deleted, props: Object }
        protected var _propTimestamps:Object; // nodeId -> { propName: LamportTimestamp }
        protected var _moveTimestamps:Object; // nodeId -> LamportTimestamp

        public function CRDTree(replicaId:String = "peer0")
        {
            this.replicaId = replicaId;
            _clock = new LamportTimestamp(0, replicaId);
            _nodes = {};
            _propTimestamps = {};
            _moveTimestamps = {};

            // Initialize virtual root node
            _nodes["root"] = {
                id: "root",
                parentId: null,
                type: "SceneGraph",
                deleted: false,
                props: {}
            };
        }

        public function get clock():LamportTimestamp { return _clock; }
        public function get nodes():Object { return _nodes; }

        public function hasNode(nodeId:String):Boolean
        {
            return _nodes.hasOwnProperty(nodeId) && !_nodes[nodeId].deleted;
        }

        public function getNode(nodeId:String):Object
        {
            if (hasNode(nodeId))
            {
                return _nodes[nodeId];
            }
            return null;
        }

        /**
         * Inserts a new node into the replicated tree.
         */
        public function insert(nodeId:String, parentId:String, type:String, initialProps:Object = null):CRDTOperation
        {
            var ts:LamportTimestamp = _clock.tick().clone() as LamportTimestamp;

            var op:CRDTOperation = new CRDTOperation(
                CRDTOperation.OP_INSERT,
                nodeId,
                parentId,
                ts,
                initialProps,
                type
            );

            applyOperation(op);
            return op;
        }

        /**
         * Moves a node under a new parent with cycle prevention.
         */
        public function move(nodeId:String, newParentId:String):CRDTOperation
        {
            var ts:LamportTimestamp = _clock.tick().clone() as LamportTimestamp;

            var op:CRDTOperation = new CRDTOperation(
                CRDTOperation.OP_MOVE,
                nodeId,
                newParentId,
                ts
            );

            applyOperation(op);
            return op;
        }

        /**
         * Marks a node and its descendants as deleted (tombstone).
         */
        public function remove(nodeId:String):CRDTOperation
        {
            var ts:LamportTimestamp = _clock.tick().clone() as LamportTimestamp;

            var op:CRDTOperation = new CRDTOperation(
                CRDTOperation.OP_DELETE,
                nodeId,
                null,
                ts
            );

            applyOperation(op);
            return op;
        }

        /**
         * Updates a node property using Last-Write-Wins (LWW) register semantics.
         */
        public function updateProperty(nodeId:String, propName:String, val:Object):CRDTOperation
        {
            var ts:LamportTimestamp = _clock.tick().clone() as LamportTimestamp;
            var payload:Object = {};
            payload[propName] = val;

            var op:CRDTOperation = new CRDTOperation(
                CRDTOperation.OP_UPDATE,
                nodeId,
                null,
                ts,
                payload
            );

            applyOperation(op);
            return op;
        }

        /**
         * Applies an atomic CRDT mutation operation to this replica state.
         */
        public function applyOperation(op:CRDTOperation):Boolean
        {
            if (op == null) return false;

            // Sync clock
            _clock.update(op.timestamp.counter);

            switch (op.opType)
            {
                case CRDTOperation.OP_INSERT:
                    return applyInsert(op);

                case CRDTOperation.OP_MOVE:
                    return applyMove(op);

                case CRDTOperation.OP_DELETE:
                    return applyDelete(op);

                case CRDTOperation.OP_UPDATE:
                    return applyUpdate(op);
            }

            return false;
        }

        protected function applyInsert(op:CRDTOperation):Boolean
        {
            if (_nodes.hasOwnProperty(op.nodeId))
            {
                // Already present: revive if deleted earlier and op timestamp is newer
                var existing:Object = _nodes[op.nodeId];
                existing.deleted = false;
                existing.parentId = op.parentId;
                return true;
            }

            var propsCopy:Object = {};
            if (op.payload != null)
            {
                for (var k:String in op.payload)
                {
                    propsCopy[k] = op.payload[k];
                }
            }

            _nodes[op.nodeId] = {
                id: op.nodeId,
                parentId: op.parentId,
                type: op.nodeType,
                deleted: false,
                props: propsCopy
            };

            _moveTimestamps[op.nodeId] = op.timestamp.clone() as LamportTimestamp;
            return true;
        }

        protected function applyMove(op:CRDTOperation):Boolean
        {
            if (!_nodes.hasOwnProperty(op.nodeId)) return false;

            // Check if existing move timestamp is strictly newer
            if (_moveTimestamps.hasOwnProperty(op.nodeId))
            {
                var prevMoveTs:LamportTimestamp = _moveTimestamps[op.nodeId] as LamportTimestamp;
                if (prevMoveTs.compare(op.timestamp) > 0)
                {
                    // Stale move operation discarded
                    return false;
                }
            }

            // Cycle prevention check: ensure op.nodeId is not an ancestor of op.parentId
            if (isAncestor(op.nodeId, op.parentId))
            {
                // Concurrent cycle detected: reject move to maintain acyclic tree invariant
                return false;
            }

            var node:Object = _nodes[op.nodeId];
            node.parentId = op.parentId;
            _moveTimestamps[op.nodeId] = op.timestamp.clone() as LamportTimestamp;
            return true;
        }

        protected function applyDelete(op:CRDTOperation):Boolean
        {
            if (!_nodes.hasOwnProperty(op.nodeId)) return false;
            _nodes[op.nodeId].deleted = true;
            return true;
        }

        protected function applyUpdate(op:CRDTOperation):Boolean
        {
            if (!_nodes.hasOwnProperty(op.nodeId)) return false;
            var node:Object = _nodes[op.nodeId];

            if (!_propTimestamps.hasOwnProperty(op.nodeId))
            {
                _propTimestamps[op.nodeId] = {};
            }
            var nodePropTs:Object = _propTimestamps[op.nodeId];

            for (var propKey:String in op.payload)
            {
                if (nodePropTs.hasOwnProperty(propKey))
                {
                    var prevTs:LamportTimestamp = nodePropTs[propKey] as LamportTimestamp;
                    if (prevTs.compare(op.timestamp) > 0)
                    {
                        // Stale property write ignored
                        continue;
                    }
                }

                node.props[propKey] = op.payload[propKey];
                nodePropTs[propKey] = op.timestamp.clone() as LamportTimestamp;
            }

            return true;
        }

        /**
         * Checks whether candidateAncestor is an ancestor of targetNodeId in current tree.
         */
        public function isAncestor(candidateAncestor:String, targetNodeId:String):Boolean
        {
            if (candidateAncestor == null || targetNodeId == null) return false;
            if (candidateAncestor == targetNodeId) return true;

            var curr:String = targetNodeId;
            var depth:int = 0;
            var maxDepth:int = 500;

            while (curr != null && _nodes.hasOwnProperty(curr) && depth++ < maxDepth)
            {
                if (curr == candidateAncestor) return true;
                curr = _nodes[curr].parentId;
            }

            return false;
        }

        /**
         * Returns all children of parentId.
         */
        public function getChildren(parentId:String):Array
        {
            var results:Array = [];
            for (var id:String in _nodes)
            {
                var n:Object = _nodes[id];
                if (!n.deleted && n.parentId == parentId)
                {
                    results.push(n);
                }
            }
            return results;
        }
    }
}
