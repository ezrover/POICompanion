document.addEventListener('DOMContentLoaded', function() {
    const scrollAnimate = (element) => {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('is-visible');
                }
            });
        }, { threshold: 0.1 });

        observer.observe(element);
    };

    const elements = document.querySelectorAll('.scroll-animate');
    elements.forEach(el => {
        scrollAnimate(el);
    });
});