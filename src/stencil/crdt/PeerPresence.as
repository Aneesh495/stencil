package stencil.crdt
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.geom.Point2D;

    /**
     * PeerPresence tracks ephemeral collaborator state: cursor positions, selections, and activity heartbeats.
     */
    public class PeerPresence implements ICloneable, ISerializable
    {
        public var peerId:String;
        public var userName:String;
        public var color:uint;
        public var cursor:Point2D;
        public var selectedNodeIds:Array; // Array of String
        public var lastActive:Number;

        public function PeerPresence(
            peerId:String = "",
            userName:String = "Guest",
            color:uint = 0xFF3B82F6
        )
        {
            this.peerId = peerId;
            this.userName = userName;
            this.color = color;
            this.cursor = new Point2D(0.0, 0.0);
            this.selectedNodeIds = [];
            this.lastActive = new Date().time;
        }

        public function heartbeat(x:Number, y:Number, selections:Array = null):void
        {
            cursor.set(x, y);
            if (selections != null)
            {
                selectedNodeIds = selections.slice();
            }
            lastActive = new Date().time;
        }

        public function isOnline(timeoutMs:Number = 10000.0):Boolean
        {
            var now:Number = new Date().time;
            return (now - lastActive) <= timeoutMs;
        }

        public function clone():Object
        {
            var p:PeerPresence = new PeerPresence(peerId, userName, color);
            p.cursor = cursor.clone() as Point2D;
            p.selectedNodeIds = selectedNodeIds.slice();
            p.lastActive = lastActive;
            return p;
        }

        public function toJSON():Object
        {
            return {
                peerId: peerId,
                userName: userName,
                color: color,
                cursor: cursor.toJSON(),
                selectedNodeIds: selectedNodeIds.slice(),
                lastActive: lastActive
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                if (data.peerId != null) peerId = String(data.peerId);
                if (data.userName != null) userName = String(data.userName);
                if (data.color != null) color = uint(data.color);
                if (data.cursor != null) cursor.fromJSON(data.cursor);
                if (data.selectedNodeIds is Array) selectedNodeIds = (data.selectedNodeIds as Array).slice();
                if (data.lastActive != null) lastActive = Number(data.lastActive);
            }
        }
    }
}
