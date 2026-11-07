package com.lyamfi.app;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;
import java.util.Calendar;

public class EducationWidgetProvider extends AppWidgetProvider {
    private static final String[] TIPS = {
        "Diversifier ne consiste pas à tout acheter, mais à éviter qu’un seul risque décide de tout.",
        "Un cours qui baisse ne rend pas une action bon marché. Regardez d’abord les bénéfices.",
        "Le rendement du dividende monte quand le cours baisse : ce n’est pas toujours une bonne nouvelle.",
        "Investir régulièrement lisse le prix d’entrée, mais ne supprime pas le risque de marché.",
        "Le PER compare un prix à un bénéfice. Il ne se lit qu’avec la croissance et la qualité de ce bénéfice.",
        "Un ordre à cours limité maîtrise le prix, pas l’exécution.",
        "Votre horizon de placement est aussi important que le titre choisi."
    };

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        int day = Calendar.getInstance().get(Calendar.DAY_OF_YEAR);
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_education);
            views.setTextViewText(R.id.education_tip, TIPS[day % TIPS.length]);
            WidgetActions.click(views, R.id.widget_root, context, "/academie", 60);
            manager.updateAppWidget(id, views);
        }
    }
}
