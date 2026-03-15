---
---
// assets/js/lang-detect.js
(function () {
  var defaultLang = '{{ site.default_lang }}';
  var languages = [{% for lang in site.languages %}'{{ lang }}'{% unless forloop.last %}, {% endunless %}{% endfor %}];
  var stored = localStorage.getItem('blog_preferred_lang');
  if (languages.indexOf(stored) !== -1) {
    window.location.replace('/' + stored + '/');
    return;
  }
  localStorage.setItem('blog_preferred_lang', defaultLang);
  window.location.replace('/' + defaultLang + '/');
})();
