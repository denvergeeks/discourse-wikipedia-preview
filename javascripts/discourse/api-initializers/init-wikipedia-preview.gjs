import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

const CDN_SRC =
  "https://unpkg.com/wikipedia-preview@1.10.0/dist/wikipedia-preview.umd.cjs?module";

const HOST_ID = "wikipedia-preview-popup-host";
const BOUND_ATTR = "data-wp-preview-bound";
const HIDE_DELAY = 250;

function assetSource() {
  return (
    settings?.theme_uploads_local?.wikipedia_preview_js ||
    settings?.theme_uploads?.wikipedia_preview_js ||
    CDN_SRC
  );
}

function log(...args) {
  console.log("[WP-PREVIEW]", ...args);
}

function ensureHost() {
  let host = document.getElementById(HOST_ID);

  if (!host) {
    host = document.createElement("div");
    host.id = HOST_ID;
    host.className = "wikipedia-preview-popup-host is-visible";
    document.body.appendChild(host);
    log("host created", host);
  }

  return host;
}

function clearHost() {
  const host = document.getElementById(HOST_ID);

  if (host) {
    host.innerHTML = "";
    host.style.left = "";
    host.style.top = "";
    host.classList.remove("is-visible");
    log("host cleared");
  }
}

function positionHost(host, anchor) {
  const rect = anchor.getBoundingClientRect();
  const scrollX = window.scrollX || window.pageXOffset;
  const scrollY = window.scrollY || window.pageYOffset;

  host.style.position = "absolute";
  host.style.left = `${scrollX + rect.left}px`;
  host.style.top = `${scrollY + rect.bottom + 12}px`;
  host.style.zIndex = "10050";

  requestAnimationFrame(() => {
    const hostRect = host.getBoundingClientRect();
    const maxLeft = scrollX + window.innerWidth - hostRect.width - 16;
    const minLeft = scrollX + 16;
    const desiredLeft = Math.min(Math.max(scrollX + rect.left, minLeft), maxLeft);

    host.style.left = `${desiredLeft}px`;
    log("host positioned", {
      left: host.style.left,
      top: host.style.top,
      width: hostRect.width,
      height: hostRect.height,
    });
  });
}

function showPreviewFor(anchor) {
  const title = anchor.dataset.wpTitle || anchor.textContent.trim();
  const lang = anchor.dataset.wpLang || "en";

  log("showPreviewFor called", { title, lang, anchor });

  if (!title || !window.wikipediaPreview) {
    log("missing title or wikipediaPreview");
    return;
  }

  const host = ensureHost();
  host.innerHTML = `<div class="wikipedia-preview-loading">Loading preview…</div>`;
  host.classList.add("is-visible");
  positionHost(host, anchor);

  window.wikipediaPreview.getPreviewHtml(title, lang, (html) => {
    log("getPreviewHtml callback fired", { title, lang, htmlLength: html?.length || 0 });
    host.innerHTML = html;
    host.classList.add("is-visible");
    positionHost(host, anchor);
  });
}

function bindPreview(anchor) {
  if (anchor.getAttribute(BOUND_ATTR) === "true") {
    return;
  }

  anchor.setAttribute(BOUND_ATTR, "true");
  anchor.setAttribute("tabindex", "0");

  log("binding anchor", {
    text: anchor.textContent.trim(),
    title: anchor.dataset.wpTitle,
    lang: anchor.dataset.wpLang,
  });

  anchor.addEventListener("mouseenter", () => {
    log("mouseenter fired", anchor.textContent.trim());
    showPreviewFor(anchor);
  });

  anchor.addEventListener("focus", () => {
    log("focus fired", anchor.textContent.trim());
    showPreviewFor(anchor);
  });

  anchor.addEventListener("mouseleave", () => {
    log("mouseleave fired", anchor.textContent.trim());
    setTimeout(() => {
      const host = document.getElementById(HOST_ID);
      if (!host || !host.matches(":hover")) {
        clearHost();
      }
    }, HIDE_DELAY);
  });

  anchor.addEventListener("blur", () => {
    log("blur fired", anchor.textContent.trim());
    setTimeout(() => {
      const host = document.getElementById(HOST_ID);
      if (!host || !host.matches(":hover")) {
        clearHost();
      }
    }, HIDE_DELAY);
  });
}

function initIn(root) {
  const nodes = root.querySelectorAll("[data-wikipedia-preview]");
  log("initIn root", root, "found", nodes.length, "nodes");

  nodes.forEach((anchor) => bindPreview(anchor));
}

export default apiInitializer((api) => {
  loadScript(assetSource()).then(() => {
    log("script loaded", !!window.wikipediaPreview);

    api.decorateCookedElement(
      (element) => {
        log("decorateCookedElement fired", element);
        initIn(element);
      },
      { id: "wikipedia-preview-custom-debug", onlyStream: false }
    );

    document.addEventListener("click", (event) => {
      const clickedInsidePopup = event.target.closest(`#${HOST_ID}`);
      const clickedTrigger = event.target.closest("[data-wikipedia-preview]");

      if (!clickedInsidePopup && !clickedTrigger) {
        clearHost();
      }
    });
  });
});