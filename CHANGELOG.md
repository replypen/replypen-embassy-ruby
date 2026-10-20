# Changelog

## 0.17.0

- **`Client#start_analysis(credentials:)`** sends the optional per-run `credentials` map (hub decision 29):
  the chat claim's rules, shared via `ReplyPen::Embassy::Credentials.claim!`, plus "requires a `principal`";
  else `CREDENTIALS_INVALID` before sending. Omitted when nil/empty. Emits `trigger_with_credentials.json`
  byte-for-byte. Needs a host that knows the field (an older host answers `400`).
- Credential values containing NUL are refused (chat token too), matching the host.
- Contract fixtures re-vendored from hub `9aa0bfcf9832e2f7637c9fd0f0800b6f4477023f`.

## 0.16.0

- **`Chat.token(credentials:)`** mints the optional per-session `credentials` claim (hub decision 20):
  env name → string, keys sorted, validated like the host (UPPER_SNAKE, no `RC_`, ≤ 8 entries, ≤ 8 KiB),
  else `CREDENTIALS_INVALID`. Mints `jwt_vector_credentials_replypen.json` byte-for-byte.

## 0.15.0

- **Rebrand to ReplyPen:** gem `replypen-embassy`, namespace `ReplyPen::Embassy`, code under
  `lib/replypen/`. Legacy surface keeps working unchanged: gem name `rootcause-embassy` (second
  gemspec, same files), `require "rootcause-embassy"` / `"rootcause/embassy"`, and `RootCause` as an
  alias of the same module.
- **Chat tokens mint `aud` `replypen:chat:<project>`** (was `rootcause:chat:<project>`; the host accepts both).
- Hints and docs name `REPLYPEN_*` env vars; the gem still reads no env — initializers choose names.
- Log prefixes `[rootcause-action]`/`[rootcause-result]`/… → `[replypen-…]`; placeholder fetch URL host
  `replypen.invalid`. Wire defaults (`/rootcause/action`, `/rootcause/result`, `tmp/rootcause/actions`) unchanged.
- Contract fixtures re-vendored from hub `450e9d8a9195a58aae6c7f0d812587e4d18a88c9`.

## 0.14.0

- Loader contract `?v=5` enables the hosted loader's per-message `getPageContext` callback.
- Contract fixtures re-vendored from hub `b3a9dad1c1d36f160a554a9cb1b5719aaa3caf5c`, including unsigned URL normalization cases.

## 0.13.0

- **Loader contract `?v=4`** (`Chat::LOADER_CONTRACT`): the hosted loader's persistent Turbo mode
  (one conversation across soft navigations, tokens only from a `refreshToken` hook, `data-rc-scope`
  boundary guard). Tags from `chat_widget_tag` behave as before; a persistent host builds its own tag
  from `Chat.token` + `LOADER_PATH`/`LOADER_CONTRACT`. Hub decision 23.
- Contract fixtures re-vendored from hub `2be70da93fcffcf48e3676905a36bd9d6f8579f0`.

## 0.12.1

- **Over-cap inline attachments** — an `unavailable` descriptor may declare any `size_bytes`; byte
  caps (8 MiB/file, 20 MiB total) count only descriptors carrying bytes. The host sends a file past
  them this way instead of refusing the action.

## 0.12.0

Integrator-visible changes (additive):

- **`RC_ACTION_RUN_ID`** — executing invocations may carry the host's `action_run_id`; it is exposed
  to the action script only while it runs (inherited values removed, restored after). Absent field →
  no variable; a malformed value refuses as signed `400 invalid_request`.
- **`start_analysis(context_refs:)`** — hand back at most one `{kind: "action_run", id:}` so the
  analysis can read the chat behind an action-created record. Shape is checked before sending
  (`ANALYSIS_REQUEST_INVALID`).
- **`TriggerError#status` / `#code`** — HTTP status and the host's error code (e.g.
  `CONTEXT_REF_REFUSED`, retry without `context_refs`); `nil` on transport/malformed responses.
- Trigger bodies now emit the hub golden key order (no semantic change).
- Contract fixtures re-vendored from hub `6d2c81878dc34c7d171b8f6cb38964b5e861880a`.

## 0.10.0

Integrator-visible changes:

- **`error.backtrace` is now a STRING**, frames joined with `"\n"` and still capped at
  `max_backtrace_lines`. It was a JSON array, which the rootcause host (and the wire contract:
  `rootcause-embassy/CONTRACT.md`, golden `fixtures/actions/result_action_error.json`) decodes into a
  string field — so **every action whose script raised** came back as a signed HTTP 200 the host could
  not unmarshal, settling the run as `uncertain`/`parse_result` and losing the real exception. The
  total-deadline result now carries `""` instead of `[]` for the same reason.
- Contract fixtures re-vendored from hub `9851dc4bd2017a07bdfeb9505bb3e4cd82c385f7`.

## 0.9.0

Integrator-visible changes:

- **`dry_run` must be a JSON boolean.** A non-boolean value is now refused with `400 invalid_request`
  *before* the script fetch, instead of being read as truthy. Absent still means "execute".
- **`actions[].resource_url` is validated.** A value that is not an absolute `http(s)` URL is dropped
  from the proposed action; the analysis result is still delivered. `executed_actions[]` never carries
  the field.
- **New config `max_total_attachment_bytes` (default 6 MiB).** `start_analysis` now raises before
  sending when a trigger's decoded attachments exceed the aggregate cap, matching the host's limit.
  The per-attachment `max_attachment_bytes` is unchanged.
- **A malformed API URL raises `ArgumentError`.** `Api#request` previously turned an unparseable URL
  or port into a retryable `Response`, which a background job would retry forever.
- Unexpected-exception log lines carry the exception class only, never its message text.
