package dk.peterterman.spisetavle.scanner

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager
import dk.peterterman.spisetavle.R
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage

class BarcodeScannerActivity : AppCompatActivity() {

    private lateinit var previewView: PreviewView

    private val CAMERA_PERMISSION = Manifest.permission.CAMERA
    private val REQUEST_CODE_CAMERA = 1001

    private var isProcessing = false
    private var cameraProvider: ProcessCameraProvider? = null

    private val scanner = BarcodeScanning.getClient()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_barcode_scan)

        previewView = findViewById(R.id.previewView)

        if (ContextCompat.checkSelfPermission(this, CAMERA_PERMISSION)
            == PackageManager.PERMISSION_GRANTED
        ) {
            startCamera()
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(CAMERA_PERMISSION),
                REQUEST_CODE_CAMERA
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQUEST_CODE_CAMERA &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            startCamera()
        } else {
            finish()
        }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }

            val analysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()

            analysis.setAnalyzer(
                ContextCompat.getMainExecutor(this)
            ) { imageProxy ->
                processImageProxy(imageProxy)
            }

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(
                    this,
                    cameraSelector,
                    preview,
                    analysis
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }

        }, ContextCompat.getMainExecutor(this))
    }

    @androidx.annotation.OptIn(ExperimentalGetImage::class)
    private fun processImageProxy(imageProxy: ImageProxy) {
        if (isProcessing) {
            imageProxy.close()
            return
        }

        val mediaImage = imageProxy.image ?: run {
            imageProxy.close()
            return
        }

        val image = InputImage.fromMediaImage(
            mediaImage,
            imageProxy.imageInfo.rotationDegrees
        )

        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                for (barcode in barcodes) {
                    val code = barcode.rawValue
                    if (!code.isNullOrEmpty()) {
                        onBarcodeDetected(code)
                        imageProxy.close()
                        return@addOnSuccessListener
                    }
                }
                imageProxy.close()
            }
            .addOnFailureListener {
                imageProxy.close()
            }
    }

    private fun onBarcodeDetected(code: String) {
        if (isProcessing) return
        isProcessing = true

        Log.d("SCAN", "Detected barcode: $code")

        cameraProvider?.unbindAll()

        val resultIntent = Intent().apply {
            putExtra("BARCODE", code)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }
}
