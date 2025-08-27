package stencil.core
{
    /**
     * Interface for objects requiring deterministic resource cleanup and memory deallocation.
     * Prevents dangling references, releases native graphics allocations, and detaches event listeners.
     */
    public interface IDisposable
    {
        /**
         * Releases all internal resources, clears listener subscriptions, and invalidates references.
         * Must be idempotent: multiple calls should not throw errors.
         */
        function dispose():void;

        /**
         * Indicates whether the object has already been disposed.
         */
        function get isDisposed():Boolean;
    }
}
