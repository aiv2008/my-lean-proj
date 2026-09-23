# Lean 4 运行配置修复记录（**已合并进 init.el**）

针对你截图里那个问题："`PipeTest.lean` 怎么运行" —— 结论是 emacs 里原生的
`C-c C-x` / `C-c C-l`（`lean4-execute`）在你的环境下**必然报错**，我改掉了，并补了一个
eglot 版的 Lean 信息面板。

- 合并时间：2026-09-23 10:07 与 10:20（分两步）
- 备份：
  - `d:\home\anson\.emacs.d\init.el.bak-before-lean-fix-20260923-100705`（改动前，= Vue 合并后的状态）
  - `d:\home\anson\.emacs.d\init.el.bak-before-lean-info-20260923-102001`（插入 my/lean-info-at-point 之前）
- 当前 `init.el`：**1267 行 / 55126 字节**，SHA256 `77FBA8092A6E47D4E35E52DE3C58D8BCBB979365C7A3E1844B81B197BDEEA81A`
- diff：`merge-lean/init.el.lean-fix.patch`（相对改动前的完整补丁）
- 落地后实测：`verify-lean-final.log` → **11/11 通过**

## 一、先说怎么运行（结论）

两种"运行"：

| 想要的效果 | 命令 |
| --- | --- |
| 看所有 `#eval` 的结果（编译期求值，不需要 main） | `lake env lean PipeTest.lean` |
| 执行文件里的 `main` | `lake env lean --run PipeTest.lean` |
| 跑 lakefile 里注册的可执行文件（root = Main） | `lake exe myleanproject` |

实测输出（项目目录 `D:\home\anson\workspace\my-lean-proj\my-lean-project`）：

```
$ lake env lean PipeTest.lean
6
[10, 20, 30, 7, 8]
"<14>"
"<14>"
"<512>"
"<3>"

$ lake env lean --run PipeTest.lean
（同上 6 行）
hello 2          ← main 里 greet 打印的
```

Emacs 里对应：

- `C-c C-x`：跑整个文件（看 `#eval`），输出在 `*compilation*`
- `C-u C-c C-x`：加 `--run`，执行 `main`
- `C-c C-l`：同 `C-c C-x`（原生就绑了这两个键）
- `C-c C-g`：看光标处的类型 / 期望类型 / 证明目标（`*Lean Info*`）

## 二、为什么原生的键不能用

`lean4-execute` 会拼出 `<lean4-rootdir>/bin/lake.exe env <lean4-rootdir>/bin/lean.exe <文件>`，
而 `lean4-rootdir` 是从 `executable-find "lean"` 去掉两级目录推出来的：

```
executable-find lean = c:/Users/anson/AppData/Local/Microsoft/WinGet/Links/lean.exe
                  ↓ 去掉 Links/ 再去掉 WinGet/
lean4-rootdir        = c:/Users/anson/AppData/Local/Microsoft/WinGet/
                  ↓ 拼 bin/lean.exe
                     ...\WinGet\bin\lean.exe   ← 不存在 → 报错
Incorrect `lean4-rootdir' value, path '...\WinGet\bin\lean.exe' does not exist
```

你的 elan 是 WinGet 装的，shim 落在 `WinGet\Links\`，而真正的 toolchain 在
`C:\Users\anson\.elan\toolchains\leanprover--lean4---v4.31.0\bin\`。

## 三、改了什么（2 个函数 + 3 个按键）

### ① 新增 `my/lean-run`（放在 Lean 那一节开头）

用 PATH 里的 `lake`（elan 会按项目 `lean-toolchain` 选工具链），不碰 `lean4-rootdir`，
将来升级 toolchain 也不用改配置：

```elisp
(defun my/lean-run (&optional arg)
  (interactive "P")
  (let* ((file (or buffer-file-name (user-error "当前 buffer 没有关联文件")))
         (root (or (and (fboundp 'lean4-lake-find-dir) (lean4-lake-find-dir))
                   (file-name-directory file)))
         (extra (if arg "--run " ""))
         (cmd (format "lake env lean %s%s" extra (shell-quote-argument file))))
    (let ((default-directory (file-name-as-directory root)))
      (compile cmd))))
```

> 注释里也留了"硬编码方案"备查，想用原生 `lean4-execute` 就加：
> `(setq lean4-rootdir "C:/Users/anson/.elan/toolchains/leanprover--lean4---v4.31.0/")`

### ② 新增 `my/lean-info-at-point`，并把 `C-c C-g` 改绑到它

你原来绑的 `lean4-toggle-info-buffer` 需要 buffer 参数，**不是交互命令**，按了会报
`Wrong number of arguments: ... 0`；而它旁边的 `lean4-toggle-info` 是 **lsp-mode 的实现**，
你的 Lean 走的是 eglot，会报 `does not support method $/lean/plainGoal`。
所以用 eglot 的原生请求自己拼了一个面板（`textDocument/hover` + `$/lean/plainTermGoal` + `$/lean/plainGoal`）。

### ③ `C-c C-x` / `C-c C-l` → `my/lean-run`

```elisp
(local-set-key (kbd "C-c C-g") #'my/lean-info-at-point)
(local-set-key (kbd "C-c C-x") #'my/lean-run)   ; 跑整个文件（看 #eval）
(local-set-key (kbd "C-c C-l") #'my/lean-run)   ; 同上
```

## 四、验证（`verify-lean-final.log`，11/11）

```
[PASS] 主模式 lean4-mode
[PASS] C-c C-x → my/lean-run
[PASS] C-c C-l → my/lean-run
[PASS] C-c C-g → my/lean-info-at-point
[PASS] eglot 连上 Lean 服务器  -> (:name "Lean 4 Server" :version "0.3.0")
[PASS] 按 C-c C-x 生成 lake env lean <文件>
[PASS] C-c C-x 真跑：输出含全部 #eval 结果  -> 退出码 0
[PASS] C-u C-c C-x 生成 --run
[PASS] 带 --run 真跑：打印 hello 2  -> 退出码 0
[PASS] 信息面板给出光标处类型（IO Unit）
[PASS] by 块里能看到证明目标（⊢ 0 + n = n）
```

`*Lean Info*` 实际长这样：

```
位置：Proofs.lean:20
── 光标处类型 ──       （induction 的文档，来自 hover）
── 证明目标 ──
[n : Nat
⊢ 0 + n = n]
```

复跑：

```powershell
& "D:\soft\emacs-31.1\bin\emacs.exe" -Q --batch `
  -l "D:\home\anson\workspace\my-lean-proj\lean4-check\verify-lean-final.el"
```

## 五、回滚

```powershell
# 只回滚"信息面板"这一步
Copy-Item "d:\home\anson\.emacs.d\init.el.bak-before-lean-info-20260923-102001" `
          "d:\home\anson\.emacs.d\init.el" -Force

# 回滚所有 Lean 改动（保留 Vue 的 7b 节）
Copy-Item "d:\home\anson\.emacs.d\init.el.bak-before-lean-fix-20260923-100705" `
          "d:\home\anson\.emacs.d\init.el" -Force
```

## 六、踩坑记录（值得留档）

1. **批处理下的假故障**：`emacs -Q --batch` 里 `~/.emacs.d` 不可写（沙箱），
   lsp-mode 保存 `.lsp-session-v1` 失败，错误发生在 `lean4-mode` 的 mode body 里，
   直接中断了后面的 `lean4-mode-hook` —— 表现是"按键没生效"。
   验证时把 `lsp-session-file` 指到工作区即可复现正常行为。
2. **按键优先级**：`define-derived-mode` 的 body 先跑（含 `lean4-set-keys`），
   之后才 `run-mode-hooks`，所以 hook 里的 `local-set-key` 能覆盖原生绑定。
3. `lean4-info.el` 整个是围绕 lsp-mode 写的（`lsp-notify` / `lsp-request`），
   eglot 用户别指望它。

## 七、目录里其他文件

| 文件 | 说明 |
| --- | --- |
| `merge-lean/init.el.lean-fix.patch` | 本次 Lean 改动的 unified diff |
| `merge-lean/init.el.before-lean-fix` / `.after-lean-fix` | 改动前 / 改动后的 init.el 副本 |
| `verify-lean-final.el` / `.log` | 11/11 的验证脚本与输出 |
| `run-cmd2.el` / `run-cmd3.el` + 日志 | 早期排查：原生键为何报错、拼出的命令长什么样 |
| `probe-order.el` / `probe-keys.el` / `probe-keys2.el` / `probe-info.el` + 日志 | 定位"按键被覆盖"的沙箱假故障、验证信息面板 |
| `tools/merge-lean-init.ps1` / `merge-lean-info.ps1` | 两次改动用的合并脚本（默认审阅模式，`-Apply` 才写） |
