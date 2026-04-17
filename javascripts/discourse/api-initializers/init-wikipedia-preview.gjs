import { apiInitializer } from "discourse/lib/api";
import loadScript from "discourse/lib/load-script";

const CDN_SRC =
  "https://unpkg.com/wikipedia-preview@1.10.0/dist/wikipedia-preview.umd.cjs?module";

export default apiInitializer(() => {
  loadScript(CDN_SRC).then(() => {
    if (!window.wikipediaPreview) {
      return;
    }

    window.wikipediaPreview.init({
      root: document,
      selector: "[data-wikipedia-preview]",
      detectLinks: false,
      lang: "en",
      popupContainer: document.body,
      debug: true,
      prefersColorScheme: "detect",
    });
  });
});