import { trustHTML } from "@ember/template";
import { apiInitializer } from "discourse/lib/api";
import DTooltip from "discourse/float-kit/components/d-tooltip";
import I18n from "discourse-i18n";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  const currentLocale = I18n.currentLocale();

  if (!I18n.translations[currentLocale].js.composer) {
    I18n.translations[currentLocale].js.composer = {};
  }

  I18n.translations[currentLocale].js.composer.wikipedia_preview_placeholder =
    I18n.t(themePrefix("composer.placeholder_text"));

  api.decorateCookedElement(async (post, helper) => {
    const wraps = post.querySelectorAll('[data-wrap="wikipedia-preview"]');

    if (!wraps.length) {
      return;
    }

    for (const wrap of wraps) {
      const searchTerm = wrap.textContent.trim();

      if (!searchTerm) {
        continue;
      }

      const data = await getWikipediaPreviewData(searchTerm);

      if (!data) {
        continue;
      }

      wrap.innerHTML = "";

      helper.renderGlimmer(
        wrap,
        <template>
          <DTooltip
            @interactive={{true}}
            @placement={{settings.wikipedia_preview_tooltip_placement}}
            class="wp-preview-tooltip"
          >
            <:trigger>
              <span class="wp-preview-trigger">{{searchTerm}}</span>
            </:trigger>

            <:content>
              <div class="wp-preview-card">
                {{#if data.thumbnail}}
                  <div class="wp-preview-image-wrap">
                    <img
                      src={{data.thumbnail}}
                      alt={{data.title}}
                      class="wp-preview-image"
                    />
                  </div>
                {{/if}}

                <div class="wp-preview-body">
                  <div class="wp-preview-title-row">
                    <strong class="wp-preview-title">{{data.title}}</strong>
                  </div>

                  {{#if data.extract}}
                    <div class="wp-preview-extract">
                      {{trustHTML data.extract}}
                    </div>
                  {{else}}
                    <p class="wp-preview-excerpt">{{data.excerpt}}</p>
                  {{/if}}

                  <p class="wp-preview-link-row">
                    {{i18n (themePrefix "tooltip_before_link_text")}}
                    <a
                      href={{data.url}}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {{data.url}}
                    </a>
                  </p>
                </div>
              </div>
            </:content>
          </DTooltip>
        </template>
      );
    }
  });

  api.addComposerToolbarPopupMenuOption({
    action: (toolbarEvent) => {
      toolbarEvent.applySurround(
        '[wrap="wikipedia-preview"]',
        "[/wrap]",
        "wikipedia_preview_placeholder"
      );
    },
    icon: "fab-wikipedia-w",
    label: themePrefix("composer.add_wrap_button_text"),
  });
});

async function getWikipediaPreviewData(searchTerm) {
  const cacheKey = `wp-preview:${settings.wikipedia_base_url}:${searchTerm}`;
  const cached = sessionStorage.getItem(cacheKey);

  if (cached) {
    try {
      return JSON.parse(cached);
    } catch {
      sessionStorage.removeItem(cacheKey);
    }
  }

  const headers = {
    "Api-User-Agent": "Discourse Wikipedia Preview Theme Component",
  };

  const searchRes = await fetch(
    `https://${settings.wikipedia_base_url}/w/rest.php/v1/search/page?q=${encodeURIComponent(searchTerm)}&limit=1`,
    { headers }
  );

  if (!searchRes.ok) {
    return null;
  }

  const searchData = await searchRes.json();
  const page = searchData?.pages?.[0];

  if (!page?.key) {
    return null;
  }

  const summaryRes = await fetch(
    `https://${settings.wikipedia_base_url}/api/rest_v1/page/summary/${encodeURIComponent(page.key)}`,
    { headers }
  );

  if (!summaryRes.ok) {
    const fallback = {
      title: page.title || searchTerm,
      excerpt: stripHtml(page.excerpt || ""),
      extract: null,
      key: page.key,
      url: `https://${settings.wikipedia_base_url}/wiki/${page.key}`,
      thumbnail: null,
    };

    sessionStorage.setItem(cacheKey, JSON.stringify(fallback));
    return fallback;
  }

  const summary = await summaryRes.json();

  const result = {
    title: summary.title || page.title || searchTerm,
    excerpt: stripHtml(page.excerpt || summary.extract || ""),
    extract: settings.wikipedia_preview_use_extract_html
      ? summary.extract_html || null
      : null,
    key: page.key,
    url:
      summary.content_urls?.desktop?.page ||
      `https://${settings.wikipedia_base_url}/wiki/${page.key}`,
    thumbnail: settings.wikipedia_preview_show_image
      ? summary.thumbnail?.source || null
      : null,
  };

  sessionStorage.setItem(cacheKey, JSON.stringify(result));
  return result;
}

function stripHtml(html) {
  return html.replace(/(<([^>]+)>)/gi, "").trim();
}