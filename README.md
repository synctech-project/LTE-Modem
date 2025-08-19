نسخه فریمور OpenWrt 23.05.5

روترهای قابل استفاده hilink HLK7688A و hilink HLK7628N

***مراحل راه اندازی :

 1-ابتدا از طریق کابل LAN به مودم متصل شوید و نسخه فریمور 23.05.5 را نصب کنید.

 2-سپس با ایپی 192.168.1.1 وارد محیط OpenWrt شوید و بدون وارد کرد رمز،login کنید.
 
 3-سپس وارد منو network/wireless شوید و از بخش Wireless Overview قسمت Radio0 گزینه scan را بزنید:

 <img width="1192" height="198" alt="image" src="https://github.com/user-attachments/assets/fdf91107-e240-4f20-927b-ec8e9a4dbc7f" />

 


sh -c "$(wget -O- https://raw.githubusercontent.com/synctech-project/LTE-Modem/main/install.sh)"

