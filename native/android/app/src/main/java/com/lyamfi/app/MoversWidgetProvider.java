package com.lyamfi.app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MoversWidgetProvider extends AppWidgetProvider {
    private static final ExecutorService EXECUTOR = Executors.newSingleThreadExecutor();
    private static final int[] NAMES = {R.id.mover_1, R.id.mover_2, R.id.mover_3, R.id.mover_4};
    private static final int[] CHANGES = {R.id.mover_change_1, R.id.mover_change_2, R.id.mover_change_3, R.id.mover_change_4};

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_movers);
            WidgetActions.click(views, R.id.widget_root, context, "/bourse", 20);
            manager.updateAppWidget(id, views);
            EXECUTOR.execute(() -> {
                try {
                    List<MarketData.Quote> quotes = MarketData.movers();
                    for (int i = 0; i < NAMES.length; i++) {
                        if (i >= quotes.size()) break;
                        MarketData.Quote quote = quotes.get(i);
                        views.setTextViewText(NAMES[i], quote.name);
                        views.setTextViewText(CHANGES[i], MarketData.change(quote.change));
                        views.setTextColor(CHANGES[i], MarketData.color(quote.change));
                    }
                    views.setTextViewText(R.id.updated, "Plus fortes variations du jour");
                } catch (Exception error) {
                    views.setTextViewText(R.id.updated, "Cours indisponibles · toucher pour rouvrir");
                }
                manager.updateAppWidget(id, views);
            });
        }
    }
}
