const STORAGE_KEY = "rulesText";
const MENU_BLOCK_DOMAIN = "block-domain";
const MENU_BLOCK_PREFIX = "block-prefix";

let cachedRules = [];

function normalizeLine(line) {
  return String(line || "").trim();
}

function normalizeDomain(value) {
  return value.replace(/^\*\./, "").replace(/\.$/, "").toLowerCase();
}

function normalizeUrlPrefix(value) {
  try {
    const url = new URL(value);
    url.hash = "";
    return url.toString();
  } catch (error) {
    return "";
  }
}

function parseRules(text) {
  return String(text || "")
    .split(/\r?\n/)
    .map(normalizeLine)
    .filter((line) => line.length > 0 && !line.startsWith("#"))
    .map((line) => {
      if (/^https?:\/\//i.test(line)) {
        const prefix = normalizeUrlPrefix(line);
        if (!prefix) {
          return null;
        }

        return {
          type: "prefix",
          raw: line,
          value: prefix
        };
      }

      const domain = normalizeDomain(line);
      if (!domain) {
        return null;
      }

      return {
        type: "domain",
        raw: line,
        value: domain
      };
    })
    .filter(Boolean);
}

async function loadRules() {
  const result = await browser.storage.local.get(STORAGE_KEY);
  cachedRules = parseRules(result[STORAGE_KEY] || "");
  return cachedRules;
}

async function getRulesText() {
  const result = await browser.storage.local.get(STORAGE_KEY);
  return result[STORAGE_KEY] || "";
}

async function saveRulesText(text) {
  await browser.storage.local.set({
    [STORAGE_KEY]: String(text || "")
  });
  cachedRules = parseRules(text);
  return cachedRules;
}

function domainMatches(hostname, domain) {
  return hostname === domain || hostname.endsWith(`.${domain}`);
}

function urlMatchesRule(urlString, rule) {
  let url;

  try {
    url = new URL(urlString);
  } catch (error) {
    return false;
  }

  if (!/^https?:$/i.test(url.protocol)) {
    return false;
  }

  if (rule.type === "domain") {
    return domainMatches(url.hostname.toLowerCase(), rule.value);
  }

  if (rule.type === "prefix") {
    const normalizedUrl = normalizeUrlPrefix(url.toString());
    return normalizedUrl.startsWith(rule.value);
  }

  return false;
}

function urlMatchesAnyRule(urlString) {
  return cachedRules.some((rule) => urlMatchesRule(urlString, rule));
}

async function deleteHistoryUrl(url) {
  try {
    await browser.history.deleteUrl({ url });
    return true;
  } catch (error) {
    console.error("Failed to delete history URL", url, error);
    return false;
  }
}

async function purgeRule(rule) {
  const needle = rule.type === "domain" ? rule.value : rule.value;
  const candidates = await browser.history.search({
    text: needle,
    startTime: 0,
    maxResults: 10000
  });

  let deleted = 0;
  const seen = new Set();

  for (const item of candidates) {
    if (!item.url || seen.has(item.url) || !urlMatchesRule(item.url, rule)) {
      continue;
    }

    seen.add(item.url);
    if (await deleteHistoryUrl(item.url)) {
      deleted += 1;
    }
  }

  return deleted;
}

async function purgeMatchingHistory() {
  let deleted = 0;

  for (const rule of cachedRules) {
    deleted += await purgeRule(rule);
  }

  return deleted;
}

async function appendRule(ruleText) {
  const current = await getRulesText();
  const lines = current
    .split(/\r?\n/)
    .map(normalizeLine)
    .filter(Boolean);

  if (!lines.includes(ruleText)) {
    lines.push(ruleText);
  }

  await saveRulesText(lines.join("\n"));
  await purgeMatchingHistory();
}

async function openOptions() {
  await browser.runtime.openOptionsPage();
}

async function handleVisited(result) {
  if (result && result.url && urlMatchesAnyRule(result.url)) {
    await deleteHistoryUrl(result.url);
  }
}

function buildMenu() {
  browser.contextMenus.removeAll().then(() => {
    browser.contextMenus.create({
      id: MENU_BLOCK_DOMAIN,
      title: "Block this domain from URL bar suggestions",
      contexts: ["page"]
    });

    browser.contextMenus.create({
      id: MENU_BLOCK_PREFIX,
      title: "Block this page URL prefix from URL bar suggestions",
      contexts: ["page"]
    });
  });
}

browser.history.onVisited.addListener(handleVisited);

browser.browserAction.onClicked.addListener(openOptions);

browser.contextMenus.onClicked.addListener(async (info, tab) => {
  if (!tab || !tab.url) {
    return;
  }

  const url = new URL(tab.url);
  if (info.menuItemId === MENU_BLOCK_DOMAIN) {
    await appendRule(url.hostname);
    await openOptions();
    return;
  }

  if (info.menuItemId === MENU_BLOCK_PREFIX) {
    await appendRule(normalizeUrlPrefix(tab.url));
    await openOptions();
  }
});

browser.runtime.onMessage.addListener((message) => {
  if (!message || !message.type) {
    return undefined;
  }

  if (message.type === "get-state") {
    return getRulesText().then((rulesText) => ({
      rulesText,
      rulesCount: cachedRules.length
    }));
  }

  if (message.type === "save-rules") {
    return saveRulesText(message.rulesText || "").then((rules) => ({
      ok: true,
      rulesCount: rules.length
    }));
  }

  if (message.type === "purge-history") {
    return purgeMatchingHistory().then((deleted) => ({
      ok: true,
      deleted
    }));
  }

  if (message.type === "open-options") {
    return openOptions().then(() => ({ ok: true }));
  }

  return undefined;
});

browser.runtime.onInstalled.addListener(async () => {
  await loadRules();
  buildMenu();
});

browser.runtime.onStartup.addListener(async () => {
  await loadRules();
  buildMenu();
});

loadRules().then(buildMenu);
