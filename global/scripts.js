// Google Analytics
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', 'G-3ZN94Y4QHN');

// Menú hamburguesa
document.addEventListener('DOMContentLoaded', function () {
  const toggle = document.querySelector('.hamburger');
  const navLinks = document.querySelector('.nav-links');
  if (toggle && navLinks) {
    toggle.addEventListener('click', function () {
      navLinks.classList.toggle('activo');
    });
  }
});