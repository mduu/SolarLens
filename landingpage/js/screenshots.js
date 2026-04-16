document.addEventListener('DOMContentLoaded', () => {
    // ===== Lightbox (built once, reused for all screenshots) =====
    let lightbox = null;
    let lbImages = [];
    let lbIdx = 0;

    const buildLightbox = () => {
        if (lightbox) return;
        lightbox = document.createElement('div');
        lightbox.className = 'lightbox';
        lightbox.setAttribute('role', 'dialog');
        lightbox.setAttribute('aria-modal', 'true');
        lightbox.innerHTML = `
            <button class="lightbox-close" type="button" aria-label="Close">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="6" y1="6" x2="18" y2="18"/><line x1="6" y1="18" x2="18" y2="6"/></svg>
            </button>
            <button class="lightbox-nav lightbox-prev" type="button" aria-label="Previous">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 6 9 12 15 18"/></svg>
            </button>
            <img class="lightbox-img" alt="">
            <button class="lightbox-nav lightbox-next" type="button" aria-label="Next">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 6 15 12 9 18"/></svg>
            </button>
        `;
        document.body.appendChild(lightbox);

        const prevBtn = lightbox.querySelector('.lightbox-prev');
        const nextBtn = lightbox.querySelector('.lightbox-next');

        prevBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            showLb(Math.max(0, lbIdx - 1));
        });
        nextBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            showLb(Math.min(lbImages.length - 1, lbIdx + 1));
        });

        // Click anywhere except the prev/next buttons closes
        lightbox.addEventListener('click', (e) => {
            if (e.target.closest('.lightbox-nav')) return;
            closeLb();
        });

        document.addEventListener('keydown', (e) => {
            if (!lightbox.classList.contains('open')) return;
            if (e.key === 'Escape') closeLb();
            else if (e.key === 'ArrowLeft') showLb(Math.max(0, lbIdx - 1));
            else if (e.key === 'ArrowRight') showLb(Math.min(lbImages.length - 1, lbIdx + 1));
        });
    };

    const openLb = (images, idx) => {
        buildLightbox();
        lbImages = images;
        showLb(idx);
        lightbox.classList.add('open');
        document.body.style.overflow = 'hidden';
    };

    const closeLb = () => {
        if (!lightbox) return;
        lightbox.classList.remove('open');
        document.body.style.overflow = '';
    };

    const showLb = (idx) => {
        if (!lightbox) return;
        lbIdx = idx;
        const img = lightbox.querySelector('.lightbox-img');
        img.src = lbImages[idx].src;
        img.alt = lbImages[idx].alt || '';
        lightbox.querySelector('.lightbox-prev').disabled = idx === 0;
        lightbox.querySelector('.lightbox-next').disabled = idx === lbImages.length - 1;
    };

    // ===== Carousel: arrows, dots, lightbox triggers =====
    document.querySelectorAll('.screenshots').forEach(section => {
        const scroll = section.querySelector('.screenshots-scroll');
        const prev = section.querySelector('.screenshots-nav-prev');
        const next = section.querySelector('.screenshots-nav-next');
        const dotsContainer = section.querySelector('.screenshots-dots');
        if (!scroll) return;
        const screenshots = scroll.querySelectorAll('.screenshot');
        if (!screenshots.length) return;

        // Build dots
        if (dotsContainer) {
            screenshots.forEach((_, i) => {
                const dot = document.createElement('button');
                dot.className = 'screenshots-dot';
                dot.type = 'button';
                dot.setAttribute('aria-label', String(i + 1));
                dot.addEventListener('click', () => scrollToIndex(i));
                dotsContainer.appendChild(dot);
            });
        }
        const dots = dotsContainer ? dotsContainer.querySelectorAll('.screenshots-dot') : [];

        const scrollToIndex = (i) => {
            const s = screenshots[i];
            const targetLeft = s.offsetLeft - (scroll.clientWidth - s.offsetWidth) / 2;
            scroll.scrollTo({ left: targetLeft, behavior: 'smooth' });
        };

        const getCurrentIndex = () => {
            const center = scroll.scrollLeft + scroll.clientWidth / 2;
            let closestIdx = 0;
            let closestDist = Infinity;
            screenshots.forEach((s, i) => {
                const sCenter = s.offsetLeft + s.offsetWidth / 2;
                const dist = Math.abs(center - sCenter);
                if (dist < closestDist) {
                    closestDist = dist;
                    closestIdx = i;
                }
            });
            return closestIdx;
        };

        const updateUI = () => {
            const idx = getCurrentIndex();
            dots.forEach((d, i) => d.classList.toggle('active', i === idx));
            if (prev) prev.disabled = idx === 0;
            if (next) next.disabled = idx === screenshots.length - 1;
        };

        scroll.addEventListener('scroll', updateUI, { passive: true });
        window.addEventListener('resize', updateUI);
        updateUI();

        if (prev) prev.addEventListener('click', () => scrollToIndex(Math.max(0, getCurrentIndex() - 1)));
        if (next) next.addEventListener('click', () => scrollToIndex(Math.min(screenshots.length - 1, getCurrentIndex() + 1)));

        // Open lightbox on click
        const images = Array.from(screenshots).map(s => s.querySelector('img'));
        screenshots.forEach((s, i) => {
            s.addEventListener('click', () => openLb(images, i));
        });
    });
});
