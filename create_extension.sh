#!/bin/bash
set -e

BASE_DIR="Mano-AI-Pletinys"

mkdir -p "$BASE_DIR/icons"

cat <<'EOF' > "$BASE_DIR/manifest.json"
{
  "manifest_version": 3,
  "name": "AI Turinio Asistentas",
  "version": "1.0",
  "description": "Išsaugo puslapio turinį formatu, tinkamu AI apdorojimui.",
  "permissions": [ "activeTab", "scripting", "downloads" ],
  "background": { "service_worker": "service-worker.js" },
  "action": { "default_popup": "popup.html", "default_icon": { "48": "icons/icon48.png" } },
  "icons": { "48": "icons/icon48.png", "128": "icons/icon128.png" }
}
EOF

cat <<'EOF' > "$BASE_DIR/popup.html"
<!DOCTYPE html><html lang="lt"><head><meta charset="UTF-8"><title>AI Turinio Asistentas</title><link rel="stylesheet" href="popup.css"></head><body><div class="container"><h1>AI Asistentas</h1><p>Išsaugokite pagrindinį puslapio turinį.</p><button id="save-md-button">Išsaugoti kaip Markdown</button></div><script src="popup.js"></script></body></html>
EOF

cat <<'EOF' > "$BASE_DIR/popup.css"
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; width: 250px; padding: 10px; margin: 0; background-color: #f9f9f9; }
.container { text-align: center; } h1 { font-size: 18px; color: #333; margin-top: 0; } p { font-size: 14px; color: #666; }
#save-md-button { background-color: #007bff; color: white; border: none; padding: 10px 15px; border-radius: 5px; font-size: 14px; font-weight: bold; cursor: pointer; width: 100%; transition: background-color 0.2s; }
#save-md-button:hover { background-color: #0056b3; }
EOF

cat <<'EOF' > "$BASE_DIR/popup.js"
document.addEventListener('DOMContentLoaded', () => {
  const saveButton = document.getElementById('save-md-button');
  saveButton.addEventListener('click', () => { chrome.runtime.sendMessage({ action: "saveAsMarkdown" }); window.close(); });
});
EOF

cat <<'EOF' > "$BASE_DIR/service-worker.js"
importScripts('Readability.js', 'turndown.js');
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "saveAsMarkdown") {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      const activeTab = tabs[0];
      chrome.scripting.executeScript({ target: { tabId: activeTab.id }, function: getPageContent, }, (injectionResults) => {
        if (injectionResults && injectionResults[0] && injectionResults[0].result) {
            const result = injectionResults[0].result;
            const turndownService = new TurndownService();
            const markdown = turndownService.turndown(result.content);
            saveToFile(markdown, result.title);
        } else { console.error("Nepavyko išgauti puslapio turinio. Galbūt puslapis neturi aiškios straipsnio struktūros."); }
      });
    });
    return true;
  }
});
function getPageContent() { const article = new Readability(document.cloneNode(true)).parse(); return article; }
function saveToFile(content, title) {
  const safeTitle = title ? title.replace(/[^a-z0-9_]/gi, '_').toLowerCase() : 'straipsnis';
  const filename = `${safeTitle}.md`;
  const blob = new Blob([content], { type: 'text/markdown;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  chrome.downloads.download({ url: url, filename: filename, saveAs: false });
}
EOF

curl -L -o "$BASE_DIR/Readability.js" "https://raw.githubusercontent.com/mozilla/readability/master/Readability.js"
curl -L -o "$BASE_DIR/turndown.js" "https://unpkg.com/turndown/dist/turndown.js"
curl -L -o "$BASE_DIR/icons/icon48.png" "https://i.imgur.com/GRaLg5E.png"
curl -L -o "$BASE_DIR/icons/icon128.png" "https://i.imgur.com/GjT22d3.png"

echo "Sėkmė! Projektas 'Mano-AI-Pletinys' sukurtas."
