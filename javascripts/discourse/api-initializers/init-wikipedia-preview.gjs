import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

const CDN_SRC =
  "https://unpkg.com/wikipedia-preview@1.10.0/dist/wikipedia-preview.umd.cjs?module";

const HOST_ID = "wikipedia-preview-popup-host";
const BOUND_ATTR = "data-wp-preview-bound";
const HIDE_DELAY = 180;

function assetSource() {
  return (
    settings?.theme_uploads_local?.wikipedia_preview_js ||
    settings?.theme_uploads?.wikipedia_preview_js ||
    CDN_SRC
  );
}

function ensureHost() {
  let host = document.getElementById(HOST_ID);

  if (!host) {
    host = document.createElement("div");
    host.id = HOST_ID;
    host.className = "wikipedia-preview-popup-host";
    document.body.appendChild(host);
  }

  return host;
}

function clearHost() {
  const host = document.getElementById(HOST_ID);
  if (host) {
    host.innerHTML = "";
    host.classList.remove("is-visible");
    host.style.left = "";
    host.style.top = "";
  }
}

function positionHost(host, anchor) {
  const rect = anchor.getBoundingClientRect();
  const scrollX = window.scrollX || window.pageXOffset;
  const scrollY = window.scrollY || window.pageYOffset;

  host.style.left = `${scrollX + rect.left}px`;
  host.style.top = `${scrollY + rect.bottom + 10}px`;

  requestAnimationFrame(() => {
    const hostRect = host.getBoundingClientRect();
    const maxLeft = scrollX + window.innerWidth - hostRect.width - 16;
    const minLeft = scrollX + 16;
    const desiredLeft = Math.min(Math.max(scrollX + rect.left, minLeft), maxLeft);

    host.style.left = `${desiredLeft}px`;
  });
}

function wirePopupHover(host, anchor) {
  let hideTimer;

  const cancelHide = () => {
    if (hideTimer) {
      clearTimeout(hideTimer);
      hideTimer = null;
    }
  };

  const scheduleHide = () => {
    cancelHide();
    hideTimer = setTimeout(() => {
      clearHost();
    }, HIDE_DELAY);
  };

  anchor.addEventListener("mouseenter", cancelHide);
  anchor.addEventListener("mouseleave", scheduleHide);
  host.addEventListener("mouseenter", cancelHide);
  host.addEventListener("mouseleave", scheduleHide);
}

function showPreviewFor(anchor) {
  const title = anchor.dataset.wpTitle || anchor.textContent.trim();
  const lang = anchor.dataset.wpLang || "en";

  if (!title || !window.wikipediaPreview) {
    return;
  }

  const host = ensureHost();
  host.innerHTML = `<div class="wikipedia-preview-loading">Loading preview…</div>`;
  host.classList.add("is-visible");
  positionHost(host, anchor);

  window.wikipediaPreview.getPreviewHtml(title, lang, (html) => {
    host.innerHTML = html;
    host.classList.add("is-visible");
    positionHost(host, anchor);
    wirePopupHover(host, anchor);
  });
}

function bindPreview(anchor) {
  if (anchor.getAttribute(BOUND_ATTR) === "true") {
    return;
  }

  anchor.setAttribute(BOUND_ATTR, "true");

  anchor.addEventListener("mouseenter", () => {
    showPreviewFor(anchor);
  });

  anchor.addEventListener("focus", () => {
    showPreviewFor(anchor);
  });

  anchor.addEventListener("mouseleave", () => {
    setTimeout(() => {
      const host = document.getElementById(HOST_ID);
      if (!host || !host.matches(":hover")) {
        clearHost();
      }
    }, HIDE_DELAY);
  });

  anchor.addEventListener("blur", () => {
    setTimeout(() => {
      const host = document.getElementById(HOST_ID);
      if (!host || !host.matches(":hover")) {
        clearHost();
      }
    }, HIDE_DELAY);
  });
}

function initIn(root) {
  root
    .querySelectorAll("[data-wikipedia-preview]")
    .forEach((anchor) => bindPreview(anchor));
}

export default apiInitializer((api) => {
  loadScript(assetSource()).then(() => {
    api.decorateCookedElement(
      (element) => {
        initIn(element);
      },
      { id: "wikipedia-preview-custom", onlyStream: false }
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