<div dir="rtl">

# داشبورد شخصی 🧊

اپ دسکتاپ سبک برای اوبونتو با ظاهر **Liquid Glass** — مدیریت کارها + امور مالی شخصی، کاملاً فارسی و با تقویم جلالی. همه‌ی داده‌ها به‌صورت خودکار روی دیسک ذخیره می‌شوند.

| حالت روشن | حالت تاریک |
|---|---|
| ![light](assets/screenshots/light.png) | ![dark](assets/screenshots/dark.png) |

## ویژگی‌ها

- **کارها:** اولویت‌بندی، جست‌وجو، مرتب‌سازی، فیلتر، حلقه‌ی پیشرفت
- **مالی:** درآمد/هزینه، بدهی و قسط، نمودار روند ۶ ماهه، نمودار دسته‌ها، هزینه‌ی هفتگی
- **خروجی:** Markdown ،CSV ،JSON و متن ساده — مستقیم در پوشه‌ی Downloads
- **ذخیره‌سازی دائمی:** هر تغییر بلافاصله در یک فایل JSON نوشته می‌شود
- حالت تاریک/روشن، فونت وزیرمتن باندل‌شده (بدون نیاز به اینترنت)، بک‌گراند شیشه‌ای متحرک

## دانلود مستقیم

نسخه مناسب سیستم‌عامل خود را مستقیماً دانلود کنید:

| سیستم‌عامل            | فایل دانلود                                                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| اوبونتو، دبیان و مینت | [دانلود فایل DEB](https://github.com/majidsii/dashboard-shakhsi/releases/download/v1.2.0/dashboard-shakhsi_1.2.0_all.deb)      |
| فدورا و اوپن‌سوزه     | [دانلود فایل RPM](https://github.com/majidsii/dashboard-shakhsi/releases/download/v1.2.0/dashboard-shakhsi-1.2.0-2.noarch.rpm) |
| ویندوز                | [دانلود نسخه ویندوز](https://github.com/majidsii/dashboard-shakhsi/releases/latest/download/DashboardShakhsi-windows.exe)      |
| macOS                 | [دانلود نسخه مک](https://github.com/majidsii/dashboard-shakhsi/releases/latest/download/DashboardShakhsi-macos.zip)            |
| اندروید               | [دانلود نسخه اندروید](https://github.com/majidsii/dashboard-shakhsi/releases/latest/download/DashboardShakhsi-android.apk)     |

برای مشاهده جزئیات نسخه‌ها و تغییرات، به بخش [Releases](https://github.com/majidsii/dashboard-shakhsi/releases/latest) مراجعه کنید.


## نصب

از بخش [Releases](../../releases) آخرین نسخه را برای سیستم‌عامل خودتان دانلود کنید:

### اوبونتو / دبیان / مینت (فایل `.deb`)

```bash
sudo apt install ./dashboard-shakhsi_*.deb
```

### فدورا / اوپن‌سوزه (فایل `.rpm`)

```bash
sudo dnf install python3-gobject gtk3 webkit2gtk4.1
sudo rpm -i --nodeps dashboard-shakhsi-*.rpm
```

### ویندوز (فایل `DashboardShakhsi-windows.exe`)

فایل را دانلود و اجرا کنید — نصب لازم ندارد. به WebView2 نیاز دارد که روی ویندوز ۱۰ و ۱۱ به‌روز از قبل نصب است.

### مک (فایل `DashboardShakhsi-macos.zip`)

فایل را باز کنید و `DashboardShakhsi.app` را به پوشه‌ی Applications بکشید. چون برنامه امضای اپل ندارد، بار اول روی آن راست‌کلیک کنید و **Open** را بزنید.

### اندروید (فایل `DashboardShakhsi-android.apk`)

فایل APK را دانلود و نصب کنید (اندروید ۷ به بالا). چون خارج از گوگل‌پلی است، هنگام نصب اجازه‌ی «نصب از منابع ناشناس» را بدهید. برنامه به اینترنت و هیچ مجوز دیگری نیاز ندارد و خروجی‌ها در پوشه‌ی Download گوشی ذخیره می‌شوند.

### سایر توزیع‌های لینوکس

```bash
sudo pacman -S python-gobject gtk3 webkit2gtk-4.1   # آرچ (نمونه)
python3 src/main.py
```

پس از نصب، «داشبورد شخصی» را در منوی برنامه‌ها اجرا کنید، یا در ترمینال:

```bash
dashboard-shakhsi
```

## محل ذخیره‌ی داده‌ها

```
لینوکس:  ~/.local/share/dashboard-shakhsi/data.json
ویندوز:  %APPDATA%\dashboard-shakhsi\data.json
مک:      ~/Library/Application Support/dashboard-shakhsi/data.json
اندروید: حافظه‌ی داخلی برنامه (با حذف برنامه پاک می‌شود — قبل از حذف، از «خروجی JSON» بک‌آپ بگیرید)
```

برای پشتیبان‌گیری کافی است همین یک فایل را کپی کنید. با حذف برنامه، داده‌ها پاک نمی‌شوند.

## ساخت از سورس

پیش‌نیاز فقط `dpkg-deb` است (روی اوبونتو از قبل نصب است):

```bash
./build-deb.sh
sudo apt install ./dist/dashboard-shakhsi_*.deb
```

اجرای مستقیم بدون نصب:

```bash
sudo apt install python3-gi gir1.2-gtk-3.0 gir1.2-webkit2-4.1
python3 src/main.py
```

حالت دیباگ (ابزار توسعه‌دهنده‌ی وب‌کیت): `dashboard-shakhsi --devtools`

## لایسنس

کد تحت لایسنس [MIT](LICENSE). فونت [وزیرمتن](https://github.com/rastikerdar/vazirmatn) تحت [SIL OFL 1.1](src/fonts/OFL.txt).

</div>
