// GSAP Initialization and Configuration
// This file imports GSAP core and plugins, registers them, and sets global defaults

import { gsap } from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { ScrollToPlugin } from "gsap/ScrollToPlugin";

// Register GSAP plugins
gsap.registerPlugin(ScrollTrigger, ScrollToPlugin);

// Set global GSAP defaults
gsap.defaults({
  duration: 0.8,
  ease: "power2.out"
});

// ScrollTrigger global configuration
ScrollTrigger.defaults({
  toggleActions: "play none none reverse",
  markers: false // Set to true for debugging
});

// Respect user's motion preferences
const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

if (prefersReducedMotion.matches) {
  // Disable all GSAP animations if user prefers reduced motion
  gsap.globalTimeline.timeScale(0.01);
  ScrollTrigger.config({
    autoRefreshEvents: "visibilitychange,DOMContentLoaded,load"
  });
}

// Refresh ScrollTrigger on Turbo navigation
document.addEventListener("turbo:load", () => {
  ScrollTrigger.refresh();
});

// Clean up ScrollTriggers before Turbo cache
document.addEventListener("turbo:before-cache", () => {
  ScrollTrigger.getAll().forEach(trigger => trigger.kill());
});

// Export GSAP for use in Stimulus controllers
export { gsap, ScrollTrigger, ScrollToPlugin };

// Log GSAP version to console (helpful for debugging)
console.log(`GSAP ${gsap.version} loaded with ScrollTrigger and ScrollToPlugin`);
