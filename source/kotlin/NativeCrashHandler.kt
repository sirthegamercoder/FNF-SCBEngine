package com.sirthegamercoder.scbengine

import android.content.Intent
import android.util.Log
import org.haxe.extension.Extension
import java.io.PrintWriter
import java.io.StringWriter
import java.util.concurrent.atomic.AtomicBoolean

object NativeCrashHandler {

    private const val TAG = "NativeCrashHandler"
    private val installed = AtomicBoolean(false)

    @JvmStatic
    fun install() {
        if (installed.getAndSet(true)) return

        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                showCrashActivity(throwable)
            } catch (handlerError: Throwable) {
                Log.e(TAG, "Failed to open crash activity", handlerError)
            }

            if (previousHandler != null) {
                previousHandler.uncaughtException(thread, throwable)
            }
        }
    }

    @JvmStatic
    fun showCrashActivity(throwable: Throwable) {
        val activity = Extension.mainActivity ?: return
        val stackTrace = throwable.toDetailedStackTrace()

        activity.runOnUiThread {
            val intent = Intent(activity, NativeCrashActivity::class.java).apply {
                putExtra(NativeCrashActivity.EXTRA_CRASH_TITLE, throwable.javaClass.simpleName)
                putExtra(NativeCrashActivity.EXTRA_CRASH_MESSAGE, throwable.message ?: "No message")
                putExtra(NativeCrashActivity.EXTRA_CRASH_TRACE, stackTrace)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            activity.startActivity(intent)
        }
    }

    private fun Throwable.toDetailedStackTrace(): String {
        val writer = StringWriter()
        val printer = PrintWriter(writer)
        this.printStackTrace(printer)
        printer.flush()
        return writer.toString()
    }
}