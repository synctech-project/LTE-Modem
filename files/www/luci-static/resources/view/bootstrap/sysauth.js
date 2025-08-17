'use strict';
'require ui';
'require view';

return view.extend({
    render: function() {
        var form = document.querySelector('form'),
            btn  = document.querySelector('button');

        var dlg = ui.showModal(
            _(''),
            [].slice.call(document.querySelectorAll('section > *')),
            'login'
        );

        var logo = E('div', {
    style: 'text-align:center; margin-bottom:15px;'
}, E('img', {
    src: '/luci-static/resources/logo.png',
    alt: 'AGC Global Logo',
    style: 'max-width:180px; width:100%; height:auto;'
}));
        // درج لوگو قبل از عناصر مودال
        dlg.insertBefore(logo, dlg.firstChild);
        // ================================

        // وقتی Enter زده شد، دکمه کلیک شود
        form.addEventListener('keypress', function(ev) {
            if (ev.key === 'Enter')
                btn.click();
        });

        // رویداد کلیک روی دکمه لاگین
        btn.addEventListener('click', function() {
            dlg.querySelectorAll('*').forEach(function(node) {
                node.style.display = 'none';
            });
            dlg.appendChild(E('div', { 'class': 'spinning' }, _('Logging in…')));
            form.submit();
        });

        // فوکوس روی پسورد
        document.querySelector('input[type="password"]').focus();

        return '';
    },

    addFooter: function() {}
});
