package com.lyamfi.app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MarketWidgetProvider extends AppWidgetProvider {
    private static final ExecutorService EXECUTOR = Executors.newSingleThreadExecutor();

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_market);
            WidgetActions.click(views, R.id.widget_root, context, "/dashboard", 10);
            manager.updateAppWidget(id, views);
            EXECUTOR.execute(() -> {
                try {
                    List<MarketData.Quote> quotes = MarketData.bySymbol(Arrays.asList(
                            "CSEMA:MASI", "CSEMA:MSI20", "CSEMA:MASI20"));
                    MarketData.Quote masi = null, masi20 = null;
                    for (MarketData.Quote quote : quotes) {
                        String symbol = quote.ticker.toUpperCase();
                        if (symbol.endsWith(":MASI")) masi = quote;
                        if (symbol.contains("20")) masi20 = quote;
                    }
                    if (masi != null) setQuote(views, R.id.masi_price, R.id.masi_change, masi);
                    if (masi20 != null) setQuote(views, R.id.masi20_price, R.id.masi20_change, masi20);
                    views.setTextViewText(R.id.updated, "Cours TradingView · MAD/points");
                } catch (Exception error) {
                    views.setTextViewText(R.id.updated, "Cours indisponibles · toucher pour rouvrir");
                }
                manager.updateAppWidget(id, views);
            });
        }
    }

    private static void setQuote(RemoteViews views, int priceId, int changeId, MarketData.Quote quote) {
        views.setTextViewText(priceId, MarketData.price(quote.price));
        views.setTextViewText(changeId, MarketData.change(quote.change));
        views.setTextColor(changeId, MarketData.color(quote.change));
    }
}
