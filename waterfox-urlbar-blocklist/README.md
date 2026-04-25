# Waterfox URL Bar Blocklist

Local WebExtension for Waterfox/Firefox that prevents history-based address bar suggestions for configured domains or URL prefixes by deleting matching history items as soon as they are visited.

## What it does

- accept multiple rules, one per line
- if a rule is a domain such as `example.com`, it matches that domain and its subdomains
- if a rule is a full URL such as `https://example.com/private`, it matches that URL prefix
- provides an options page to edit the rule list
- provides context menu entries to add the current page URL or domain
- can purge existing matching history on demand

## Limits

- this only blocks history-based suggestions
- it does not hide bookmark suggestions unless you remove those bookmarks or disable bookmark suggestions in Waterfox
- it does not hide search-engine suggestions or Waterfox Suggest results

## Files

- `manifest.json`
- `background.js`
- `options.html`
- `options.js`
- `options.css`
- `build-xpi.sh`

## Build

```bash
~/scripts/waterfox-urlbar-blocklist/build-xpi.sh
```

This creates:

```bash
~/scripts/waterfox-urlbar-blocklist/dist/waterfox-urlbar-blocklist.xpi
```

## Load in Waterfox

Temporary load for testing:

1. Open `about:debugging`
2. Open `This Waterfox` / `This Firefox`
3. Click `Load Temporary Add-on`
4. Pick `manifest.json`

If your Waterfox build allows installing unsigned add-ons from file, you can also install the generated `.xpi`.
