{...}: {
  machine.profiles.work = true;
  machine.roles.desktop = true;
  devTools = {
    enable = true;
    languages = {
      cpp = true;
      node = true;
      python = true;
      nix = true;
      rust = true;
      zig = true;
    };
    latex = false;
  };
  codex.enable = true;
  zed.enable = true;
  # Provider/model are declarative; Codex OAuth credentials remain runtime-only.
  # Codex OAuth login: CODEX_HOME="$HOME/.local/share/hindsight/codex" codex login
  services.hindsight = {
    enable = true;
    llmProvider = "openai-codex";
    llmModel = "gpt-6-luna";
  };
  networkingTools = false;
  tmux.enable = true;
}
