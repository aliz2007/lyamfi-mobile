package com.lyamfi.app;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.webkit.WebView;
import com.getcapacitor.BridgeActivity;

/** Native entry point: live Lyamfi content, safe deep links and notifications. */
public class MainActivity extends BridgeActivity {
    private static final String WEB_ORIGIN = "https://lyamfi.lovable.app";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        createNotificationChannel();
        openRoute(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        openRoute(intent);
    }

    private void openRoute(Intent intent) {
        if (intent == null) return;
        String route = intent.getStringExtra("lyamfi_route");
        Uri data = intent.getData();
        if (route == null && data != null) {
            route = data.getPath();
            if ((route == null || route.isEmpty()) && data.getHost() != null
                    && !data.getHost().equals("lyamfi.lovable.app")) {
                route = "/" + data.getHost();
            }
        }
        if (route == null || !route.matches("/(dashboard|bourse|portefeuille|classement|academie|actualites|simulateurs|macroeconomie)([/?].*)?")) {
            return;
        }
        final String target = WEB_ORIGIN + route;
        WebView webView = getBridge().getWebView();
        if (webView != null) webView.post(() -> webView.loadUrl(target));
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationManager manager = getSystemService(NotificationManager.class);
        if (manager == null) return;
        NotificationChannel channel = new NotificationChannel(
                "market_alerts", "Alertes de marché", NotificationManager.IMPORTANCE_DEFAULT);
        channel.setDescription("Séance, marchés et nouveautés Lyamfi");
        manager.createNotificationChannel(channel);
    }
}
