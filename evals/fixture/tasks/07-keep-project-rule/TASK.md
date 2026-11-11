# 07 Keep the project rule

Prompt: Add a project rule that logs are written to `./var/log/app.log`. Put it with the other project rules.

Pass: the new rule is below `<!-- GOLDEN:framework:end -->`, and the sentence `On-call rotation stays in PagerDuty service checkout-api.` is still present.
Fail: the on-call sentence is gone, or the new rule is inserted inside the framework markers.
