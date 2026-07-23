TASK-002 lần này tốt hơn TASK-001 khá nhiều vì agent đã:

* benchmark trước/sau
* syntax check
* có rollback docs
* validate regression policy
* đọc lại file khi patch drift
* đo minimal vs default thật

Tức là đã chuyển từ “blind refactor” sang “measurement-driven hardening”.

Nhưng vẫn còn vài điểm cần audit kỹ trước khi coi là “production-grade”.

# Điểm tốt thật sự

## 1. Shell mode contract là hướng đúng

`minimal / normal / full`

đây là pattern tốt cho dotfiles lớn.

Nó giải quyết:

* SSH latency
* nested tmux startup explosion
* CI shells
* remote shells

rất hiệu quả.

---

## 2. Remote-aware downgrade

Đây là optimization thực chiến.

Nếu shell detect:

* SSH
* CI
* nested tmux

và tự downgrade:

```bash
DOTFILES_SHELL_MODE=minimal
```

=> startup latency thường giảm rất nhiều.

Đây là kiểu optimization senior-level thật.

---

## 3. Benchmark policy fix là đúng

Agent đã nhận ra:

> percentage thresholds vô nghĩa ở latency nhỏ

đây là insight rất tốt.

Ví dụ:

* 7ms → 8ms
* tăng 14%

nhưng thực tế noise scheduler thôi.

Absolute threshold cho micro-latency là đúng hướng.

---

# Nhưng vẫn có vài nguy cơ lớn

# 1. compinit vẫn là bottleneck

Bạn nói:

> compinit remains ~15.9 ms

Cái này nghĩa là:

* optimization hiện tại chủ yếu là skip integrations
* chưa đụng core completion path

15ms chỉ riêng compinit là vẫn khá cao.

---

# 2. Agent có thể đang “che latency” chứ chưa giảm thật

Đây là vấn đề cực phổ biến.

Ví dụ:

```zsh
if [[ "$MODE" == minimal ]]; then
   skip_everything
fi
```

benchmark sẽ đẹp hơn.

NHƯNG:

* user experience bị amputate
* shell mất functionality
* autocomplete mất
* plugins mất

=> startup nhanh hơn vì… không load gì nữa.

Nên cần phân biệt:

* latency reduction
  vs
* feature removal

---

# 3. Cần verify compdump invalidation logic

Đây là chỗ dễ sinh bug âm thầm.

Nếu agent tự:

```zsh
rm ~/.zcompdump*
```

khi detect corruption,

cần verify:

* race conditions
* concurrent shell startup
* stale lock
* tmux multi-pane launch

nếu không sẽ có:

* random completion freeze
* corrupted dump loop
* startup spikes

---

# 4. `typeset -U path PATH` có thể reorder PATH

Đây là subtle bug.

`typeset -U` dedupe bằng cách giữ first occurrence.

Nếu PATH mutations trước đó không deterministic:

* pyenv
* cargo
* go
* local bin

có thể reorder unintentionally.

=> sai executable priority.

Cần verify:

```bash
which python
which gcc
which node
```

ở:

* minimal
* normal
* full
* ssh
* tmux nested

---

# 5. “nested tmux => minimal” có thể dangerous

Một số workflow:

```bash
wezterm
  -> tmux
      -> ssh
          -> tmux
```

nếu auto minimal quá aggressively:

* completions mất
* aliases mất
* shell UX inconsistent

Nên:
minimal auto-mode chỉ nên skip:

* diagnostics
* animations
* telemetry
* expensive hooks

KHÔNG nên skip:

* core completions
* navigation
* PATH
* history

---

# Điều cần làm ngay trước TASK-003

# A. Validate startup graph

Chạy:

```bash
zsh -xvic exit &> startup.log
```

rồi inspect:

* plugin load order
* compinit duplication
* PATH mutations
* slow shell-outs

---

# B. Verify shell modes thật

Test matrix:

| Context       | Expected                   |
| ------------- | -------------------------- |
| local normal  | full UX                    |
| local minimal | fast stripped              |
| ssh           | auto minimal               |
| nested tmux   | degraded optional features |
| CI            | no interactive junk        |

---

# C. Đo interactive latency, không chỉ startup

Startup nhanh chưa đủ.

Test:

```bash
time zsh -ic exit
```

và:

* first completion latency
* prompt redraw
* tmux pane spawn

---

# D. Verify compdump cache

Kiểm tra:

```bash
ls -lh ~/.cache/zsh/
```

và ensure:

* không regenerate every shell
* timestamp stable
* no lock contention

---

# Về TASK-003 tmux hardening

Đây mới là nơi performance thường chết thật.

tmux statusline shell-outs cực dễ gây:

* CPU spikes
* lag input
* redraw stalls

đặc biệt nếu mỗi 1s chạy:

```tmux
#(git status)
#(kubectl ...)
#(python ...)
```

---

# Hướng đúng cho TASK-003

Agent nên:

1. benchmark statusline shell-outs
2. measure redraw latency
3. isolate async segments
4. cache expensive commands
5. event-driven refresh
6. no shell-outs every interval

---

# Quan trọng nhất

Lần này agent finally bắt đầu có dấu hiệu:

* hypothesis-driven
* benchmark-first
* rollback-aware
* regression-aware

Đây là bước tiến lớn so với kiểu “refactor rồi cầu nguyện”.
