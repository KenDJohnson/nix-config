{
  config,
  lib,
  inputs,
  ...
}: let
  mkModel = {
    model,
    provider ? "openai-codex",
    effort ? "max",
  }: "${provider}/${model}:${effort}";
  default-model = "gpt-6.1-sol";
  localMemory = {
    memories = {
      backend = "local";
      maxRolloutAgeDays = 120; # 30
      minRolloutIdleHours = 12;
      maxRolloutsPerStartup = 128; # 64
      threadScanLimit = 512; # 300
      maxRawMemoriesForGlobal = 200;
      stage1Concurrency = 8;
      stage1RetryDelaySeconds = 120;
      phase2LeaseSeconds = 180;
      phase2RetryDelaySeconds = 180;
      phase2HeartbeatSeconds = 30;
      rolloutPayloadPercent = 0.7;
      phase1InputTokenLimit = 4000;
      fallbackTokenLimit = 16000;
      summaryInjectionTokenLimit = 5000;
    };
  };
in {
  imports = [inputs.omp.homeManagerModules.default];

  config = lib.mkIf config.agents.enable {
    programs.omp = {
      enable = config.agents.omp.enable;
      settings = {
        advisor = {
          enabled = false;
          syncBacklog = "off"; # off|1|3|5|strict
          immuneTurns = 3;
          reviewMode = "turn"; # turn|agent-end
          reviewInterval = 1;
          maxNotesPerUpdate = 4;
          evictStaleResults = true;
        };
        async.enabled = true;
        bash = {
          autoBackground = {
            enabled = true;
            thresholdMs = 60000;
          };
          allowCompoundCommands = false; # ??
          direnv = "auto";
          direnvLoadTimeoutMs = 60000;
        };
        checkpoint.enabled = true;
        collab = {
          autoStart = "control";
        };
        composer.shape = "box";
        contextPromotion.enabled = false;
        defaultThinkingLevel = "auto";
        dev.autoqaConsent = "denied";
        display = {
          shimmer = "kitt"; # "classic|disabled"
          smoothStreaming = true;
          hideToolActivity = false;
          showTokenUsage = true;
          showTurnTime = true;
          cacheMissMarker = true;
          collapseCompacted = true;
        };
        github.enabled = true;
        hideThinkingBlock = true;
        interruptMode = "immediate";
        # setupVersion = 2;
        live.voice = "sol"; # arbor|breeze|cove|ember|juniper|maple|sol|spruce|vale
        modelRoles = {
          default = mkModel {model = default-model;};
          slow = mkModel {model = "gpt-6-astra";};
          designer = mkModel {model = "gpt-6-astra";};
          smol = mkModel {
            model = "gpt-6-luna";
            effort = "xhigh";
          };
          plan = mkModel {model = "gpt-6-astra";};
        };
        power.sleepPrevention = "idle"; # off|idle|display|system
        providers = {
          openai-codex = {
            codeMode = "off"; # off|on|auto
            codeModeDirectTools = [];
          };
        };
        secrets = {
          enabled = false;
        };
        skills = {
          enabled = true;
          enableCodexUser = true;
          enableClaudeUser = true;
          ignoredSkills = [];
        };
        stt = {
          enabled = true;
          language = "en";
          submitTrigger = "never"; # never|release|release-complete|say-submit
        };
        speech = {
          enabled = false;
          mode = "assistant"; # all|assistant|yield
          enhanced = false;
          voice = "af_heart"; # af_heart|af_bella|af_nicole|af_aoede|af_kore|af_sarah|am_michael|am_fenrir|am_puck|bf_emma|bm_george|bm_fable
        };
        symbolPreset = "nerd";
        theme.dark = "titanium";
        telemetry.otlpExportEnabled = true;
        tier = {
          openai = "priority"; # priority=fast  none|auto|default|flex|scale|priority|ultrafast
          anthropic = "none"; # none|priority
          subagent = "inherit";
          advisor = "none";
        };
        ttsr = {
          enabled = true;
          judge = "auto";
          contextMode = "discard";
          interruptMode = "always";
          repeatMode = "once";
          repeatGap = 10;
          builtinRules = true;
          disabledRules = [];
        };
        tui = {
          renderMermaid = true;
          mouse = true;
          # vimMode = true;
        };
        prewalk = {enabled = false;};
        # codexResets.autoRedeem = unset (unset|yes|no)
        # codexResets.minBlockedMinutes = 60 (number)
        # codexResets.keepCredits = 0 (number)
        # codexResets.salvageHorizonHours = 12 (number)
        # claudeResets.autoRedeem = unset (unset|yes|no)
        # claudeResets.minBlockedMinutes = 60 (number)
        # claudeResets.keepCredits = 0 (number)
        # claudeResets.salvageHorizonHours = 12 (number)
      };
    };
  };
}
