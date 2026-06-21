package com.jaivik.leko

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.Locale

class BankNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE).orEmpty()
        val text = listOf(
            extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty(),
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
        ).filter { it.isNotBlank() }.joinToString(" ")
        val combined = "$title $text"
        val amount = amountRegex.find(combined)?.groupValues?.getOrNull(1)
            ?.replace(",", "")
            ?.toDoubleOrNull()

        if (amount == null || !looksLikeFinanceNotification(sbn.packageName, combined)) {
            return
        }

        val draft = JSONObject()
            .put("sourceId", sbn.key.ifBlank { "${sbn.packageName}:${sbn.postTime}" })
            .put("source", "bank_notification")
            .put("amount", amount)
            .put("date", Instant.ofEpochMilli(sbn.postTime).toString())
            .put("type", "expense")
            .put("merchant", merchantFrom(title, sbn.packageName))
            .put("categorySuggestion", categorySuggestion(combined))
            .put("confidence", 0.74)
            .put("note", "Imported from an opt-in bank notification review draft.")

        saveDraft(applicationContext, draft)
    }

    companion object {
        private const val prefsName = "leko_bank_notification_import"
        private const val draftsKey = "drafts"
        private const val activeUserIdKey = "active_user_id"
        private const val maxDrafts = 50

        private val amountRegex = Regex("""(?:CAD|USD|\$)\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{2})?)""")

        fun readDrafts(context: Context, userId: String?): List<Map<String, Any?>> {
            if (userId.isNullOrBlank()) return emptyList()
            val raw = context
                .getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                .getString(draftsKey, "[]")
            val array = JSONArray(raw)
            return List(array.length()) { index ->
                val item = array.getJSONObject(index)
                item.keys().asSequence().associateWith { key ->
                    if (item.isNull(key)) null else item.get(key)
                }
            }.filter { draft ->
                draft["userId"]?.toString() == userId
            }
        }

        fun setActiveUserId(context: Context, userId: String?) {
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            prefs.edit().apply {
                if (userId.isNullOrBlank()) {
                    remove(activeUserIdKey)
                } else {
                    putString(activeUserIdKey, userId)
                }
            }.apply()
        }

        fun clearDraftsForUser(context: Context, userId: String) {
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            val raw = prefs.getString(draftsKey, "[]") ?: "[]"
            val existing = JSONArray(raw)
            val next = JSONArray()
            for (index in 0 until existing.length()) {
                val item = existing.getJSONObject(index)
                if (item.optString("userId") == userId) continue
                next.put(item)
            }
            prefs.edit().putString(draftsKey, next.toString()).apply()
        }

        private fun saveDraft(context: Context, draft: JSONObject) {
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            val activeUserId = prefs.getString(activeUserIdKey, null)
            if (activeUserId.isNullOrBlank()) return
            draft.put("userId", activeUserId)
            val existing = JSONArray(prefs.getString(draftsKey, "[]"))
            val next = JSONArray()
            next.put(draft)
            val seen = mutableSetOf(draft.getString("sourceId"))
            for (index in 0 until existing.length()) {
                val item = existing.getJSONObject(index)
                val sourceId = item.optString("sourceId")
                if (sourceId.isBlank() || seen.contains(sourceId)) continue
                seen.add(sourceId)
                next.put(item)
                if (next.length() >= maxDrafts) break
            }
            prefs.edit().putString(draftsKey, next.toString()).apply()
        }

        private fun looksLikeFinanceNotification(packageName: String, content: String): Boolean {
            val lower = "$packageName $content".lowercase(Locale.US)
            return listOf(
                "bank",
                "rbc",
                "td",
                "cibc",
                "scotia",
                "bmo",
                "wealthsimple",
                "visa",
                "mastercard",
                "amex",
                "debit",
                "credit",
                "purchase",
                "transaction",
                "withdrawal",
                "payment",
                "spent"
            ).any(lower::contains)
        }

        private fun merchantFrom(title: String, packageName: String): String {
            return title.takeIf { it.isNotBlank() }
                ?: packageName.substringAfterLast('.')
        }

        private fun categorySuggestion(content: String): String {
            val lower = content.lowercase(Locale.US)
            return when {
                listOf("restaurant", "cafe", "coffee", "lunch", "dinner").any(lower::contains) -> "Food"
                listOf("grocery", "supermarket", "market").any(lower::contains) -> "Groceries"
                listOf("uber", "lyft", "transit", "gas", "fuel").any(lower::contains) -> "Transportation"
                listOf("pharmacy", "medical", "clinic").any(lower::contains) -> "Health"
                listOf("subscription", "bill", "utility").any(lower::contains) -> "Bills"
                else -> "Other"
            }
        }
    }
}
