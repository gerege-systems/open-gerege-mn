/* FOUC-аас сэргийлэх: React hydrate хийхээс ӨМНӨ загвар/хэл/харагдацыг сонгож
   <html>-д тавина. Блоклогч (head доторх sync) script тул body зурахаас өмнө
   ажиллана.

   ХОЁР ХҮРЭЭ:
   - Нэвтэрсэн апп (/me, /admin, /manager, …) → ХЭРЭГЛЭГЧийн localStorage prefs
     (preset accent + фонт/нягтрал/загвар), байхгүй бол template default.
   - Нийтийн хуудас (/, /login, …) → АДМИНы идэвхтэй LANDING THEME
     (window.__SITE_THEME__: mode/font/style + бүрэн палетр). localStorage-ыг
     эндэ үл хэрэгснэ.
   Хэл (mn/en/zh/ru) хаана ч localStorage-аар. */
(function () {
  try {
    var root = document.documentElement;
    var mqDark = function () {
      return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    };

    // Хэл.
    var lang = localStorage.getItem('gerege.lang');
    if (lang !== 'mn' && lang !== 'en' && lang !== 'zh' && lang !== 'ru') lang = 'mn';
    root.setAttribute('lang', lang);

    // Desktop бүрхүүл (Electron). preload нь хуудасны script-үүдээс ӨМНӨ
    // `window.geregeDesktop`-ыг тавьдаг тул энд аль хэдийн бэлэн — ингэснээр
    // desktop харагдац эхний зурагдалтаас тогтож, хөтчийн layout анивчихгүй.
    // `overlayTitleBar` = цонх гарчгийн мөргүй (macOS hiddenInset): аппын дээд
    // эгнээ өөрөө гарчгийн мөрийн үүрэг гүйцэтгэх тул зүүн дээд буланд
    // цонхны удирдлагад зай нөөцөлнө.
    var desk = window.geregeDesktop;
    if (desk && desk.isDesktop) {
      root.setAttribute('data-desktop', typeof desk.platform === 'string' ? desk.platform : 'unknown');
      if (desk.overlayTitleBar) {
        root.setAttribute('data-titlebar', 'overlay');
        var inset = Number(desk.titleBarInset);
        root.style.setProperty('--titlebar-inset', (inset > 0 && inset < 200 ? inset : 78) + 'px');
      }
    }

    var authed = /^\/(me|admin|manager|profile|settings)(\/|$)/.test(location.pathname);

    if (authed) {
      // ---- Нэвтэрсэн апп: хэрэглэгчийн prefs ----
      var PRESETS = ['cobalt', 'teal', 'violet', 'emerald', 'amber'];
      var uget = function (k, list, def) {
        var v = localStorage.getItem('gerege.' + k);
        return list.indexOf(v) !== -1 ? v : def;
      };
      var theme = uget('theme', ['light', 'dark', 'system'], 'light');
      var eff = theme === 'system' ? (mqDark() ? 'dark' : 'light') : theme;
      if (eff === 'dark') root.setAttribute('data-theme', 'dark');
      else root.removeAttribute('data-theme');
      root.setAttribute('data-theme-pref', theme);
      var accent = localStorage.getItem('gerege.accent');
      root.setAttribute('data-accent', PRESETS.indexOf(accent) !== -1 ? accent : 'cobalt');
      root.style.removeProperty('--dan-blue-base');
      root.removeAttribute('data-theme-custom');
      root.setAttribute('data-font', uget('font', ['inter', 'serif', 'system'], 'inter'));
      root.setAttribute('data-style', uget('style', ['comfortable', 'compact'], 'comfortable'));
      return;
    }

    // ---- Нийтийн хуудас: админы идэвхтэй landing theme ----
    var T = window.__SITE_THEME__ || {};
    var VARS = {
      bg: '--bg', surface: '--surface', surface2: '--surface-2', fg: '--fg',
      muted: '--muted', border: '--border', borderStrong: '--border-strong',
      danBlue: '--dan-blue', gold: '--gold', success: '--success', danger: '--danger',
      lpNavy: '--lp-navy', lpHeader: '--lp-header',
    };
    var pick = function (v, list, def) { return list.indexOf(v) !== -1 ? v : def; };

    var mode = pick(T.mode, ['light', 'dark', 'system'], 'light');
    var effc = mode === 'system' ? (mqDark() ? 'dark' : 'light') : mode;
    if (effc === 'dark') root.setAttribute('data-theme', 'dark');
    else root.removeAttribute('data-theme');
    root.setAttribute('data-theme-pref', mode);
    root.setAttribute('data-accent', 'cobalt'); // palette-аар дардаг тул accent хамааралгүй
    root.style.removeProperty('--dan-blue-base');
    root.setAttribute('data-font', pick(T.font, ['inter', 'serif', 'system'], 'inter'));
    root.setAttribute('data-style', pick(T.style, ['comfortable', 'compact'], 'comfortable'));

    var colors = T.colors || {};
    var any = false;
    for (var k in VARS) {
      if (Object.prototype.hasOwnProperty.call(VARS, k)) {
        var val = colors[k];
        if (typeof val === 'string' && /^#[0-9a-fA-F]{6}$/.test(val)) {
          root.style.setProperty(VARS[k], val);
          any = true;
        } else {
          root.style.removeProperty(VARS[k]);
        }
      }
    }
    if (any) root.setAttribute('data-theme-custom', '');
    else root.removeAttribute('data-theme-custom');
  } catch (e) {}
})();
