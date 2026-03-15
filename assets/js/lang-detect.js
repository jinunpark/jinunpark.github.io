// assets/js/lang-detect.js
(function () {
  var stored = localStorage.getItem('blog_preferred_lang');
  if (stored === 'ko' || stored === 'en') {
    window.location.replace('/' + stored + '/');
    return;
  }
  var target = 'ko';
  localStorage.setItem('blog_preferred_lang', target);
  window.location.replace('/' + target + '/');
})();
