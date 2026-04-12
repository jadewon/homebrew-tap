class MacClaudeNotifier < Formula
  desc "Native macOS notifications for Claude Code with click-to-activate terminal"
  homepage "https://github.com/jadewon/mac-claude-notifier"
  url "https://github.com/jadewon/mac-claude-notifier/releases/download/v0.1.0/ClaudeNotifier-v0.1.0-macOS.zip"
  sha256 "8e23de4a0b3dfe3d8e92508a3a58a38b6c8902ff0e4dfa2e1b4cdb4e7738bbdc"
  version "0.1.0"
  license "MIT"

  depends_on :macos

  def install
    prefix.install "ClaudeNotifier.app"
    bin.install_symlink prefix/"ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier"

    # Install hook script
    (buildpath/"notification.sh").write <<~BASH
      #!/bin/bash
      # Claude Code notification hook — pipes stdin JSON to ClaudeNotifier.app
      # https://github.com/jadewon/mac-claude-notifier

      APP_BUNDLE="${CLAUDE_NOTIFIER_APP:-#{opt_prefix}/ClaudeNotifier.app}"
      INPUT=$(cat)

      resolve_terminal_bundle_id() {
          if [ -n "$CLAUDE_NOTIFIER_ACTIVATE_APP" ]; then
              echo "$CLAUDE_NOTIFIER_ACTIVATE_APP"
              return
          fi

          case "${TERM_PROGRAM:-}" in
              iTerm.app)       echo "com.googlecode.iterm2" ;;
              Apple_Terminal)  echo "com.apple.Terminal" ;;
              WarpTerminal)    echo "dev.warp.Warp-Stable" ;;
              vscode)          echo "com.microsoft.VSCode" ;;
              Hyper)           echo "co.zeit.hyper" ;;
              alacritty)       echo "org.alacritty" ;;
              ghostty)         echo "com.mitchellh.ghostty" ;;
              *)               echo "com.apple.Terminal" ;;
          esac
      }

      if [ -d "$APP_BUNDLE" ]; then
          killall ClaudeNotifier 2>/dev/null

          TMPFILE=$(mktemp /tmp/claude-noti-XXXXXX)
          trap 'rm -f "$TMPFILE"' EXIT
          printf '%s' "$INPUT" > "$TMPFILE"

          BUNDLE_ID=$(resolve_terminal_bundle_id)
          open -a "$APP_BUNDLE" --args --data "$TMPFILE" --activate "$BUNDLE_ID" &
      else
          MESSAGE=$(echo "$INPUT" | jq -r '.message // "Done"')
          osascript - "$MESSAGE" <<'APPLESCRIPT'
      on run argv
          display notification (item 1 of argv) with title "🤖 Claude Code"
      end run
      APPLESCRIPT
      fi
    BASH
    bin.install "notification.sh"
  end

  def caveats
    <<~EOS
      Add this to your ~/.claude/settings.json:

        {
          "hooks": {
            "Notification": [
              {
                "matcher": "",
                "hooks": [
                  {
                    "type": "command",
                    "command": "#{opt_bin}/notification.sh"
                  }
                ]
              }
            ]
          }
        }

      First run will prompt for macOS notification permission.
    EOS
  end
end
