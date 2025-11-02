package stencil.text
{
    /**
     * FontTable represents a single table record in an SFNT (TrueType/OpenType) font header.
     */
    public class FontTable
    {
        public var tag:String;
        public var checkSum:uint;
        public var offset:uint;
        public var length:uint;

        public function FontTable(tag:String = "", checkSum:uint = 0, offset:uint = 0, length:uint = 0)
        {
            this.tag = tag;
            this.checkSum = checkSum;
            this.offset = offset;
            this.length = length;
        }

        public function toString():String
        {
            return "FontTable(" + tag + ", off=" + offset + ", len=" + length + ")";
        }
    }
}
