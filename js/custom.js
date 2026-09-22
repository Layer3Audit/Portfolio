/*!
 * Item: Kitzu
 * Description: Personal Portfolio Template
 * Author/Developer: Exill
 * Author/Developer URL: https://themeforest.net/user/exill
 * Version: v2.0.1
 * License: Themeforest Standard Licenses: https://themeforest.net/licenses
 */

/*----------- CUSTOM JS SCRIPTS -----------*/

(function($) {
  'use strict';

  $(function() {
    var $sections = $('.lightbox-wrapper');
    var $links = $('.navbar .section-link[href^="#"]');
    var $pdfModal = $('#pdf-viewer-modal');
    var $pdfFrame = $('#pdf-viewer-frame');
    var $pdfTitle = $('#pdf-viewer-title');

    function closePdfViewer() {
      $pdfModal.removeClass('is-open').attr('aria-hidden', 'true');
      $('body').removeClass('pdf-viewer-open');

      window.setTimeout(function() {
        if (!$pdfModal.hasClass('is-open')) {
          $pdfFrame.attr('src', 'about:blank');
        }
      }, 250);
    }

    /*
     * main.js initializes animatedModal on the navbar links before this file
     * runs. Remove those old modal click handlers and the inline styles/classes
     * they add so our persistent page navigation is the only system controlling
     * section visibility.
     */
    $('.navbar .navbar-nav .nav-link[href^="#"]').off('click');

    $sections.each(function() {
      var $section = $(this);
      var sectionId = this.id;

      $section
        .removeClass('animated fadeIn fadeOut ' + sectionId + '-on ' + sectionId + '-off')
        .css({
          'position': '',
          'width': '',
          'height': '',
          'top': '',
          'left': '',
          'z-index': '',
          'opacity': '',
          '-webkit-animation-duration': '',
          '-moz-animation-duration': '',
          '-ms-animation-duration': '',
          'animation-duration': '',
          'animation-delay': '',
          'animation-fill-mode': ''
        });
    });

    var fadeOutDuration = 250;
    var fadeInDuration = 400;
    var isTransitioning = false;
    var queuedSection = null;

    function updateNavigation(sectionId) {
      $links.removeClass('active');
      $links.filter('[href="' + sectionId + '"]').addClass('active');

      if (window.history && window.history.replaceState) {
        window.history.replaceState(null, '', sectionId);
      }

      if ($('#navbarSupportedContent').hasClass('show')) {
        $('.navbar-menu').trigger('click');
      }
    }

    function showSection(sectionId, immediate) {
      closePdfViewer();

      var $target = $(sectionId);
      var $current = $sections.filter('.is-active');

      if (!$target.length) {
        return;
      }

      /* Clicking the page that is already open should do nothing. */
      if ($current.length && $current.is($target) && !isTransitioning) {
        updateNavigation(sectionId);
        return;
      }

      /* If somebody clicks quickly, remember only the latest requested page. */
      if (isTransitioning && !immediate) {
        queuedSection = sectionId;
        return;
      }

      updateNavigation(sectionId);

      /* Initial page load should appear immediately rather than flash white. */
      if (immediate || !$current.length) {
        $sections.removeClass('is-active is-fading-out is-transition-target');
        $target.addClass('is-active');
        if (sectionId === '#blog') {
          window.setTimeout(layoutPhotoGrid, 0);
        }
        return;
      }

      isTransitioning = true;
      queuedSection = null;

      /* Render the next page invisibly, then fade the current page away. */
      $target.addClass('is-transition-target');
      $current.addClass('is-fading-out');

      window.setTimeout(function() {
        $current.removeClass('is-active is-fading-out');

        /* Two frames guarantee that opacity: 0 is painted before fading to 1. */
        window.requestAnimationFrame(function() {
          window.requestAnimationFrame(function() {
            $target.removeClass('is-transition-target').addClass('is-active');
            if (sectionId === '#blog') {
              window.setTimeout(layoutPhotoGrid, 0);
            }

            window.setTimeout(function() {
              isTransitioning = false;

              if (queuedSection && queuedSection !== '#' + $target.attr('id')) {
                var nextSection = queuedSection;
                queuedSection = null;
                showSection(nextSection, false);
              } else {
                queuedSection = null;
              }
            }, fadeInDuration);
          });
        });
      }, fadeOutDuration);
    }

    $links.on('click', function(event) {
      event.preventDefault();
      showSection($(this).attr('href'), false);
    });

    $('.pdf-preview-link').on('click', function(event) {
      event.preventDefault();

      var pdfSrc = $(this).attr('href');
      var pdfTitle = $(this).data('pdf-title') || 'Document';

      $pdfTitle.text(pdfTitle);
      $pdfFrame.attr('src', pdfSrc);
      $pdfModal.addClass('is-open').attr('aria-hidden', 'false');
      $('body').addClass('pdf-viewer-open');
      $pdfModal.find('.pdf-viewer-close').trigger('focus');
    });

    $pdfModal.find('.pdf-viewer-close').on('click', closePdfViewer);

    $pdfModal.on('click', function(event) {
      if (event.target === this) {
        closePdfViewer();
      }
    });

    $(document).on('keydown', function(event) {
      if (event.key === 'Escape' && $pdfModal.hasClass('is-open')) {
        closePdfViewer();
      }
    });

    /* Photos: original Portfolio-style filtered gallery. */
    var $photoGrid = $('#blog .photos-portfolio-section .portfolio-grid');
    var $photoFilters = $('#blog .photos-portfolio-section .filter-control li');

    function layoutPhotoGrid() {
      if ($photoGrid.length && $photoGrid.data('isotope')) {
        $photoGrid.isotope('layout');
      }
    }

    if ($photoGrid.length) {
      $photoGrid.imagesLoaded(function() {
        $photoGrid.isotope({
          itemSelector: '#blog .photos-portfolio-section .single-item',
          masonry: {
            horizontalOrder: true
          }
        });

        $photoFilters.on('click', function() {
          $photoFilters.removeClass('tab-active');
          $(this).addClass('tab-active');

          $photoGrid.isotope({
            filter: $(this).data('filter'),
            transitionDuration: '.25s'
          });
        });
      });
    }

    var initialSection = window.location.hash;
    if (!initialSection || !$(initialSection).hasClass('lightbox-wrapper')) {
      initialSection = '#about';
    }

    showSection(initialSection, true);
  });
}(jQuery));

/* Compact long scripting links to domain/.../filename while preserving the full URL. */
(function() {
  'use strict';

  function compactScriptLinks() {
    var links = document.querySelectorAll('#scripting .script-url');

    links.forEach(function(link) {
      var fullUrl = link.getAttribute('href');
      if (!fullUrl || fullUrl === '#') {
        return;
      }

      try {
        var parsed = new URL(fullUrl, window.location.href);
        var hostname = parsed.hostname.replace(/^www\./, '');
        var parts = parsed.pathname.split('/').filter(Boolean);
        var filename = parts.length ? decodeURIComponent(parts[parts.length - 1]) : '';

        link.textContent = filename ? hostname + '/.../' + filename : hostname;
        link.setAttribute('title', fullUrl);
      } catch (error) {
        /* Leave the authored link text untouched if the URL is not parseable. */
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', compactScriptLinks);
  } else {
    compactScriptLinks();
  }
}());

/* Sort the Scripting table by clicking any column heading. */
(function() {
  'use strict';

  function initScriptTableSorting() {
    var table = document.querySelector('#scripting .script-table');
    if (!table) {
      return;
    }

    var headers = Array.prototype.slice.call(table.querySelectorAll('th.script-sortable'));
    var tbody = table.querySelector('tbody');

    function sortByHeader(header) {
      var columnIndex = headers.indexOf(header);
      var currentSort = header.getAttribute('aria-sort');
      var nextSort = currentSort === 'ascending' ? 'descending' : 'ascending';
      var direction = nextSort === 'ascending' ? 1 : -1;
      var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));

      rows.sort(function(a, b) {
        var aCell = a.children[columnIndex];
        var bCell = b.children[columnIndex];
        var aValue = (aCell.getAttribute('data-sort-value') || aCell.textContent || '').trim().toLowerCase();
        var bValue = (bCell.getAttribute('data-sort-value') || bCell.textContent || '').trim().toLowerCase();

        return aValue.localeCompare(bValue, undefined, {numeric: true, sensitivity: 'base'}) * direction;
      });

      headers.forEach(function(item) {
        item.setAttribute('aria-sort', item === header ? nextSort : 'none');
      });

      rows.forEach(function(row) {
        tbody.appendChild(row);
      });
    }

    headers.forEach(function(header) {
      header.addEventListener('click', function() {
        sortByHeader(header);
      });

      header.addEventListener('keydown', function(event) {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          sortByHeader(header);
        }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initScriptTableSorting);
  } else {
    initScriptTableSorting();
  }
}());

/* Contact: submit through Formspree without leaving the page. */
(function() {
  'use strict';

  function initContactForm() {
    var form = document.getElementById('contact-form');

    if (!form) {
      return;
    }

    var submitBtn = document.getElementById('contact-submit');
    var feedback = form.querySelector('.contact-feedback');
    var originalButtonText = submitBtn ? submitBtn.textContent : 'Send Message';

    form.addEventListener('submit', function(event) {
      event.preventDefault();

      if (!submitBtn || !feedback) {
        return;
      }

      submitBtn.classList.remove('success', 'error');
      submitBtn.classList.add('wait');
      submitBtn.textContent = 'Sending...';
      submitBtn.disabled = true;

      feedback.classList.remove('success', 'error');
      feedback.textContent = '';
      feedback.style.display = 'none';

      fetch(form.action, {
        method: 'POST',
        body: new FormData(form),
        headers: {
          'Accept': 'application/json'
        }
      })
        .then(function(response) {
          if (response.ok) {
            return response.json().catch(function() {
              return {};
            });
          }

          return response.json()
            .catch(function() {
              return {};
            })
            .then(function(data) {
              var message = 'Unable to send your message. Please try again.';

              if (data && Array.isArray(data.errors) && data.errors.length) {
                message = data.errors
                  .map(function(item) {
                    return item.message;
                  })
                  .filter(Boolean)
                  .join(' ');
              }

              throw new Error(message);
            });
        })
        .then(function() {
          submitBtn.classList.remove('wait', 'error');
          submitBtn.classList.add('success');
          submitBtn.textContent = 'Success';

          feedback.classList.remove('error');
          feedback.classList.add('success');
          feedback.textContent = 'Thank you for your message. It has been sent.';
          feedback.style.display = 'block';

          form.reset();
        })
        .catch(function(error) {
          console.error('Contact form submission failed:', error);

          submitBtn.classList.remove('wait', 'success');
          submitBtn.classList.add('error');
          submitBtn.textContent = 'Error';

          feedback.classList.remove('success');
          feedback.classList.add('error');
          feedback.textContent = error.message || 'Unable to send your message. Please try again.';
          feedback.style.display = 'block';
        })
        .finally(function() {
          window.setTimeout(function() {
            submitBtn.classList.remove('wait', 'success', 'error');
            submitBtn.textContent = originalButtonText;
            submitBtn.disabled = false;

            feedback.style.display = 'none';
            feedback.classList.remove('success', 'error');
            feedback.textContent = '';
          }, 6000);
        });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initContactForm);
  } else {
    initContactForm();
  }
}());
