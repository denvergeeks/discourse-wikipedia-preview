import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

const CDN_SRC =
  "https://unpkg.com/wikipedia-preview@1.10.0/dist/wikipedia-preview.umd.cjs?module";
const ROOT_KEY = "wpPreviewRootInitialized";
const NODE_KEY = "wpPreviewInitialized";
const OBSERVER_KEY = "wpPreviewObserverBound";
const CLICK_KEY = "wpPreviewClickModeBound";

function isTouchFirstDevice() {
  return window.matchMedia("(hover: none) and (pointer: coarse)").matches;
}

function currentInteractionMode(mode) {
  if (mode === "hover") {
    return "hover";
  }

  if (mode === "click") {
    return "click";
  }

  return isTouchFirstDevice() ? "click" : "hover";
}

function isDeviceEnabled(componentSettings) {
  return isTouchFirstDevice()
    ? componentSettings.wikipedia_preview_enable_mobile
    : componentSettings.wikipedia_preview_enable_desktop;
}

function enabledSources(componentSettings) {
  const mode = componentSettings.wikipedia_preview_trigger_source;
  return {
    links: mode === "links" || mode === "both",
    spans: mode === "spans" || mode === "both",
  };
}

function debugLog(enabled, message, payload = null) {
  if (!enabled) {
    return;
  }

  if (payload) {
    console.debug(`[wikipedia-preview] ${message}`, payload);
  } else {
    console.debug(`[wikipedia-preview] ${message}`);
  }
}

function buildEvents(debug) {
  return {
    onShow(title, lang, type) {
      debugLog(debug, "onShow", { title, lang, type });
    },
    onWikiRead(title, lang) {
      debugLog(debug, "onWikiRead", { title, lang });
    },
  };
}

function assetSource(componentSettings) {
  if (componentSettings.wikipedia_preview_vendor_mode === "cdn") {
    return CDN_SRC;
  }

  return settings.theme_uploads_local.wikipedia_preview_js;
}

function loadOptionalLinkCss(componentSettings, debug) {
  if (!componentSettings.wikipedia_preview_use_upstream_link_styles) {
    return;
  }

  const href = settings.theme_uploads_local.wikipedia_preview_link_css;
  if (!href) {
    debugLog(debug, "link stylesheet asset missing");
    return;
  }

  if (document.querySelector(`link[data-wikipedia-preview-link-css="${href}"]`)) {
    return;
  }

  const link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = href;
  link.dataset.wikipediaPreviewLinkCss = href;
  document.head.appendChild(link);
}

function presetClass(preset) {
  return `wp-preview-preset--${preset || "standard"}`;
}

function cleanupPresetClasses(element) {
  Array.from(element.classList)
    .filter((name) => name.startsWith("wp-preview-preset--"))
    .forEach((name) => element.classList.remove(name));
}

function applyPresetClass(element, preset) {
  cleanupPresetClasses(element);
  element.classList.add(presetClass(preset));
}

function queryAllSafe(root, selector, debug) {
  try {
    return Array.from(root.querySelectorAll(selector));
  } catch (error) {
    debugLog(debug, "invalid selector", { selector, error });
    return [];
  }
}

function sanitizeManualElement(el) {
  if (!el.classList.contains("wmf-wp-with-preview")) {
    el.classList.add("wmf-wp-with-preview");
  }

  if (!el.hasAttribute("tabindex")) {
    el.setAttribute("tabindex", "0");
  }
}

function markNodeInitialized(node) {
  node.dataset[NODE_KEY] = "true";
}

function nodeInitialized(node) {
  return node.dataset[NODE_KEY] === "true";
}

function rootInitialized(root) {
  return root.dataset[ROOT_KEY] === "true";
}

function markRootInitialized(root) {
  root.dataset[ROOT_KEY] = "true";
}

function closeOpenPreview() {
  document
    .querySelectorAll(".wikipedia-preview, .mwe-popups, .mwe-popups-type-generic")
    .forEach((node) => node.remove());
}

function bindClickMode(root, selector, debug) {
  queryAllSafe(root, selector, debug).forEach((el) => {
    if (el.dataset[CLICK_KEY] === "true") {
      return;
    }

    el.dataset[CLICK_KEY] = "true";

    el.addEventListener("click", (event) => {
      const href = el.getAttribute("href");
      const isModified =
        event.metaKey || event.ctrlKey || event.shiftKey || event.altKey;

      if (href && !isModified) {
        event.preventDefault();
      }

      debugLog(debug, "click interaction", { href, text: el.textContent?.trim() });
    });

    el.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" && event.key !== " ") {
        return;
      }

      event.preventDefault();
      el.click();
    });
  });
}

function initManualElements(root, config, componentSettings) {
  const nodes = queryAllSafe(root, componentSettings.wikipedia_preview_selector, config.debug);

  nodes.forEach((node) => {
    sanitizeManualElement(node);

    if (nodeInitialized(node)) {
      return;
    }

    window.wikipediaPreview.init({
      root: node,
      selector: componentSettings.wikipedia_preview_selector,
      detectLinks: false,
      lang: node.dataset.wpLang || config.lang,
      prefersColorScheme: config.prefersColorScheme,
      popupContainer: document.body,
      events: config.events,
      debug: config.debug,
    });

    markNodeInitialized(node);
  });
}

function initLinkDetection(root, config) {
  window.wikipediaPreview.init({
    root,
    detectLinks: true,
    lang: config.lang,
    prefersColorScheme: config.prefersColorScheme,
    popupContainer: document.body,
    events: config.events,
    debug: config.debug,
  });
}

function initializeRoot(root, config, componentSettings) {
  if (!root || !window.wikipediaPreview) {
    return;
  }

  applyPresetClass(root, componentSettings.wikipedia_preview_card_preset);

  const mode = currentInteractionMode(
    componentSettings.wikipedia_preview_activation_mode
  );
  const sourceModes = enabledSources(componentSettings);

  if (sourceModes.links && !rootInitialized(root)) {
    initLinkDetection(root, config);
    markRootInitialized(root);
  }

  if (sourceModes.spans) {
    initManualElements(root, config, componentSettings);
  }

  if (mode === "click") {
    if (sourceModes.links) {
      bindClickMode(root, 'a[href*="wikipedia.org/wiki/"]', config.debug);
    }

    if (sourceModes.spans) {
      bindClickMode(root, componentSettings.wikipedia_preview_selector, config.debug);
    }
  }
}

function ensureComposerPreview(componentSettings, config) {
  const preview = document.querySelector(".d-editor-preview");
  if (!preview) {
    return;
  }

  initializeRoot(preview, config, componentSettings);

  if (preview.dataset[OBSERVER_KEY] === "true") {
    return;
  }

  preview.dataset[OBSERVER_KEY] = "true";

  const observer = new MutationObserver(() => {
    closeOpenPreview();
    initializeRoot(preview, config, componentSettings);
  });

  observer.observe(preview, {
    childList: true,
    subtree: true,
  });
}

export default apiInitializer((api) => {
  const componentSettings = settings;

  if (!componentSettings.wikipedia_preview_enabled) {
    return;
  }

  if (!isDeviceEnabled(componentSettings)) {
    return;
  }

  const sourceModes = enabledSources(componentSettings);
  if (!sourceModes.links && !sourceModes.spans) {
    return;
  }

  const config = {
    lang: componentSettings.wikipedia_preview_lang || "en",
    prefersColorScheme:
      componentSettings.wikipedia_preview_color_scheme || "detect",
    events: buildEvents(componentSettings.wikipedia_preview_debug),
    debug: componentSettings.wikipedia_preview_debug,
  };

  loadOptionalLinkCss(componentSettings, config.debug);

  loadScript(assetSource(componentSettings)).then(() => {
    if (componentSettings.wikipedia_preview_in_posts) {
      api.decorateCookedElement(
        (element) => initializeRoot(element, config, componentSettings),
        { id: "wikipedia-preview", onlyStream: false }
      );
    }

    if (componentSettings.wikipedia_preview_in_composer_preview) {
      api.onPageChange(() => ensureComposerPreview(componentSettings, config));
    }

    document.addEventListener("click", (event) => {
      if (event.target.closest(".wikipedia-preview, .mwe-popups, .mwe-popups-type-generic")) {
        return;
      }

      if (event.target.closest('.wmf-wp-with-preview, [data-wikipedia-preview], a[href*="wikipedia.org/wiki/"]')) {
        return;
      }

      closeOpenPreview();
    });
  });
});
