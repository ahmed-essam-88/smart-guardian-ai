package com.smartguardian.smart_guardian_ai

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val sppUuid: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val main = Handler(Looper.getMainLooper())
    private var socket: BluetoothSocket? = null
    private var dataSink: EventChannel.EventSink? = null
    private var scanSink: EventChannel.EventSink? = null
    @Volatile private var reading = false
    private var scanReceiver: BroadcastReceiver? = null

    private val adapter: BluetoothAdapter?
        get() = (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private fun hasBtPermission(): Boolean {
        if (Build.VERSION.SDK_INT < 31) return true
        return ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestPerms() {
        val perms = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= 31) {
            perms += Manifest.permission.BLUETOOTH_CONNECT
            perms += Manifest.permission.BLUETOOTH_SCAN
        } else {
            perms += Manifest.permission.ACCESS_FINE_LOCATION
        }
        if (Build.VERSION.SDK_INT >= 33) perms += Manifest.permission.POST_NOTIFICATIONS
        ActivityCompat.requestPermissions(this, perms.toTypedArray(), 77)
    }

    private fun emit(event: String, data: String) {
        main.post { dataSink?.success(mapOf("event" to event, "data" to data)) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        EventChannel(messenger, "smart_guardian/bluetooth_data").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) { dataSink = sink }
                override fun onCancel(args: Any?) { dataSink = null }
            })
        EventChannel(messenger, "smart_guardian/bluetooth_scan").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) { scanSink = sink; startDiscovery() }
                override fun onCancel(args: Any?) { stopDiscovery(); scanSink = null }
            })

        MethodChannel(messenger, "smart_guardian/bluetooth").setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> result.success(adapter?.isEnabled == true)
                "getPaired" -> {
                    if (!hasBtPermission()) { requestPerms(); result.success(emptyList<Any>()); return@setMethodCallHandler }
                    result.success(pairedList())
                }
                "stopDiscovery" -> { stopDiscovery(); result.success(null) }
                "connect" -> {
                    val addr = call.argument<String>("address")
                    if (addr == null) { result.success(false); return@setMethodCallHandler }
                    if (!hasBtPermission()) { requestPerms(); result.success(false); return@setMethodCallHandler }
                    thread {
                        val ok = connectTo(addr)
                        main.post { result.success(ok) }
                    }
                }
                "disconnect" -> { closeSocket(); result.success(null) }
                "isConnected" -> result.success(socket?.isConnected == true)
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "smart_guardian/location").setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocation" -> fetchLocation { map -> result.success(map) }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "smart_guardian/notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "ensureChannel" -> { ensureChannel(); result.success(null) }
                "show" -> {
                    val id = call.argument<Int>("id") ?: 1
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    result.success(showNotification(id, title, body))
                }
                else -> result.notImplemented()
            }
        }
        if (Build.VERSION.SDK_INT >= 33) requestPerms()
    }

    /** Best-effort device location with no Google services or API key. */
    @SuppressLint("MissingPermission")
    private fun fetchLocation(done: (Map<String, Any>?) -> Unit) {
        val granted =
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!granted) { done(null); return }
        val lm = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { try { lm.isProviderEnabled(it) } catch (e: Exception) { false } }
        fun toMap(l: Location): Map<String, Any> = mapOf(
            "lat" to l.latitude,
            "lon" to l.longitude,
            "accuracy" to l.accuracy.toDouble(),
            "ageSec" to ((System.currentTimeMillis() - l.time) / 1000).toInt()
        )
        // Newest last-known fix (used as a fallback).
        var best: Location? = null
        for (p in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)) {
            try {
                val l = lm.getLastKnownLocation(p)
                if (l != null && (best == null || l.time > best!!.time)) best = l
            } catch (e: Exception) {}
        }
        if (providers.isEmpty()) {
            done(best?.let { toMap(it) }); return
        }
        var finished = false
        val listeners = mutableListOf<LocationListener>()
        fun finish(l: Location?) {
            if (finished) return
            finished = true
            listeners.forEach { try { lm.removeUpdates(it) } catch (e: Exception) {} }
            val chosen = l ?: best
            done(chosen?.let { toMap(it) })
        }
        for (p in providers) {
            val listener = object : LocationListener {
                override fun onLocationChanged(loc: Location) { finish(loc) }
                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }
            listeners.add(listener)
            try { lm.requestLocationUpdates(p, 0L, 0f, listener, Looper.getMainLooper()) } catch (e: Exception) {}
        }
        main.postDelayed({ finish(null) }, 10000)
    }

    @SuppressLint("MissingPermission")
    private fun pairedList(): List<Map<String, String>> =
        try {
            adapter?.bondedDevices?.map {
                mapOf("name" to (it.name ?: "Unknown"), "address" to it.address)
            } ?: emptyList()
        } catch (e: SecurityException) { emptyList() }

    @SuppressLint("MissingPermission")
    private fun startDiscovery() {
        if (!hasBtPermission()) { requestPerms(); return }
        val a = adapter ?: return
        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, i: Intent?) {
                if (i?.action == BluetoothDevice.ACTION_FOUND) {
                    val d: BluetoothDevice? = i.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    if (d != null) scanSink?.success(mapOf("event" to "device",
                        "name" to (d.name ?: "Unknown"), "address" to d.address))
                }
            }
        }
        registerReceiver(scanReceiver, IntentFilter(BluetoothDevice.ACTION_FOUND))
        try { a.startDiscovery() } catch (e: SecurityException) {}
    }

    @SuppressLint("MissingPermission")
    private fun stopDiscovery() {
        try { adapter?.cancelDiscovery() } catch (e: SecurityException) {}
        scanReceiver?.let { try { unregisterReceiver(it) } catch (e: Exception) {} }
        scanReceiver = null
    }

    @SuppressLint("MissingPermission")
    private fun connectTo(address: String): Boolean {
        closeSocket()
        return try {
            val a = adapter ?: return false
            a.cancelDiscovery()
            val device = a.getRemoteDevice(address)
            val s = device.createRfcommSocketToServiceRecord(sppUuid)
            s.connect()
            socket = s
            startReader(s)
            true
        } catch (e: Exception) {
            emit("error", e.message ?: "connection failed")
            false
        }
    }

    private fun startReader(s: BluetoothSocket) {
        reading = true
        thread {
            val buf = StringBuilder()
            val bytes = ByteArray(256)
            try {
                val input = s.inputStream
                while (reading) {
                    val n = input.read(bytes)
                    if (n < 0) break
                    for (i in 0 until n) {
                        val ch = bytes[i].toInt().toChar()
                        if (ch == '\n') {
                            val line = buf.toString().trim()
                            buf.setLength(0)
                            if (line.isNotEmpty()) emit("line", line)
                        } else if (buf.length < 200) {
                            buf.append(ch)
                        } else {
                            buf.setLength(0)
                        }
                    }
                }
            } catch (e: Exception) {
                // connection dropped
            }
            if (reading) {
                reading = false
                closeSocket()
                emit("state", "disconnected")
            }
        }
    }

    private fun closeSocket() {
        reading = false
        try { socket?.close() } catch (e: Exception) {}
        socket = null
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = getSystemService(NotificationManager::class.java)
            val ch = NotificationChannel("emergency_alerts", "Emergency alerts",
                NotificationManager.IMPORTANCE_HIGH)
            ch.description = "High-priority fire risk alerts"
            nm.createNotificationChannel(ch)
        }
    }

    private fun showNotification(id: Int, title: String, body: String): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED) return false
        ensureChannel()
        val n = NotificationCompat.Builder(this, "emergency_alerts")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .build()
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(id, n)
        return true
    }

    override fun onDestroy() {
        stopDiscovery()
        closeSocket()
        super.onDestroy()
    }
}
