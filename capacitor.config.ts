import type { CapacitorConfig } from "@capacitor/cli";

const config: CapacitorConfig = {
  appId: "com.lyamfi.app",
  appName: "Lyamfi",
  webDir: "www",
  backgroundColor: "#080807",
  server: {
    // The app is a native shell around the live product. Publishing from
    // Lovable therefore updates the app without another store submission.
    url: "https://lyamfi.lovable.app",
    cleartext: false,
    allowNavigation: ["lyamfi.lovable.app", "*.supabase.co"],
  },
  ios: {
    backgroundColor: "#080807",
    contentInset: "never",
    allowsLinkPreview: false,
    scrollEnabled: true,
  },
  android: {
    backgroundColor: "#080807",
    allowMixedContent: false,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 1200,
      launchAutoHide: true,
      backgroundColor: "#080807",
      androidSplashResourceName: "splash",
      androidScaleType: "CENTER_CROP",
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true,
    },
    StatusBar: {
      style: "DARK",
      backgroundColor: "#080807",
      overlaysWebView: false,
    },
    PushNotifications: {
      presentationOptions: ["badge", "sound", "alert"],
    },
  },
};

export default config;
