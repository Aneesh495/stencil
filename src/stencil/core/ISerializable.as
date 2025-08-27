package stencil.core
{
    /**
     * Interface for objects providing bi-directional conversion to plain schema representations.
     */
    public interface ISerializable
    {
        /**
         * Serializes the object state into an untyped dictionary or primitive structure suitable for JSON encoding.
         * 
         * @return A serializable object representation.
         */
        function toJSON():Object;

        /**
         * Deserializes properties from a raw data dictionary into this instance.
         * 
         * @param data Raw untyped data map.
         */
        function fromJSON(data:Object):void;
    }
}
