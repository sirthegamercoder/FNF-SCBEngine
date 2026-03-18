package com.sirthegamercoder.scbengine

import android.os.Bundle
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import android.content.ClipboardManager
import android.content.ClipData

class NativeCrashActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_CRASH_TITLE = "crash_title"
        const val EXTRA_CRASH_MESSAGE = "crash_message"
        const val EXTRA_CRASH_TRACE = "crash_trace"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val crashTitle = intent.getStringExtra(EXTRA_CRASH_TITLE) ?: "Native Crash"
        val crashMessage = intent.getStringExtra(EXTRA_CRASH_MESSAGE) ?: "No message"
        val crashTrace = intent.getStringExtra(EXTRA_CRASH_TRACE) ?: "No stack trace"

        title = "Crash Report"

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        }

        val header = TextView(this).apply {
            text = "${crashTitle}: ${crashMessage}"
            textSize = 16f
            setPadding(0, 0, 0, dp(12))
        }

        val scroll = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f)
        }

        val traceText = TextView(this).apply {
            text = crashTrace
            textSize = 12f
            setTextIsSelectable(true)
        }
        scroll.addView(traceText)

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }

        val copyButton = Button(this).apply {
            text = "Copy"
            setOnClickListener {
                val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("Native Crash Trace", crashTrace))
            }
        }

        val closeButton = Button(this).apply {
            text = "Close"
            setOnClickListener { finishAffinity() }
        }

        actions.addView(copyButton, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        actions.addView(closeButton, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))

        root.addView(header)
        root.addView(scroll)
        root.addView(actions)

        setContentView(root)
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }
}