# Preservar recursos raw para notificaciones
-keep class **.R$raw { *; }
-keepclassmembers class **.R$raw { *; }

# Preservar recursos para flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }