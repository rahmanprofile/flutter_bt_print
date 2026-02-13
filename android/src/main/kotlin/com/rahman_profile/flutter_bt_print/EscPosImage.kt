package com.rahman_profile.flutter_bt_print

import android.graphics.Bitmap
import java.io.OutputStream

class EscPosImage(private val bitmap: Bitmap) {

    fun print(outputStream: OutputStream?) {
        if (outputStream == null) return

        val width = bitmap.width
        val height = bitmap.height
        val bytesPerRow = (width + 7) / 8

        // GS v 0 (raster bit image)
        outputStream.write(
            byteArrayOf(
                0x1D, 0x76, 0x30, 0x00,
                (bytesPerRow and 0xFF).toByte(),
                ((bytesPerRow shr 8) and 0xFF).toByte(),
                (height and 0xFF).toByte(),
                ((height shr 8) and 0xFF).toByte()
            )
        )

        val imageBytes = ByteArray(bytesPerRow * height)
        var index = 0

        for (y in 0 until height) {
            for (x in 0 until bytesPerRow * 8 step 8) {
                var byte = 0
                for (bit in 0..7) {
                    val px = x + bit
                    if (px < width) {
                        val color = bitmap.getPixel(px, y)
                        val r = (color shr 16) and 0xFF
                        val g = (color shr 8) and 0xFF
                        val b = color and 0xFF
                        val gray = (r + g + b) / 3
                        if (gray < 128) {
                            byte = byte or (1 shl (7 - bit))
                        }
                    }
                }
                imageBytes[index++] = byte.toByte()
            }
        }

        outputStream.write(imageBytes)
    }
}