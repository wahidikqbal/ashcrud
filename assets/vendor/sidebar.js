const Sidebar = {
  STORAGE_KEY: "ashcrud:sidebar_minimized",
  defaults: {
    expandedWidth: "250px",
    collapsedWidth: "60px",
    transitionDuration: "0.3s",
    labelAnimationDelay: 10,
  },

  getElements(el) {
    const sidebarSelector = el.getAttribute("data-sidebar-selector");
    if (!sidebarSelector) return null;

    if (!this.isValidSelector(sidebarSelector)) return null;

    const sidebar = document.querySelector(sidebarSelector);
    if (!sidebar) return null;

    return {
      sidebar,
      labels: sidebar.querySelectorAll("[data-item-label]"),
    };
  },

  isValidSelector(selector) {
    try {
      document.querySelector(selector);
      return true;
    } catch (e) {
      console.error("Invalid selector:", selector);
      return false;
    }
  },

  getConfig(sidebar) {
    const expandedWidth = sidebar.getAttribute("data-expanded-width");
    const collapsedWidth = sidebar.getAttribute("data-collapsed-width");

    return {
      expandedWidth:
        this.sanitizeCssValue(expandedWidth) || this.defaults.expandedWidth,
      collapsedWidth:
        this.sanitizeCssValue(collapsedWidth) || this.defaults.collapsedWidth,
      isMinimized: sidebar.getAttribute("data-minimized") === "true",
    };
  },

  sanitizeCssValue(value) {
    if (!value) return null;

    const validPattern = /^[0-9]+(px|em|rem|%|vh|vw)$/;
    return validPattern.test(value) ? value : null;
  },

  expandSidebar(sidebar, labels, expandedWidth) {
    sidebar.style.width = expandedWidth;
    sidebar.setAttribute("data-minimized", "false");

    this.animateLabels(labels, true);
  },

  collapseSidebar(sidebar, labels, collapsedWidth) {
    sidebar.style.width = collapsedWidth;
    sidebar.setAttribute("data-minimized", "true");

    this.hideLabels(labels);
  },

  animateLabels(labels, show) {
    if (show) {
      labels.forEach((label) => {
        label.classList.remove("hidden");
        label.classList.add("opacity-0");

        setTimeout(() => {
          label.classList.add(
            "transition-opacity",
            "duration-200",
            "opacity-100",
          );
          label.classList.remove("opacity-0");
        }, this.defaults.labelAnimationDelay);
      });
    }
  },

  hideLabels(labels) {
    labels.forEach((label) => {
      label.classList.add("hidden");
      label.classList.remove(
        "opacity-100",
        "transition-opacity",
        "duration-200",
      );
    });
  },

  Sidebar(elements, config) {
    const { sidebar, labels } = elements;
    const { expandedWidth, collapsedWidth, isMinimized } = config;

    sidebar.style.transition = `width ${this.defaults.transitionDuration} ease`;

    if (isMinimized) {
      this.expandSidebar(sidebar, labels, expandedWidth);
    } else {
      this.collapseSidebar(sidebar, labels, collapsedWidth);
    }
  },

  mounted() {
    // Restore sidebar state from localStorage
    const savedState = localStorage.getItem(this.STORAGE_KEY);
    const shouldCollapse = savedState === "true";

    if (shouldCollapse) {
      const elements = this.getElements(this.el);
      if (elements) {
        const config = this.getConfig(elements.sidebar);
        // Disable transition for instant initial restore (no animation on page load)
        elements.sidebar.style.transition = "none";
        this.collapseSidebar(elements.sidebar, elements.labels, config.collapsedWidth);
        // Force reflow to apply width change instantly
        void elements.sidebar.offsetHeight;
        // Restore transition for future interactions
        elements.sidebar.style.transition = `width ${this.defaults.transitionDuration} ease`;
        // Rotate icon to match collapsed state
        const icon = this.el.querySelector(".minimize-icon");
        if (icon) {
          icon.classList.add("rotate-180");
        }
      }
    }

    // Setup click handler
    this.clickHandler = this.handleClick.bind(this);
    this.el.addEventListener("click", this.clickHandler);
  },

  handleClick() {
    const elements = this.getElements(this.el);
    if (!elements) return;

    const config = this.getConfig(elements.sidebar);
    this.Sidebar(elements, config);

    // Save new state to localStorage
    const newState = elements.sidebar.getAttribute("data-minimized");
    localStorage.setItem(this.STORAGE_KEY, newState);

    const icon = this.el.querySelector(".minimize-icon");
    if (icon) {
      icon.classList.toggle("rotate-180");
    }
  },

  destroy() {
    if (this.el && this.clickHandler) {
      this.el.removeEventListener("click", this.clickHandler);
      this.clickHandler = null;
    }
  },
};

export default Sidebar;
