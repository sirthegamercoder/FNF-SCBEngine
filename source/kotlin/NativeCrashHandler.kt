package com.sirthegamercoder.scbengine

import android.content.Intent
import android.util.Log
import android.os.Process
import org.haxe.extension.Extension
import java.io.PrintWriter
import java.io.StringWriter
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.system.exitProcess

object NativeCrashHandler {

    private const val TAG = "NativeCrashHandler"
    private const val CRASH_ACTIVITY_WAIT_MS = 350L
    private val installed = AtomicBoolean(false)

    @JvmStatic
    fun install() {
        if (installed.getAndSet(true)) return

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                showCrashActivity(throwable)
            } catch (handlerError: Throwable) {
                Log.e(TAG, "Failed to open crash activity", handlerError)
            } finally {
                try {
                    Thread.sleep(CRASH_ACTIVITY_WAIT_MS)
                } catch (_: InterruptedException) {
                }

                Process.killProcess(Process.myPid())
                exitProcess(10)
            }
        }
    }

    @JvmStatic
    fun showCrashActivity(throwable: Throwable) {
        launchCrashActivity(throwable)
    }

    private fun launchCrashActivity(throwable: Throwable) {
        val activity = Extension.mainActivity ?: return
        val stackTrace = throwable.toDetailedStackTrace()

        val context = activity.applicationContext
        val intent = Intent(context, NativeCrashActivity::class.java).apply {
            putExtra(NativeCrashActivity.EXTRA_CRASH_TITLE, throwable.javaClass.simpleName)
            putExtra(NativeCrashActivity.EXTRA_CRASH_MESSAGE, throwable.message ?: "No message")
            putExtra(NativeCrashActivity.EXTRA_CRASH_TRACE, stackTrace)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK
            )
        }

        context.startActivity(intent)
    }

    private fun Throwable.toDetailedStackTrace(): String {
        val writer = StringWriter()
        val printer = PrintWriter(writer)
        this.printStackTrace(printer)
        printer.flush()
        return writer.toString()
    }
}