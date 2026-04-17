# Discourse Wikipedia Preview

A Discourse theme component built from the official `discourse/discourse-theme-skeleton` template for integrating Wikimedia's `wikipedia-preview` library into cooked posts and the composer preview.

## This package now includes vendored upstream assets

The repository now contains vendored upstream files from `wikipedia-preview`:

- `assets/wikipedia-preview.umd.cjs`
- `assets/wikipedia-preview-link.css`

These are registered in `about.json` and the component defaults to `wikipedia_preview_vendor_mode: local` for production use.

## Click/tap and composer behavior review

This deploy-focused version improves click/tap behavior and composer handling by:

- preventing standard navigation on plain clicks for matching Wikipedia links when click mode is active
- preserving modified-click behavior such as ctrl/cmd-click
- adding keyboard activation for Enter and Space on manual trigger elements
- assigning `tabindex="0"` to manual trigger elements when needed
- closing stale previews when the composer preview rerenders
- guarding the composer `MutationObserver` against duplicate binding

## Admin settings

- Global enable/disable
- Desktop enable/disable
- Mobile enable/disable
- Enable in posts
- Enable in composer preview
- Trigger source: links, spans, or both
- Activation mode: hover, click/tap, or hybrid
- Card preset: standard, few images, many images, text-first, compact
- Default language
- Color scheme: detect, light, dark
- Manual selector for span mode
- Optional upstream link styles
- Vendor mode: local or CDN
- Debug mode

## Git-ready initialization script

Run these commands after creating a new empty GitHub repository:

```bash
tar -xzf discourse-wikipedia-preview.tar.gz
cd discourse-wikipedia-preview
git init
git branch -M main
git add .
git commit -m "Initial commit: Discourse Wikipedia Preview theme component"
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/discourse-wikipedia-preview.git
git push -u origin main
```

If you prefer SSH:

```bash
git remote add origin git@github.com:YOUR_GITHUB_USERNAME/discourse-wikipedia-preview.git
git push -u origin main
```

## Exact GitHub setup flow

1. Create a new empty repository on GitHub named `discourse-wikipedia-preview`.
2. Do not add a README, .gitignore, or license on GitHub because the archive already includes them.
3. Extract this archive locally or on your server.
4. Run the git commands above.
5. In Discourse Admin -> Customize -> Themes, install from the repository URL.
6. Add the component to your active theme.
7. Keep `wikipedia_preview_vendor_mode` set to `local` in production.

## CSP note

If your CSP is strict, allow the Wikimedia domains needed by the preview library and related API/media requests.
