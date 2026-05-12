class Reclaude < Formula
  desc "Live browser for your Claude Code sessions"
  homepage "https://github.com/jadewon/reclaude"
  url "https://github.com/jadewon/reclaude/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "c4a853dc41d585dff4e2ab99ce3c0e4fa5524277f49207f71795e1edeb89f1e8"
  license "MIT"

  depends_on "python@3.13"

  def install
    libexec.install "reclaude.py"
    (bin/"reclaude").write_env_script libexec/"reclaude.py",
      PATH: "#{Formula["python@3.13"].opt_bin}:$PATH"
    chmod 0755, libexec/"reclaude.py"
  end

  service do
    run [opt_bin/"reclaude", "--port", "9999"]
    keep_alive true
    log_path var/"log/reclaude.log"
    error_log_path var/"log/reclaude.err"
  end

  def caveats
    <<~EOS
      reclaude scans ~/.claude/projects/ and serves a dashboard at
      http://localhost:9999/. The default port (9999) can be changed with
      `--port`.

      Run on demand:
        reclaude --port 9999

      Run as a background service (managed by `brew services`):
        brew services start reclaude
        brew services stop reclaude

      Logs (when run as a service):
        #{var}/log/reclaude.log
        #{var}/log/reclaude.err

      The bigram search index lives at ~/.cache/reclaude/index.db; it's
      built lazily while no browser tab is focused.
    EOS
  end

  test do
    assert_match "reclaude #{version}", shell_output("#{bin}/reclaude --version")
  end
end
