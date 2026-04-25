const rulesField = document.getElementById("rules");
const saveButton = document.getElementById("save");
const purgeButton = document.getElementById("purge");
const statusNode = document.getElementById("status");

function setStatus(message, isError = false) {
  statusNode.textContent = message;
  statusNode.classList.toggle("error", isError);
}

async function loadState() {
  try {
    const response = await browser.runtime.sendMessage({ type: "get-state" });
    rulesField.value = await response.rulesText;
    setStatus(`Loaded ${response.rulesCount} rule(s).`);
  } catch (error) {
    setStatus(`Failed to load rules: ${error}`, true);
  }
}

async function saveRules() {
  try {
    const response = await browser.runtime.sendMessage({
      type: "save-rules",
      rulesText: rulesField.value
    });
    setStatus(`Saved ${response.rulesCount} rule(s).`);
  } catch (error) {
    setStatus(`Failed to save rules: ${error}`, true);
  }
}

async function purgeHistory() {
  try {
    setStatus("Purging matching history...");
    const response = await browser.runtime.sendMessage({
      type: "purge-history"
    });
    setStatus(`Deleted ${response.deleted} matching history entr${response.deleted === 1 ? "y" : "ies"}.`);
  } catch (error) {
    setStatus(`Failed to purge history: ${error}`, true);
  }
}

saveButton.addEventListener("click", saveRules);
purgeButton.addEventListener("click", purgeHistory);

loadState();
