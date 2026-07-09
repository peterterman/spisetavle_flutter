package dk.peterterman.spisetavle.scanner

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.View

class ViewfinderOverlay(context: Context, attrs: AttributeSet?) : View(context, attrs) {

    init {
        // Required so CLEAR mode works and does NOT black out the camera preview
        setLayerType(LAYER_TYPE_SOFTWARE, null)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val width = width.toFloat()
        val height = height.toFloat()

        val overlayPaint = Paint().apply {
            color = Color.parseColor("#88000000") // dim background
        }

        val clearPaint = Paint().apply {
            xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
        }

        // Draw dim background
        canvas.drawRect(0f, 0f, width, height, overlayPaint)

        // Cut out a transparent rectangle in the center
        val rectWidth = width * 0.8f
        val rectHeight = height * 0.3f
        val left = (width - rectWidth) / 2
        val top = (height - rectHeight) / 2
        val right = left + rectWidth
        val bottom = top + rectHeight

        canvas.drawRoundRect(left, top, right, bottom, 40f, 40f, clearPaint)
    }
}
