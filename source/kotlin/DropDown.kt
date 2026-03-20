package com.sirthegamercoder.scbengine

import android.text.Editable
import android.text.TextWatcher
import android.widget.AbsListView
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.ListView
import androidx.appcompat.app.AlertDialog
import com.sirthegamercoder.scbengine.NativeCrashHandler
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import org.haxe.extension.Extension
import org.json.JSONArray
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

object DropDown {

    const val NO_SELECTION: Int = -1
    const val CANCELED: Int = -2

    private val pendingSelection: AtomicInteger = AtomicInteger(NO_SELECTION)
    private val dialogVisible: AtomicBoolean = AtomicBoolean(false)
    private val isScrolling: AtomicBoolean = AtomicBoolean(false)
    private val scrollState: AtomicInteger = AtomicInteger(0)

    @JvmStatic
    fun showDropDown(title: String?, itemsJson: String, selectedIndex: Int): Boolean {
        NativeCrashHandler.install()
        val activity = Extension.mainActivity ?: return false
        val items = parseItems(itemsJson)
        if (items.isEmpty()) return false

        activity.runOnUiThread {
            try {
                if (dialogVisible.get()) return@runOnUiThread

                dialogVisible.set(true)
                val safeSelectedIndex = selectedIndex.coerceIn(0, items.lastIndex)
                val displayTitle = if (title.isNullOrBlank()) "Select option" else title
                val filteredItems = items.toMutableList()
                val filteredIndices = items.indices.toMutableList()

                val listView = ListView(activity).apply {
                    choiceMode = ListView.CHOICE_MODE_SINGLE

                    setOnTouchListener { v, event ->
                        when (event.action) {
                            MotionEvent.ACTION_DOWN -> {
                                v.parent.requestDisallowInterceptTouchEvent(true)
                                isScrolling.set(false)
                                scrollState.set(0)
                            }
                            MotionEvent.ACTION_MOVE -> {
                                val child = (v as ListView).getChildAt(0)
                                if (child != null && Math.abs(event.y - child.top) > 10) {
                                    isScrolling.set(true)
                                    scrollState.set(1)
                                }
                            }
                            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                                v.parent.requestDisallowInterceptTouchEvent(false)
                                v.postDelayed({
                                    isScrolling.set(false)
                                    scrollState.set(0)
                                }, 100)
                            }
                        }
                        false
                    }
                }

                val adapter = ArrayAdapter(activity, android.R.layout.simple_list_item_single_choice, filteredItems)
                listView.adapter = adapter

                listView.setOnScrollListener(object : AbsListView.OnScrollListener {
                    override fun onScrollStateChanged(view: AbsListView?, scrollState: Int) {
                        when (scrollState) {
                            AbsListView.OnScrollListener.SCROLL_STATE_IDLE -> {
                                this@DropDown.scrollState.set(0)
                                isScrolling.set(false)
                            }
                            AbsListView.OnScrollListener.SCROLL_STATE_TOUCH_SCROLL -> {
                                this@DropDown.scrollState.set(1)
                                isScrolling.set(true)
                            }
                            AbsListView.OnScrollListener.SCROLL_STATE_FLING -> {
                                this@DropDown.scrollState.set(2)
                                isScrolling.set(true)
                            }
                        }
                    }

                    override fun onScroll(view: AbsListView?, firstVisibleItem: Int, visibleItemCount: Int, totalItemCount: Int) {
                        // Not needed but must be implemented
                    }
                })

                val searchInput = TextInputEditText(activity)
                val searchLayout = TextInputLayout(activity).apply {
                    hint = "Search"
                    addView(
                        searchInput,
                        LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
                    )
                }

                val container = LinearLayout(activity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dp(20), dp(8), dp(20), 0)
                    addView(searchLayout, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
                    addView(
                        listView,
                        LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(280))
                    )
                }

                var dialogRef: AlertDialog? = null

                fun refreshList(query: String?) {
                    val trimmed = query?.trim()?.lowercase() ?: ""
                    filteredItems.clear()
                    filteredIndices.clear()

                    for (index in items.indices) {
                        val item = items[index]
                        if (trimmed.isEmpty() || item.lowercase().contains(trimmed)) {
                            filteredItems.add(item)
                            filteredIndices.add(index)
                        }
                    }

                    adapter.notifyDataSetChanged()
                    val selectedFilteredIndex = filteredIndices.indexOf(safeSelectedIndex)
                    if (selectedFilteredIndex >= 0) {
                        listView.setItemChecked(selectedFilteredIndex, true)
                        listView.setSelection(selectedFilteredIndex)
                    } else {
                        listView.clearChoices()
                    }
                }

                searchInput.addTextChangedListener(object : TextWatcher {
                    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                    override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                        refreshList(s?.toString())
                    }
                    override fun afterTextChanged(s: Editable?) {}
                })

                listView.setOnItemClickListener { _, _, position, _ ->
                    if (!isScrolling.get() && position >= 0 && position < filteredIndices.size) {
                        pendingSelection.set(filteredIndices[position])
                        dialogRef?.dismiss()
                    }
                }

                dialogRef = MaterialAlertDialogBuilder(activity)
                    .setTitle(displayTitle)
                    .setView(container)
                    .setNegativeButton(android.R.string.cancel) { _, _ ->
                        pendingSelection.set(CANCELED)
                    }
                    .setOnCancelListener {
                        pendingSelection.set(CANCELED)
                    }
                    .setOnDismissListener {
                        dialogVisible.set(false)
                        isScrolling.set(false)
                    }
                    .show()

                refreshList(null)
            } catch (throwable: Throwable) {
                dialogVisible.set(false)
                isScrolling.set(false)
                pendingSelection.set(CANCELED)
                NativeCrashHandler.showCrashActivity(throwable)
            }
        }

        return true
    }

    @JvmStatic
    fun pollSelection(): Int {
        val currentValue = pendingSelection.get()
        if (currentValue == NO_SELECTION) return NO_SELECTION

        pendingSelection.set(NO_SELECTION)
        return currentValue
    }

    @JvmStatic
    fun isDialogVisible(): Boolean {
        return dialogVisible.get()
    }

    private fun parseItems(itemsJson: String): List<String> {
        return try {
            val json = JSONArray(itemsJson)
            buildList(json.length()) {
                for (index in 0 until json.length()) {
                    add(json.optString(index, ""))
                }
            }
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun dp(value: Int): Int {
        val activity = Extension.mainActivity ?: return value
        return (value * activity.resources.displayMetrics.density).toInt()
    }

    @JvmStatic
    fun isScrolling(): Boolean {
        return isScrolling.get()
    }

    @JvmStatic
    fun getScrollState(): Int {
        return scrollState.get()
    }
}