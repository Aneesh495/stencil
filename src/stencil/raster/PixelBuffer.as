package stencil.raster
{
    import stencil.geom.Rect2D;

    /**
     * PixelBuffer manages a flat 32-bit ARGB frame target for CPU software rasterization.
     * Implements subpixel blending, clipping rectangles, blitting, and scanline fills.
     */
    public class PixelBuffer
    {
        public var width:int;
        public var height:int;
        public var pixels:Array; // Array of uint (0xAARRGGBB)

        public function PixelBuffer(width:int = 800, height:int = 600)
        {
            this.width = Math.max(1, width);
            this.height = Math.max(1, height);
            this.pixels = new Array(this.width * this.height);
            clear(0x00000000);
        }

        public function clear(color:uint = 0x00000000):void
        {
            var len:int = width * height;
            for (var i:int = 0; i < len; i++)
            {
                pixels[i] = color;
            }
        }

        public function setPixel(x:int, y:int, color:uint):void
        {
            if (x >= 0 && x < width && y >= 0 && y < height)
            {
                pixels[y * width + x] = color;
            }
        }

        public function getPixel(x:int, y:int):uint
        {
            if (x >= 0 && x < width && y >= 0 && y < height)
            {
                return uint(pixels[y * width + x]);
            }
            return 0;
        }

        /**
         * Blends an incoming ARGB pixel over existing pixel with subpixel coverage factor.
         */
        public function blendPixel(x:int, y:int, srcColor:uint, coverage:Number = 1.0):void
        {
            if (x < 0 || x >= width || y < 0 || y >= height || coverage <= 0.0) return;

            var idx:int = y * width + x;
            var dst:uint = uint(pixels[idx]);

            var sa:Number = (((srcColor >>> 24) & 0xFF) / 255.0) * coverage;
            if (sa <= 0.0) return;
            if (sa >= 1.0)
            {
                pixels[idx] = srcColor;
                return;
            }

            var da:Number = ((dst >>> 24) & 0xFF) / 255.0;

            var sr:Number = ((srcColor >>> 16) & 0xFF);
            var sg:Number = ((srcColor >>> 8) & 0xFF);
            var sb:Number = (srcColor & 0xFF);

            var dr:Number = ((dst >>> 16) & 0xFF);
            var dg:Number = ((dst >>> 8) & 0xFF);
            var db:Number = (dst & 0xFF);

            var outA:Number = sa + da * (1.0 - sa);
            if (outA <= 0.0)
            {
                pixels[idx] = 0;
                return;
            }

            var outR:Number = (sr * sa + dr * da * (1.0 - sa)) / outA;
            var outG:Number = (sg * sa + dg * da * (1.0 - sa)) / outA;
            var outB:Number = (sb * sa + db * da * (1.0 - sa)) / outA;

            var finalA:uint = Math.round(outA * 255) & 0xFF;
            var finalR:uint = Math.round(outR) & 0xFF;
            var finalG:uint = Math.round(outG) & 0xFF;
            var finalB:uint = Math.round(outB) & 0xFF;

            pixels[idx] = (((finalA << 24) >>> 0) | (finalR << 16) | (finalG << 8) | finalB);
        }

        /**
         * Fills a rectangular region with solid color.
         */
        public function fillRect(rect:Rect2D, color:uint):void
        {
            if (rect == null || rect.isEmpty()) return;

            var x0:int = Math.max(0, Math.floor(rect.left));
            var y0:int = Math.max(0, Math.floor(rect.top));
            var x1:int = Math.min(width, Math.ceil(rect.right));
            var y1:int = Math.min(height, Math.ceil(rect.bottom));

            for (var y:int = y0; y < y1; y++)
            {
                var rowStart:int = y * width;
                for (var x:int = x0; x < x1; x++)
                {
                    pixels[rowStart + x] = color;
                }
            }
        }

        /**
         * Blits another pixel buffer onto this buffer at target coordinates.
         */
        public function blit(src:PixelBuffer, dstX:int, dstY:int):void
        {
            if (src == null) return;

            var x0:int = Math.max(0, -dstX);
            var y0:int = Math.max(0, -dstY);
            var x1:int = Math.min(src.width, width - dstX);
            var y1:int = Math.min(src.height, height - dstY);

            for (var sy:int = y0; sy < y1; sy++)
            {
                var srcRow:int = sy * src.width;
                var dstRow:int = (dstY + sy) * width + dstX;
                for (var sx:int = x0; sx < x1; sx++)
                {
                    pixels[dstRow + sx] = src.pixels[srcRow + sx];
                }
            }
        }
    }
}
