package com.lyamfi.app;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

/** Small dependency-free client for the same public scanner used by Lyamfi. */
final class MarketData {
    static final class Quote {
        final String ticker;
        final String name;
        final double price;
        final double change;

        Quote(String ticker, String name, double price, double change) {
            this.ticker = ticker;
            this.name = name;
            this.price = price;
            this.change = change;
        }
    }

    private MarketData() {}

    static List<Quote> bySymbol(List<String> tickers) throws Exception {
        JSONObject body = new JSONObject();
        body.put("symbols", new JSONObject().put("tickers", new JSONArray(tickers)));
        body.put("columns", new JSONArray().put("name").put("description").put("close").put("change"));
        return scan(body);
    }

    static List<Quote> market() throws Exception {
        JSONObject body = new JSONObject();
        body.put("filter", new JSONArray().put(new JSONObject()
                .put("left", "exchange").put("operation", "equal").put("right", "CSEMA")));
        body.put("columns", new JSONArray().put("name").put("description").put("close").put("change"));
        body.put("range", new JSONArray().put(0).put(120));
        return scan(body);
    }

    private static List<Quote> scan(JSONObject body) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(
                "https://scanner.tradingview.com/morocco/scan").openConnection();
        connection.setConnectTimeout(8000);
        connection.setReadTimeout(8000);
        connection.setRequestMethod("POST");
        connection.setRequestProperty("Content-Type", "text/plain;charset=UTF-8");
        connection.setDoOutput(true);
        byte[] payload = body.toString().getBytes(StandardCharsets.UTF_8);
        try (OutputStream output = connection.getOutputStream()) {
            output.write(payload);
        }
        if (connection.getResponseCode() < 200 || connection.getResponseCode() >= 300) {
            throw new IllegalStateException("Market data unavailable");
        }
        StringBuilder text = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                connection.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) text.append(line);
        } finally {
            connection.disconnect();
        }
        JSONArray rows = new JSONObject(text.toString()).optJSONArray("data");
        List<Quote> quotes = new ArrayList<>();
        if (rows == null) return quotes;
        for (int i = 0; i < rows.length(); i++) {
            JSONArray values = rows.getJSONObject(i).getJSONArray("d");
            quotes.add(new Quote(values.optString(0), values.optString(1),
                    values.optDouble(2), values.optDouble(3)));
        }
        return quotes;
    }

    static List<Quote> movers() throws Exception {
        List<Quote> quotes = market();
        quotes.removeIf(q -> q.price <= 0 || q.ticker.toUpperCase().contains("MASI"));
        quotes.sort((a, b) -> Double.compare(Math.abs(b.change), Math.abs(a.change)));
        return new ArrayList<>(quotes.subList(0, Math.min(4, quotes.size())));
    }

    static String price(double value) {
        return String.format(java.util.Locale.FRANCE, "%,.2f", value).replace('\u00a0', ' ');
    }

    static String change(double value) {
        return String.format(java.util.Locale.FRANCE, "%+.2f %%", value);
    }

    static int color(double value) {
        return value >= 0 ? 0xFF55D69E : 0xFFFF7A85;
    }
}
