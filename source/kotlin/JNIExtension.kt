package com.sirthegamercoder.scbengine

import android.content.Intent
import android.os.Bundle
import org.haxe.extension.Extension

class JNIExtension : Extension() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NativeCrashHandler.install()
    }
    
    companion object {
        @JvmStatic
        fun showMessageBox(title: String, message: String) {
            val activity = Extension.mainActivity ?: return
            activity.runOnUiThread {
                NativeUI.showDialog(
                    context = activity,
                    title = title,
                    message = message,
                    positiveText = "OK"
                )
            }
        }
    }
}