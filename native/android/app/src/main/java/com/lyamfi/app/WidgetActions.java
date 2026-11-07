package com.lyamfi.app;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.widget.RemoteViews;

final class WidgetActions {
    private WidgetActions() {}

    static PendingIntent open(Context context, String route, int requestCode) {
        Intent intent = new Intent(context, MainActivity.class)
                .setAction(Intent.ACTION_VIEW)
                .putExtra("lyamfi_route", route)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        return PendingIntent.getActivity(context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    static void click(RemoteViews views, int viewId, Context context, String route, int requestCode) {
        views.setOnClickPendingIntent(viewId, open(context, route, requestCode));
    }
}
