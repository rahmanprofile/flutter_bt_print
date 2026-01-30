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

class FlutterBtPrintPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_bt_print")
        channel.setMethodCallHandler(this)
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
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

            "printText" -> {
                val text = call.argument<String>("text")
                if (text != null) {
                    printTextInternal(text)
                }
                result.success(true)
            }

            "disconnect" -> {
                try {
                    outputStream?.close()
                    socket?.close()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                socket = null
                outputStream = null
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ===== REAL CONNECTION =====
    private fun connectPrinter(address: String): Boolean {
        return try {
            if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
                false
            } else {
                val device = bluetoothAdapter!!.getRemoteDevice(address)
                val uuid =
                    UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

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

    // ===== REAL PRINTING =====
    private fun printTextInternal(text: String) {
        try {
            outputStream?.write(text.toByteArray(Charsets.UTF_8))
            outputStream?.write(byteArrayOf(0x0A, 0x0A))
            outputStream?.flush()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
