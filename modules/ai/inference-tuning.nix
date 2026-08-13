# modules/ai/inference-tuning.nix
#
# Low-risk system tuning for efficient local inference on the laptop (see
# steward/docs/12). Safe to apply anytime; the only tradeoff is more heat/battery
# drain from the performance governor (worth it while plugged in).
#
#   * performance governor : your CPU is on `powersave`, which throttles clocks
#                            and adds latency to every token. `performance` keeps
#                            the i5-9300H's cores up during inference.
#   * thermald             : Intel thermal daemon — keeps an H-series chip from
#                            thermal-throttling under sustained load (so the
#                            performance governor doesn't just cook and downclock).
{
  config,
  pkgs,
  ...
}:
{
  # Plugged-in inference: keep clocks high. (On intel_pstate this maps to the
  # performance mode.) If you want battery-aware switching instead, use TLP and
  # scope performance to AC — ask and I'll stage that variant.
  powerManagement.cpuFreqGovernor = "performance";

  # Intel thermal management — prevents throttle-storms on the H CPU.
  services.thermald.enable = true;

  # NOTE on threads: llama.cpp/Ollama thread count is set per-model/per-request
  # (num_thread: 4), not here — 4 = your physical cores. See docs/12.
}
