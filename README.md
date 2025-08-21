> [!NOTE]
>**Framwore version 23.05.5**

> [!NOTE]
>**Can be used for hlk7688a & hlk7628n routers**

<ins>مراحل راه اندازی :</ins>

 1-ابتدا فریمور را متناسب با چیپ خود دانلود کنید سپس از طریق کابل LAN به مودم متصل شوید و ان را نصب کنید.

 -فریمور متناسب با چیپ HLK7628N:

       https://downloads.openwrt.org/releases/23.05.6/targets/ramips/mt76x8/openwrt-23.05.6-ramips-mt76x8-hilink_hlk-7628n-squashfs-sysupgrade.bin

 -فریمور متناسب با چیپ HLK7688A:

       https://downloads.openwrt.org/releases/23.05.6/targets/ramips/mt76x8/openwrt-23.05.6-ramips-mt76x8-hilink_hlk-7688a-squashfs-sysupgrade.bin

 2-سپس مرورگر خود را باز کنید و با ایپی 192.168.1.1 وارد محیط OpenWrt شوید و بدون وارد کرد رمز،login کنید.
 
 3-سپس وارد منو network/wireless شوید و از بخش Wireless Overview قسمت Radio0 گزینه scan را بزنید:

 <img width="1192" height="198" alt="image" src="https://github.com/user-attachments/assets/fdf91107-e240-4f20-927b-ec8e9a4dbc7f" />

4-سپس اینترنت و HotSpot موبایل خود را روشن کرده و از لیست WiFi های اسکن شده توسط مودم،HotSpot موبایل خود را پیدا کنید و روی Join کلیک کنید:

<img width="1714" height="162" alt="image" src="https://github.com/user-attachments/assets/8a5747a4-8d87-429c-82fc-95b3d01504b4" />

5-سپس از صفحه باز شده قسمت name of the new network را "حتما wwan2"قرار دهید و در قسمت WPA passphrase رمز HotSpot موبایل خود را وارد کنید و submit را بزنید،سپس از صفحه باز شده save را بزنید.بعد از save کردن دکمه save & apply را بزنید تا به شبکه وای فای متصل شود و اینترنت موبایل شما را دریافت کند.

<img width="1756" height="581" alt="image" src="https://github.com/user-attachments/assets/5e4b53ed-f0d6-45ea-b40d-bd6165b7be8e" />

در صورتی که اتصال برقرار شده باشد،سیستم شما نیز اینترنت دریافت میکند و برای تست اتصال یک عبارتی را داخل گوگل سرچ کنید و از اتصال صحیح مطمعن شوید و بعد بقیه مراحل را جلو بروید.

6-سپس وارد نرم افزار putty شوید و در قسمت Host Name (or IP address) ایپی 192.168.1.1 وارد کنید و PORT را روی 22 قرار دهید،قسمت Connection type را نیز SSH قرار دهید و OPEN را بزنید.

از صفحه باز شده،رو به روی login as تایپ کنید root و enter را بزنید.

سپس دستور زیر را کپی کنید و در محیط PUTTY با زدن کلیک راست،ان را paste کنید و سپس enter بزنید و منتظر بمانید دستورات به ترتیب اجرا شوند پیغام Complated را به شما نمایش دهد.

```<pre>
sh -c "$(wget -O- https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/install.sh)"

https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/passwall-packages

