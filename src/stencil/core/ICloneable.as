package stencil.core
{
    /**
     * Interface for objects supporting deep or shallow duplication semantics.
     */
    public interface ICloneable
    {
        /**
         * Creates an independent duplicate of the object.
         * Implementations must perform deep copies of mutable internal components.
         * 
         * @return A cloned instance identical in state to the receiver.
         */
        function clone():Object;
    }
}
