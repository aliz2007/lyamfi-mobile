package com.lyamfi.app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import java.util.Calendar;
import java.util.Locale;
import java.util.TimeZone;

public class SessionWidgetProvider extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        Calendar now = Calendar.getInstance(TimeZone.getTimeZone("Africa/Casablanca"));
        int day = now.get(Calendar.DAY_OF_WEEK);
        int minutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE);
        boolean weekday = day != Calendar.SATURDAY && day != Calendar.SUNDAY;
        boolean open = weekday && minutes >= 570 && minutes < 930;
        String detail;
        if (!weekday) detail = "Fermée · week-end";
        else if (minutes < 570) detail = "Ouvre à 09:30 · heure de Casablanca";
        else if (minutes >= 930) detail = "Fermée · prochaine séance 09:30";
        else detail = "Séance continue · jusqu’à 15:30";
        String time = String.format(Locale.FRANCE, "%02d:%02d · Casablanca",
                now.get(Calendar.HOUR_OF_DAY), now.get(Calendar.MINUTE));
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_session);
            views.setTextViewText(R.id.session_status, open ? "Marché ouvert" : "Marché fermé");
            views.setTextColor(R.id.session_status, open ? 0xFF55D69E : 0xFFE7C56B);
            views.setTextViewText(R.id.session_detail, detail);
            views.setTextViewText(R.id.session_time, time);
            WidgetActions.click(views, R.id.widget_root, context, "/bourse", 40);
            manager.updateAppWidget(id, views);
        }
    }
}
