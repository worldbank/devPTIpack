// Scroll-reactive navbar: transparent above page header, white + shadow below.
// Mirrors the GeoPovData navbar-scroll.html behaviour.
window.addEventListener('scroll', function () {
  var navbar = document.querySelector('.navbar');
  if (!navbar) return;
  var header = document.querySelector('.page-header') ||
               document.querySelector('.jumbotron') ||
               document.querySelector('.template-home .contents > .row:first-child');
  var threshold = header ? header.offsetHeight - navbar.offsetHeight : 80;
  if (window.scrollY > threshold) {
    navbar.classList.add('scrolled');
  } else {
    navbar.classList.remove('scrolled');
  }
});
