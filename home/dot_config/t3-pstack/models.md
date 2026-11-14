# pstack model configuration (T3). One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat's model (`delegate_task` omits `target`). Alias entries in a panel list still count toward its fan-out.
# budget: large (xhigh)
feature, refactoring: claudeAgent/claude-opus-5-5 effort=xhigh
bug-fix: claudeAgent/claude-opus-5-5 effort=xhigh
perf-issue: claudeAgent/claude-opus-5-5 effort=xhigh
hillclimb: claudeAgent/claude-opus-5-5 effort=xhigh
judgment and prose: codex/gpt-6.1-sol reasoningEffort=xhigh
hardest tasks: claudeAgent/claude-opus-5-5 effort=xhigh
how explorer: codex/gpt-6.1-sol reasoningEffort=xhigh
how explainer: codex/gpt-6.1-sol reasoningEffort=xhigh
why investigators: codex/gpt-6.1-sol reasoningEffort=xhigh
why synthesizer: codex/gpt-6.1-sol reasoningEffort=xhigh
reflect tooling: codex/gpt-6.1-sol reasoningEffort=xhigh
reflect judgment, divergent, synthesizer: codex/gpt-6.1-sol reasoningEffort=xhigh
arena runners: claudeAgent/claude-opus-5-5 effort=xhigh, codex/gpt-6.1-sol reasoningEffort=xhigh
arena cross-judge pool: codex/gpt-6.1-sol reasoningEffort=xhigh, claudeAgent/claude-opus-5-5 effort=xhigh
swarm workers: claudeAgent/claude-opus-5-5 effort=xhigh
architect runners: claudeAgent/claude-opus-5-5 effort=xhigh, codex/gpt-6.1-sol reasoningEffort=xhigh
interrogate reviewers: claudeAgent/claude-opus-5-5 effort=xhigh, codex/gpt-6.1-sol reasoningEffort=xhigh
session hook: on
