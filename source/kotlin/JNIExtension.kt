package com.sirthegamercoder.scbengine

import android.content.Intent
import org.haxe.extension.Extension

class JNIExtension : Extension() {
    
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