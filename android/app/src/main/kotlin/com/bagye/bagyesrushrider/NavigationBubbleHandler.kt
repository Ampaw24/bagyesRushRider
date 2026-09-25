package com.bagye.bagyesrushrider

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * Android's official Bubbles API (API 30+) — a floating, draggable "chat
 * head" the rider can tap to jump straight back into the app while
 * turn-by-turn runs in an external Maps app.
 *
 * Deliberately NOT `SYSTEM_ALERT_WINDOW`: that special permission is a
 * known overlay-phishing vector and is heavily scrutinised by Play Store
 * review. Bubbles need no such permission from this app — only the
 * standard notification permission it already requests, plus a per-app
 * "Bubbles" toggle the *rider* opts into from system settings (see
 * [openBubbleSettings]; there is no way for an app to grant this to
 * itself).
 *
 * This posts a *conversation* bubble — a long-lived dynamic shortcut +
 * `MessagingStyle`, anchoring `BubbleMetadata` to the shortcut id rather
 * than a bare PendingIntent+Icon. Both are valid per the public API and
 * both were built and tested here; a plain PendingIntent bubble posted
 * successfully but never floated. The conversation-shortcut path is what
 * messaging apps use and is the one OEM notification rankers are actually
 * built to recognise, so it's the more correct implementation regardless —
 * but on the Samsung One UI 5.x device this was verified against
 * (Android 13, Galaxy S20 5G), it *also* never floats: `dumpsys window` and
 * `dumpsys activity services` show no bubble-rendering component present
 * in that device's SystemUI at all, despite every app-side signal being
 * correct (channel allows bubbles, per-app and device-wide Bubbles
 * settings both on, shortcut recognised as a valid conversation). That is
 * a gap in that SystemUI build, not something fixable from app code —
 * Pixel and other AOSP-close devices are expected to render this
 * correctly. Either way this never fails to notify: when it doesn't
 * float, it's still a normal ongoing notification with a working tap
 * target.
 */
object NavigationBubbleHandler {
    private const val CHANNEL_ID = "bagyes_rush_navigation_bubble"
    private const val NOTIFICATION_ID = 90202
    private const val SHORTCUT_ID = "navigation_return_shortcut"

    // ShortcutInfo.SHORTCUT_CATEGORY_CONVERSATION's documented value — the
    // AndroidX compat class re-exposes the setter but not the constant
    // itself, so the literal is the framework's own, not a guess.
    private const val SHORTCUT_CATEGORY_CONVERSATION = "android.shortcut.conversation"

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Delivery Navigation",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "Tap-to-return bubble shown while navigating to a pickup or delivery point"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            channel.setAllowBubbles(true)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Publishes (or refreshes) the long-lived dynamic shortcut the bubble
     * anchors to. `pushDynamicShortcut` is safe to call every time — it
     * just updates the existing shortcut with this id rather than
     * duplicating it, so no separate "already registered" guard is needed.
     */
    private fun ensureShortcut(context: Context, icon: IconCompat, person: Person): Boolean {
        val shortcutIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val shortcut = ShortcutInfoCompat.Builder(context, SHORTCUT_ID)
            .setLongLived(true)
            .setShortLabel("BagyesRUSH")
            .setIcon(icon)
            .setPerson(person)
            .setCategories(setOf(SHORTCUT_CATEGORY_CONVERSATION))
            .setIntent(shortcutIntent)
            .build()
        return ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
    }

    /** Returns true once a notification (bubble-capable or not) was posted. */
    fun show(context: Context, title: String, text: String, logo: ByteArray): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false

        val bitmap = BitmapFactory.decodeByteArray(logo, 0, logo.size) ?: return false
        ensureChannel(context)

        val icon = IconCompat.createWithBitmap(bitmap)
        val person = Person.Builder()
            .setName("BagyesRUSH")
            .setIcon(icon)
            .setImportant(true)
            .setBot(true)
            .setKey("bagyesrush_app")
            .build()

        if (!ensureShortcut(context, icon, person)) return false

        val smallIconRes = context.resources.getIdentifier(
            "ic_notification", "drawable", context.packageName,
        )

        // Still used for the notification's own tap target when it isn't
        // actually floating as a bubble.
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // Anchored to the shortcut, not a PendingIntent — the OS resolves
        // the bubble's launch target from the shortcut's own intent.
        val bubbleMetadata = NotificationCompat.BubbleMetadata.Builder(SHORTCUT_ID)
            .setDesiredHeight(600)
            .setAutoExpandBubble(false)
            .setSuppressNotification(true)
            .build()

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(if (smallIconRes != 0) smallIconRes else context.applicationInfo.icon)
            .setLargeIcon(bitmap)
            // MessagingStyle + shortcutId + CATEGORY_MESSAGE is what actually
            // marks this a "conversation" to OEM notification rankers — the
            // combination bubble eligibility is keyed off, confirmed against
            // this device's behaviour, not assumed from the docs alone.
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setShortcutId(SHORTCUT_ID)
            .setStyle(
                NotificationCompat.MessagingStyle(person)
                    .setConversationTitle(title)
                    .addMessage(text, System.currentTimeMillis(), person),
            )
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(pendingIntent)
            .setBubbleMetadata(bubbleMetadata)
            .addPerson(person)
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        return true
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /**
     * There is no runtime permission dialog for Bubbles — the rider has to
     * flip it on manually. This is the closest the OS offers to a direct
     * link there.
     */
    fun openBubbleSettings(context: Context) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Intent(Settings.ACTION_APP_NOTIFICATION_BUBBLE_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            }
        } else {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            }
        }
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }
}
