// phia_hooks_registered
import PhiaHooks from './phia_hooks/index.js'

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"
// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/ashcrud";
import topbar from "../vendor/topbar";
import MishkaComponents from "../vendor/mishka_components.js";
import Sidebar from "../vendor/sidebar.js";

// Sidebar toggle functions exposed globally for direct onclick access
window.SidebarToggle = {
  toggleMinimize: function() {
    const currentState = localStorage.getItem('sidebar_minimized') === 'true';
    const newState = !currentState;
    localStorage.setItem('sidebar_minimized', newState);
    this.applyStateDirect(newState, localStorage.getItem('sidebar_mobile_open') === 'true');
    document.dispatchEvent(new CustomEvent('sidebar:state-changed', { detail: { minimized: newState, mobileOpen: localStorage.getItem('sidebar_mobile_open') === 'true' } }));
  },
  
  toggleMobile: function() {
    const currentState = localStorage.getItem('sidebar_mobile_open') === 'true';
    const newState = !currentState;
    localStorage.setItem('sidebar_mobile_open', newState);
    this.applyStateDirect(localStorage.getItem('sidebar_minimized') === 'true', newState);
    document.dispatchEvent(new CustomEvent('sidebar:state-changed', { detail: { minimized: localStorage.getItem('sidebar_minimized') === 'true', mobileOpen: newState } }));
  },
  
  navigateAndClose: function(url) {
    this.closeMobile();
    window.location.href = url;
  },
  
  closeMobile: function() {
    localStorage.setItem('sidebar_mobile_open', 'false');
    const backdrop = document.getElementById('sidebar-backdrop');
    if (backdrop) backdrop.remove();
    this.applyStateDirect(localStorage.getItem('sidebar_minimized') === 'true', false);
    document.dispatchEvent(new CustomEvent('sidebar:state-changed', { detail: { minimized: localStorage.getItem('sidebar_minimized') === 'true', mobileOpen: false } }));
  },
  
  applyStateDirect: function(minimized, mobileOpen) {
    const sidebar = document.getElementById('sidebar-drawer');
    if (!sidebar) return;
    
    const isMobile = window.innerWidth < 768;
    
    // Apply minimized state (desktop only)
    if (!isMobile) {
      if (minimized) {
        sidebar.classList.remove('w-60');
        sidebar.classList.add('w-16');
        // Hide text labels
        document.querySelectorAll('.sidebar-label').forEach(el => el.classList.add('hidden'));
        document.querySelectorAll('.sidebar-section-label').forEach(el => el.classList.add('hidden'));
        document.querySelectorAll('.sidebar-brand-text').forEach(el => el.classList.add('hidden'));
      } else {
        sidebar.classList.remove('w-16');
        sidebar.classList.add('w-60');
        // Show text labels
        document.querySelectorAll('.sidebar-label').forEach(el => el.classList.remove('hidden'));
        document.querySelectorAll('.sidebar-section-label').forEach(el => el.classList.remove('hidden'));
        document.querySelectorAll('.sidebar-brand-text').forEach(el => el.classList.remove('hidden'));
      }
    }
    
    // Mobile overlay handling
    if (isMobile) {
      if (mobileOpen) {
        sidebar.classList.remove('hidden');
        sidebar.classList.add('fixed', 'inset-0', 'z-50', 'w-60');
      } else {
        sidebar.classList.add('hidden');
        sidebar.classList.remove('fixed', 'inset-0', 'z-50');
      }
    }
    
    // Mobile backdrop
    let backdrop = document.getElementById('sidebar-backdrop');
    if (isMobile && mobileOpen) {
      if (!backdrop) {
        backdrop = document.createElement('div');
        backdrop.id = 'sidebar-backdrop';
        backdrop.className = 'fixed inset-0 z-40 bg-black/50';
        backdrop.addEventListener('click', () => {
          window.SidebarToggle.closeMobile();
        });
        document.body.appendChild(backdrop);
      }
      backdrop.classList.remove('hidden');
    } else if (backdrop) {
      backdrop.remove();
    }
    
    // Update hamburger button icon
    const mobileBtn = document.querySelector('[data-sidebar-mobile-btn]');
    if (mobileBtn) {
      const icon = mobileBtn.querySelector('svg');
      if (icon) {
        icon.setAttribute('name', mobileOpen ? 'hero-x-mark' : 'hero-bars-3');
      }
      mobileBtn.setAttribute('aria-label', mobileOpen ? 'Close sidebar' : 'Open sidebar');
    }
  }
};

// Apply initial state immediately on page load
(function() {
  // Direct read from localStorage to ensure we get the correct value
  const storedMinimized = localStorage.getItem('sidebar_minimized');
  console.log('Initial state - storedMinimized:', storedMinimized);
  const minimized = storedMinimized === 'true';
  console.log('Initial state - minimized:', minimized);
  
  // Force remove mobile-related classes first, then apply minimized state
  const applyNow = () => {
    const sidebar = document.getElementById('sidebar-drawer');
    if (!sidebar) {
      console.log('Sidebar not found!');
      return;
    }
    
    console.log('Applying sidebar state:', minimized);
    console.log('Current sidebar classes:', sidebar.className);
    
    // Always ensure mobile classes are removed first
    sidebar.classList.remove('hidden', 'fixed', 'inset-0', 'z-50');
    sidebar.classList.add('md:flex');
    
    // Then apply minimized state for desktop
    if (minimized) {
      sidebar.classList.remove('w-60');
      sidebar.classList.add('w-16');
      // Hide text labels
      document.querySelectorAll('.sidebar-label').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.sidebar-section-label').forEach(el => el.classList.add('hidden'));
      document.querySelectorAll('.sidebar-brand-text').forEach(el => el.classList.add('hidden'));
    } else {
      sidebar.classList.remove('w-16');
      sidebar.classList.add('w-60');
      // Show text labels
      document.querySelectorAll('.sidebar-label').forEach(el => el.classList.remove('hidden'));
      document.querySelectorAll('.sidebar-section-label').forEach(el => el.classList.remove('hidden'));
      document.querySelectorAll('.sidebar-brand-text').forEach(el => el.classList.remove('hidden'));
    }
    
    console.log('After apply - sidebar classes:', sidebar.className);
  };
  
  // Apply immediately if sidebar exists, otherwise wait
  const sidebar = document.getElementById('sidebar-drawer');
  console.log('Sidebar element found:', !!sidebar);
  if (sidebar) {
    applyNow();
  } else {
    const checkInterval = setInterval(() => {
      const el = document.getElementById('sidebar-drawer');
      if (el) {
        clearInterval(checkInterval);
        applyNow();
      }
    }, 50);
    setTimeout(() => clearInterval(checkInterval), 3000);
  }
})();

const SidebarManager = {
  mounted() {
    // Always re-apply state from localStorage on mount to handle navigation
    const storedMinimized = localStorage.getItem('sidebar_minimized') === 'true';
    const storedMobileOpen = localStorage.getItem('sidebar_mobile_open') === 'true';
    const isMobile = window.innerWidth < 768;
    
    // Apply state on mount
    window.SidebarToggle.applyStateDirect(storedMinimized, isMobile ? storedMobileOpen : false);
    
    // Listen for state changes
    document.addEventListener('sidebar:state-changed', (e) => {
      window.SidebarToggle.applyStateDirect(e.detail.minimized, e.detail.mobileOpen);
    });
    
    // Auto-minimize on resize to desktop
    this.handleResize = () => {
      if (window.innerWidth >= 768) {
        localStorage.setItem('sidebar_mobile_open', 'false');
        const currentMinimized = localStorage.getItem('sidebar_minimized') === 'true';
        window.SidebarToggle.applyStateDirect(currentMinimized, false);
      }
    };
    window.addEventListener('resize', this.handleResize);
  },
  
  destroyed() {
    window.removeEventListener('resize', this.handleResize);
  }
};

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {
    _csrf_token: csrfToken,
  },
  hooks: {
    ...colocatedHooks,
    ...MishkaComponents,
    Sidebar,
    SidebarManager,
  },
});
// Show progress bar on live navigation and form submits
topbar.config({
  barColors: {
    0: "#29d",
  },
  shadowColor: "rgba(0, 0, 0, .3)",
  // Make topbar appear faster on mobile for better UX
  clientBarSpeed: window.innerWidth < 768 ? 100 : 300,
  barTopSpeed: 200,
  barBottomSpeed: 200,
});
window.addEventListener("phx:page-loading-start", (_info) => {
  topbar.show(300);
  // Auto-close mobile sidebar on navigation - instant close for faster UX
  if (window.innerWidth < 768) {
    // Immediately remove backdrop and hide sidebar (no animation for speed)
    const backdrop = document.getElementById('sidebar-backdrop');
    if (backdrop) backdrop.remove();
    localStorage.setItem('sidebar_mobile_open', 'false');
  }
  // For both mobile and desktop - ensure sidebar state is maintained
  // Don't add 'hidden' class as it breaks desktop layout
});
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
// connect if there are any LiveViews on the page
liveSocket.connect();
// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();
      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );
      window.liveReloader = reloader;
    },
  );
}
