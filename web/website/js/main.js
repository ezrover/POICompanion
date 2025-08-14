// HMI2.ai Website JavaScript - Interactive Elements and Form Handling

document.addEventListener('DOMContentLoaded', function() {
    
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('a[href^="#"]');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                const headerOffset = 80;
                const elementPosition = targetSection.getBoundingClientRect().top;
                const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
                
                window.scrollTo({
                    top: offsetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Mobile menu toggle
    const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
    if (mobileMenuToggle && navMenu) {
        mobileMenuToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            this.classList.toggle('active');
        });
        
        // Close mobile menu when clicking on a link
        const mobileNavLinks = navMenu.querySelectorAll('.nav-link');
        mobileNavLinks.forEach(link => {
            link.addEventListener('click', function() {
                navMenu.classList.remove('active');
                mobileMenuToggle.classList.remove('active');
            });
        });
    }
    
    // Navbar background on scroll
    const navbar = document.querySelector('.navbar');
    let lastScrollTop = 0;
    
    window.addEventListener('scroll', function() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        
        if (scrollTop > 50) {
            navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.98)';
            navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
        } else {
            navbar.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
            navbar.style.boxShadow = 'none';
        }
        
        // Hide/show navbar on scroll
        if (scrollTop > lastScrollTop && scrollTop > 100) {
            navbar.style.transform = 'translateY(-100%)';
        } else {
            navbar.style.transform = 'translateY(0)';
        }
        
        lastScrollTop = scrollTop;
    });
    
    // Intersection Observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe all section elements for scroll animations
    const sections = document.querySelectorAll('.section');
    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(30px)';
        section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(section);
    });
    
    // Animate cards on scroll
    const cards = document.querySelectorAll('.problem-card, .stat-card, .traction-item, .investment-card');
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = `opacity 0.6s ease ${index * 0.1}s, transform 0.6s ease ${index * 0.1}s`;
        observer.observe(card);
    });
    
    // Download button tracking
    const downloadButtons = document.querySelectorAll('.app-store-btn, .btn[href*="download"]');
    downloadButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            
            const platform = this.classList.contains('ios-btn') ? 'iOS' : 'Android';
            
            // Show waitlist signup notification
            showNotification(`Thanks for your interest in Roadtrip-Copilot for ${platform}! We'll notify you when it launches.`, 'success');
            
            // In a real app, this would redirect to app store or collect email for waitlist
            console.log(`User clicked download for ${platform}`);
        });
    });
    
    // FAQ accordion functionality
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');
        const answer = item.querySelector('.faq-answer');
        
        // Initially hide answers
        answer.style.display = 'none';
        question.style.cursor = 'pointer';
        question.innerHTML += ' <span class="faq-toggle">+</span>';
        
        question.addEventListener('click', function() {
            const toggle = this.querySelector('.faq-toggle');
            const isOpen = answer.style.display === 'block';
            
            if (isOpen) {
                answer.style.display = 'none';
                toggle.textContent = '+';
                item.style.transform = 'scale(1)';
            } else {
                answer.style.display = 'block';
                toggle.textContent = '−';
                item.style.transform = 'scale(1.02)';
            }
        });
    });
    
    // Notification system
    function showNotification(message, type = 'info') {
        // Remove existing notifications
        const existingNotifications = document.querySelectorAll('.notification');
        existingNotifications.forEach(notification => notification.remove());
        
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <span class="notification-message">${message}</span>
                <button class="notification-close">&times;</button>
            </div>
        `;
        
        // Add styles
        notification.style.cssText = `
            position: fixed;
            top: 100px;
            right: 20px;
            background: ${type === 'success' ? '#7ED321' : type === 'error' ? '#d32f2f' : '#4A90E2'};
            color: white;
            padding: 1rem 1.5rem;
            border-radius: 8px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
            z-index: 10000;
            transform: translateX(400px);
            transition: transform 0.3s ease;
            max-width: 350px;
        `;
        
        // Add to DOM
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // Close button functionality
        const closeButton = notification.querySelector('.notification-close');
        closeButton.addEventListener('click', () => {
            notification.style.transform = 'translateX(400px)';
            setTimeout(() => notification.remove(), 300);
        });
        
        // Auto-hide after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.style.transform = 'translateX(400px)';
                setTimeout(() => notification.remove(), 300);
            }
        }, 5000);
    }
    
    // Stats counter animation for hero section
    function animateCounters() {
        const counters = document.querySelectorAll('.stat-number');
        
        counters.forEach(counter => {
            const target = counter.textContent;
            const isPercentage = target.includes('%');
            const isDollar = target.includes('$');
            const hasText = target.includes('sec');
            
            if (hasText || isPercentage) {
                // For "6 sec" and "100%" - just animate in
                counter.style.opacity = '0';
                counter.style.transform = 'translateY(20px)';
                
                setTimeout(() => {
                    counter.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
                    counter.style.opacity = '1';
                    counter.style.transform = 'translateY(0)';
                }, Math.random() * 500);
                return;
            }
            
            if (isDollar) {
                // For "$1" - animate from $0 to $1
                let current = 0;
                const timer = setInterval(() => {
                    current += 0.1;
                    if (current >= 1) {
                        current = 1;
                        clearInterval(timer);
                    }
                    counter.textContent = `$${Math.round(current)}`;
                }, 50);
            }
        });
    }
    
    // Pricing card interactions
    const pricingCards = document.querySelectorAll('.pricing-card');
    pricingCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            if (!this.classList.contains('featured')) {
                this.style.transform = 'translateY(-5px) scale(1.02)';
                this.style.boxShadow = '0 10px 30px rgba(0, 0, 0, 0.15)';
            }
        });
        
        card.addEventListener('mouseleave', function() {
            if (!this.classList.contains('featured')) {
                this.style.transform = 'translateY(0) scale(1)';
                this.style.boxShadow = 'var(--box-shadow)';
            }
        });
    });
    
    // Platform card interactions
    const platformCards = document.querySelectorAll('.platform-card');
    platformCards.forEach(card => {
        card.addEventListener('click', function() {
            const platform = this.querySelector('h3').textContent;
            showNotification(`${platform} integration coming soon! Join our waitlist to be notified.`, 'info');
        });
    });
    
    // Testimonial card cycling (optional enhancement)
    const testimonialCards = document.querySelectorAll('.testimonial-card');
    let currentTestimonial = 0;
    
    function highlightTestimonial() {
        testimonialCards.forEach((card, index) => {
            if (index === currentTestimonial) {
                card.style.transform = 'translateY(-5px) scale(1.05)';
                card.style.boxShadow = '0 10px 30px rgba(74, 144, 226, 0.2)';
                card.style.borderTop = '3px solid var(--primary-blue)';
            } else {
                card.style.transform = 'translateY(0) scale(1)';
                card.style.boxShadow = 'var(--box-shadow)';
                card.style.borderTop = 'none';
            }
        });
        
        currentTestimonial = (currentTestimonial + 1) % testimonialCards.length;
    }
    
    // Highlight testimonials every 3 seconds
    if (testimonialCards.length > 0) {
        setInterval(highlightTestimonial, 3000);
    }
    
    // Trigger counter animation when hero stats section is visible
    const heroStats = document.querySelector('.hero-stats');
    if (heroStats) {
        const statsObserver = new IntersectionObserver(function(entries) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    animateCounters();
                    statsObserver.unobserve(entry.target);
                }
            });
        }, { threshold: 0.5 });
        
        statsObserver.observe(heroStats);
    }
    
    // Add hover effects to cards
    const hoverCards = document.querySelectorAll('.problem-card, .stat-card, .investment-card');
    hoverCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
    
    // Parallax effect for hero section
    window.addEventListener('scroll', function() {
        const scrolled = window.pageYOffset;
        const hero = document.querySelector('.hero');
        
        if (hero) {
            const rate = scrolled * -0.5;
            hero.style.backgroundPosition = `center ${rate}px`;
        }
    });
    
    // Add loading animation
    window.addEventListener('load', function() {
        document.body.classList.add('loaded');
    });
    
    // Form validation
    const formInputs = document.querySelectorAll('input, select, textarea');
    formInputs.forEach(input => {
        input.addEventListener('blur', function() {
            validateField(this);
        });
        
        input.addEventListener('input', function() {
            if (this.classList.contains('error')) {
                validateField(this);
            }
        });
    });
    
    function validateField(field) {
        const value = field.value.trim();
        let isValid = true;
        let errorMessage = '';
        
        // Remove existing error
        field.classList.remove('error');
        const existingError = field.parentNode.querySelector('.field-error');
        if (existingError) {
            existingError.remove();
        }
        
        // Validate based on field type
        if (field.hasAttribute('required') && !value) {
            isValid = false;
            errorMessage = 'This field is required';
        } else if (field.type === 'email' && value) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(value)) {
                isValid = false;
                errorMessage = 'Please enter a valid email address';
            }
        }
        
        // Show error if invalid
        if (!isValid) {
            field.classList.add('error');
            const errorDiv = document.createElement('div');
            errorDiv.className = 'field-error';
            errorDiv.textContent = errorMessage;
            errorDiv.style.cssText = `
                color: #d32f2f;
                font-size: 0.875rem;
                margin-top: 0.25rem;
            `;
            field.parentNode.appendChild(errorDiv);
        }
        
        return isValid;
    }
});

// Add CSS for mobile menu and animations
const additionalStyles = `
    .nav-menu.active {
        display: flex;
        position: absolute;
        top: 100%;
        left: 0;
        right: 0;
        background: white;
        flex-direction: column;
        padding: 1rem;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
        gap: 1rem;
    }
    
    .mobile-menu-toggle.active span:nth-child(1) {
        transform: rotate(45deg) translate(5px, 5px);
    }
    
    .mobile-menu-toggle.active span:nth-child(2) {
        opacity: 0;
    }
    
    .mobile-menu-toggle.active span:nth-child(3) {
        transform: rotate(-45deg) translate(7px, -6px);
    }
    
    .faq-toggle {
        float: right;
        font-weight: bold;
        font-size: 1.5rem;
        color: var(--primary-blue);
        transition: var(--transition);
    }
    
    .faq-answer {
        transition: all 0.3s ease;
        overflow: hidden;
    }
    
    body.loaded {
        opacity: 1;
    }
    
    body {
        opacity: 0;
        transition: opacity 0.3s ease;
    }
    
    @media (max-width: 768px) {
        .nav-menu {
            display: none;
        }
        
        .hero-stats {
            grid-template-columns: repeat(2, 1fr);
            gap: var(--spacing-sm);
        }
        
        .hero-download-buttons {
            flex-direction: column;
            align-items: center;
            width: 100%;
        }
        
        .hero-download-buttons .app-store-btn {
            width: 100%;
            max-width: 280px;
            justify-content: center;
        }
        
        .download-buttons {
            flex-direction: column;
            align-items: center;
        }
        
        .download-benefits {
            grid-template-columns: repeat(2, 1fr);
            gap: var(--spacing-sm);
        }
        
        .app-store-btn {
            width: 100%;
            max-width: 300px;
            justify-content: center;
        }
        
        .testimonials-grid {
            grid-template-columns: 1fr;
        }
        
        .platforms-grid {
            grid-template-columns: 1fr;
        }
        
        .pricing-cards {
            grid-template-columns: 1fr;
        }
        
        .pricing-card.featured {
            transform: scale(1);
        }
    }
    
    @media (max-width: 480px) {
        .hero-stats {
            grid-template-columns: 1fr;
            gap: var(--spacing-sm);
        }
        
        .download-benefits {
            grid-template-columns: 1fr;
            gap: var(--spacing-sm);
        }
    }
`;

// Inject additional styles
const styleSheet = document.createElement('style');
styleSheet.textContent = additionalStyles;
document.head.appendChild(styleSheet);