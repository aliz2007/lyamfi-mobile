package com.lyamfi.app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;

public class QuickActionsWidgetProvider extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_quick_actions);
            WidgetActions.click(views, R.id.action_bourse, context, "/bourse", 51);
            WidgetActions.click(views, R.id.action_portfolio, context, "/portefeuille", 52);
            WidgetActions.click(views, R.id.action_academy, context, "/academie", 53);
            WidgetActions.click(views, R.id.action_news, context, "/actualites", 54);
            manager.updateAppWidget(id, views);
        }
    }
}
