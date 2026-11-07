package com.lyamfi.app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class WatchlistWidgetProvider extends AppWidgetProvider {
    private static final ExecutorService EXECUTOR = Executors.newSingleThreadExecutor();
    private static final String[] SYMBOLS = {"CSEMA:ATW", "CSEMA:IAM", "CSEMA:BCP", "CSEMA:AKT"};
    private static final String[] LABELS = {"Attijariwafa Bank", "Maroc Telecom", "BCP", "Akdital"};
    private static final int[] NAMES = {R.id.watch_1, R.id.watch_2, R.id.watch_3, R.id.watch_4};
    private static final int[] PRICES = {R.id.watch_price_1, R.id.watch_price_2, R.id.watch_price_3, R.id.watch_price_4};
    private static final int[] CHANGES = {R.id.watch_change_1, R.id.watch_change_2, R.id.watch_change_3, R.id.watch_change_4};

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_watchlist);
            WidgetActions.click(views, R.id.widget_root, context, "/bourse", 30);
            manager.updateAppWidget(id, views);
            EXECUTOR.execute(() -> {
                try {
                    List<MarketData.Quote> quotes = MarketData.bySymbol(Arrays.asList(SYMBOLS));
                    Map<String, MarketData.Quote> byTicker = new HashMap<>();
                    for (MarketData.Quote quote : quotes) byTicker.put(quote.ticker, quote);
                    for (int i = 0; i < SYMBOLS.length; i++) {
                        views.setTextViewText(NAMES[i], LABELS[i]);
                        MarketData.Quote quote = byTicker.get(SYMBOLS[i]);
                        if (quote == null) continue;
                        views.setTextViewText(PRICES[i], MarketData.price(quote.price));
                        views.setTextViewText(CHANGES[i], MarketData.change(quote.change));
                        views.setTextColor(CHANGES[i], MarketData.color(quote.change));
                    }
                    views.setTextViewText(R.id.updated, "Sélection Lyamfi · MAD");
                } catch (Exception error) {
                    views.setTextViewText(R.id.updated, "Cours indisponibles · toucher pour rouvrir");
                }
                manager.updateAppWidget(id, views);
            });
        }
    }
}
