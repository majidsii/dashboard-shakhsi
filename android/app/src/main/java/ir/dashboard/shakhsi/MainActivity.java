package ir.dashboard.shakhsi;

import android.app.Activity;
import android.content.ContentValues;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;

/**
 * داشبورد شخصی — Android wrapper.
 *
 * Loads the bundled app.html in a WebView, injects saved data before the
 * page scripts run, and persists every change to files/data.json via a
 * JavascriptInterface bridge (window.AndroidBridge). Exports are written
 * to the public Downloads collection. No permissions, no network.
 */
public class MainActivity extends Activity {

    private File dataFile;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        dataFile = new File(getFilesDir(), "data.json");

        WebView web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        web.addJavascriptInterface(new Bridge(), "AndroidBridge");
        setContentView(web);

        web.loadDataWithBaseURL(
                "https://localhost/", buildHtml(), "text/html", "utf-8", null);
    }

    @Override
    public void onBackPressed() {
        // keep the app alive in the background instead of destroying it
        moveTaskToBack(true);
    }

    /* ------------------------- page assembly ------------------------- */

    private String readAsset() throws IOException {
        InputStream in = getAssets().open("app.html");
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buf = new byte[8192];
        int n;
        while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
        in.close();
        return out.toString("UTF-8");
    }

    private String loadData() {
        if (!dataFile.exists()) return "{}";
        try (BufferedReader r = new BufferedReader(new InputStreamReader(
                new FileInputStream(dataFile), StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = r.readLine()) != null) sb.append(line).append('\n');
            String text = sb.toString();
            new JSONObject(text); // validate; throws if corrupt
            return text;
        } catch (Exception e) {
            return "{}";
        }
    }

    private String buildHtml() {
        try {
            String html = readAsset();
            // JSONObject.quote() escapes "</" so the payload can never
            // terminate the injected <script> block.
            String boot = "<script>window.__NATIVE_DATA__=JSON.parse("
                    + JSONObject.quote(loadData()) + ");</script>";
            String anchor = "<meta charset=\"UTF-8\">";
            int i = html.indexOf(anchor);
            if (i >= 0) {
                int cut = i + anchor.length();
                return html.substring(0, cut) + boot + html.substring(cut);
            }
            return html.replaceFirst("<head>", "<head>" + boot);
        } catch (IOException e) {
            return "<h1>load error</h1>";
        }
    }

    /* --------------------------- js bridge --------------------------- */

    private class Bridge {

        @JavascriptInterface
        public void saveData(String payload) {
            try {
                new JSONObject(payload); // validate before writing
                File tmp = new File(getFilesDir(), "data.json.tmp");
                try (OutputStreamWriter w = new OutputStreamWriter(
                        new FileOutputStream(tmp), StandardCharsets.UTF_8)) {
                    w.write(payload);
                    w.flush();
                }
                if (!tmp.renameTo(dataFile)) {
                    try (OutputStreamWriter w = new OutputStreamWriter(
                            new FileOutputStream(dataFile),
                            StandardCharsets.UTF_8)) {
                        w.write(payload);
                    }
                    tmp.delete();
                }
            } catch (Exception ignored) {
            }
        }

        @JavascriptInterface
        public String saveFile(String name, String content) {
            String safe = (name == null ? "file.txt" : name)
                    .replaceAll("[\\\\/:*?\"<>|]", "_").trim();
            if (safe.isEmpty()) safe = "file.txt";
            try {
                byte[] bytes = content.getBytes(StandardCharsets.UTF_8);
                if (Build.VERSION.SDK_INT >= 29) {
                    ContentValues v = new ContentValues();
                    v.put(MediaStore.Downloads.DISPLAY_NAME, safe);
                    v.put(MediaStore.Downloads.MIME_TYPE, "text/plain");
                    Uri uri = getContentResolver().insert(
                            MediaStore.Downloads.EXTERNAL_CONTENT_URI, v);
                    if (uri == null) return null;
                    try (OutputStream os =
                                 getContentResolver().openOutputStream(uri)) {
                        os.write(bytes);
                    }
                    return safe;
                } else {
                    File dir = getExternalFilesDir(
                            Environment.DIRECTORY_DOWNLOADS);
                    if (dir == null) dir = getFilesDir();
                    dir.mkdirs();
                    File f = new File(dir, safe);
                    try (OutputStream os = new FileOutputStream(f)) {
                        os.write(bytes);
                    }
                    return f.getName();
                }
            } catch (Exception e) {
                return null;
            }
        }
    }
}
