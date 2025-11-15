# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
# Shell Options
setopt nohashdirs
setopt login
# Aliases
alias -- run-help=man
alias -- which-command=whence
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/Users/cedricmukolonga/.npm-global/lib/node_modules/\@anthropic-ai/claude-code/vendor/ripgrep/arm64-darwin/rg'
fi
export PATH=/Users/cedricmukolonga/.npm-global/bin\:/Users/cedricmukolonga/google-cloud-sdk/bin\:/opt/homebrew/opt/postgresql\@16/bin\:/Users/cedricmukolonga/.codeium/windsurf/bin\:/Users/cedricmukolonga/miniconda3/bin\:/opt/homebrew/bin\:/opt/homebrew/sbin\:/opt/local/bin\:/opt/local/sbin\:/Library/Frameworks/Python.framework/Versions/3.11/bin\:/Users/cedricmukolonga/.npm-global/bin\:/usr/local/bin\:/System/Cryptexes/App/usr/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin\:/Library/Apple/usr/bin\:/Users/cedricmukolonga/google-cloud-sdk/bin\:/opt/homebrew/opt/postgresql\@16/bin\:/Users/cedricmukolonga/.codeium/windsurf/bin\:/Users/cedricmukolonga/miniconda3/bin
