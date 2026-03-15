// assets/js/lang-detect.js
(function () {
  var stored = localStorage.getItem('blog_preferred_lang');
  if (stored === 'ko' || stored === 'en') {
    window.location.replace('/' + stored + '/');
    return;
  }
  var lang = (navigator.language || navigator.userLanguage || 'en').toLowerCase();
  var target = lang.startsWith('ko') ? 'ko' : 'en';
  localStorage.setItem('blog_preferred_lang', target);
  window.location.replace('/' + target + '/');
})();
