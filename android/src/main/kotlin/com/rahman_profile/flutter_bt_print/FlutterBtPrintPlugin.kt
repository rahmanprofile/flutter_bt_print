package com.rahman_profile.flutter_bt_print

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID
import android.graphics.Bitmap
import android.graphics.BitmapFactory

class FlutterBtPrintPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    // Printer width for 58mm thermal printer
    private val printerWidthPx = 864

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_bt_print")
        channel.setMethodCallHandler(this)
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "getPlatformVersion" -> {
                val androidVersion = Build.VERSION.RELEASE
                val sdkInt = Build.VERSION.SDK_INT
                val manufacturer = Build.MANUFACTURER
                val model = Build.MODEL
                result.success("Android $androidVersion | $manufacturer $model | SDK $sdkInt")
            }

            "getBondedDevices" -> {
                val devices = bluetoothAdapter?.bondedDevices?.map {
                    mapOf(
                        "name" to it.name,
                        "address" to it.address,
                        "isConnected" to (socket?.isConnected == true)
                    )
                } ?: emptyList()
                result.success(devices)
            }

            "connect" -> {
                val address = call.argument<String>("address")
                result.success(address != null && connectPrinter(address))
            }

            "isConnected" -> {
                result.success(socket?.isConnected == true)
            }

            "disconnect" -> {
                disconnectPrinter()
                result.success(true)
            }

            "printText" -> {
                val text = call.argument<String>("text")
                if (text != null) {
                    printTextInternal(text)
                }
                result.success(true)
            }

            "printImage" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes != null) {
                    printImageInternal(bytes)
                }
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ==================== CONNECTION ====================
    private fun connectPrinter(address: String): Boolean {
        return try {
            if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
                false
            } else {
                val device = bluetoothAdapter!!.getRemoteDevice(address)
                val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                socket = device.createRfcommSocketToServiceRecord(uuid)
                bluetoothAdapter!!.cancelDiscovery()
                socket!!.connect()
                outputStream = socket!!.outputStream
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun disconnectPrinter() {
        try {
            outputStream?.close()
            socket?.close()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            socket = null
            outputStream = null
        }
    }

    // ==================== PRINT TEXT ====================
    private fun printTextInternal(text: String) {
        try {
            if (outputStream == null) return
            // Align left
            outputStream?.write(byteArrayOf(0x1B, 0x61, 0x00))
            // Text
            outputStream?.write(text.toByteArray(Charsets.UTF_8))
            // Newline
            outputStream?.write(byteArrayOf(0x0A))
            outputStream?.flush()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ==================== PRINT IMAGE / PDF ====================

    private fun printImageInternal(bytes: ByteArray) {
        try {
            if (outputStream == null) return
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return

            // Maintain aspect ratio while fitting the 108mm width
            val scaleHeight = (bitmap.height.toFloat() / bitmap.width.toFloat() * 864).toInt()
            val resized = Bitmap.createScaledBitmap(bitmap, 864, scaleHeight, true)

            val escPos = EscPosImage(resized)
            escPos.print(outputStream)

            // Feed 3 lines so the label clears the tear bar
            outputStream?.write(byteArrayOf(0x1B, 0x64, 0x03))
            outputStream?.flush()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}