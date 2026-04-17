import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

const CDN_SRC =
  "https://unpkg.com/wikipedia-preview@1.10.0/dist/wikipedia-preview.umd.cjs?module";

function assetSource() {
  return (
    settings?.theme_uploads_local?.wikipedia_preview_js ||
    settings?.theme_uploads?.wikipedia_preview_js ||
    CDN_SRC
  );
}

export default apiInitializer((api) => {
  loadScript(assetSource()).then(() => {
    api.decorateCookedElement(
      (element) => {
        if (!window.wikipediaPreview) {
          return;
        }

        window.wikipediaPreview.init({
          root: element,
          selector: "[data-wikipedia-preview]",
          detectLinks: false,
          lang: "en",
          popupContainer: document.body,
          debug: true,
          prefersColorScheme: "detect",
        });
      },
      { id: "wikipedia-preview-debug", onlyStream: false }
    );
  });
});