package com.example.untitled17

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.core.content.edit
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

class MainActivity : FlutterActivity(), SensorEventListener{
    lateinit var sm: SensorManager
    lateinit var methodChannel: MethodChannel
    var long: Long = 0
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sm = getSystemService(SENSOR_SERVICE) as SensorManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger,"wasd")
        methodChannel.setMethodCallHandler { call, result ->
            val sp = getSharedPreferences("MoveGo_spf",MODE_PRIVATE)
            when(call.method){
                "save"->{
                    val js = call.argument<String>("json")
                    sp.edit { putString("app_data",js) }
                    result.success(true)
                }
                "load"->{
                    val js = sp.getString("app_data","")
                    result.success(js)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        sm.registerListener(this,sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),1)
    }

    override fun onPause() {
        super.onPause()
        sm.unregisterListener(this)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            val x = it.values[0]
            val y = it.values[1]
            val z = it.values[2]
            if(sqrt(x*x+y*y+z*z) > 15){
                val n = System.currentTimeMillis()
                if(n-long > 500){
                    long = n
                    methodChannel.invokeMethod("onsss",null)
                }
            }
        }
    }
}
