<#
.SYNOPSIS
    Lean 配置第 2 步：把 C-c C-g 换成自写的 eglot 版信息面板 my/lean-info-at-point。
.DESCRIPTION
    默认审阅模式（只写工作区里的 init.el.lean2.new / .patch）；加 -Apply 才写入 init.el 并先备份。

    lean4-toggle-info（lean4-mode 自带）是基于 lsp-mode 的实现，在 eglot 下会报
      The connected server(s) does not support method $/lean/plainGoal
    所以改用 eglot 的 textDocument/hover + $/lean/plainTermGoal + $/lean/plainGoal。
.EXAMPLE
    & .\merge-lean-info.ps1 -DryRun
    & .\merge-lean-info.ps1 -Apply
#>
[CmdletBinding()]
param(
    [string]$InitPath = "d:\home\anson\.emacs.d\init.el",
    [string]$ReviewDir = (Join-Path $PSScriptRoot "..\merge-lean"),
    [switch]$Apply,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
function Read-Text($path) { [System.IO.File]::ReadAllText($path) }
function Write-Text($path, $text) {
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}
function ToEol($text, $eol) {
    $t = $text -replace "`r`n", "`n"; $t = $t -replace "`r", "`n"
    if ($eol -ne "`n") { $t = $t -replace "`n", $eol }
    return $t
}

$init = Read-Text $InitPath
$eol = if ($init.Contains("`r`n")) { "`r`n" } else { "`n" }
Write-Host ("init.el: {0} 字符, 换行={1}" -f $init.Length, $(if ($eol -eq "`r`n") { 'CRLF' } else { 'LF' }))

# ── ① 在 (if (my/ensure-lean4-mode) 之前插入 my/lean-info-at-point ──────────
$oldA = @'
(if (my/ensure-lean4-mode)
'@
$newA = @'
(defun my/lean-info-at-point ()
  "把光标处的类型 / 期望类型 / 证明目标显示到 *Lean Info* 里。
走 eglot 的 textDocument/hover、$/lean/plainTermGoal、$/lean/plainGoal，
所以不依赖 lsp-mode（lean4-mode 自带的 lean4-toggle-info 是 lsp-mode 实现，
在 eglot 下会报 \"does not support method $/lean/plainGoal\"）。"
  (interactive)
  (let ((server (or (eglot-current-server) (user-error "当前 buffer 没有 eglot 连接")))
        (params (eglot--TextDocumentPositionParams))
        (pos (format "%s:%d" (buffer-name) (line-number-at-pos))))
    (let* ((hover (ignore-errors (eglot--request server :textDocument/hover params :timeout 15)))
           (term  (ignore-errors (eglot--request server "$/lean/plainTermGoal" params :timeout 15)))
           (goal  (ignore-errors (eglot--request server "$/lean/plainGoal" params :timeout 15)))
           (buf (get-buffer-create "*Lean Info*")))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (format "位置：%s\n\n" pos))
          (let ((hv (and hover (plist-get (plist-get hover :contents) :value))))
            (when (and hv (not (string-empty-p hv)))
              (insert "── 光标处类型 ──\n" hv "\n\n")))
          (when-let* ((g (plist-get term :goal)))
            (insert "── 期望类型 ──\n" g "\n\n"))
          (when-let* ((gs (plist-get goal :goals)))
            (insert "── 证明目标 ──\n"
                    (if (listp gs) (mapconcat #'identity gs "\n") (format "%s" gs))
                    "\n\n"))
          (when (= (point-min) (point-max))
            (insert "这里没有可显示的信息。\n")))
        (special-mode)
        (goto-char (point-min)))
      (display-buffer buf))))

(if (my/ensure-lean4-mode)
'@

# ── ② C-c C-g 改绑到 my/lean-info-at-point ─────────────────────────────────
$oldB = @'
                  ;; lean4-toggle-info-buffer 需要 buffer 参数，不是交互命令（按了会报
                  ;; Wrong number of arguments）；交互入口是 lean4-toggle-info。
                  (local-set-key (kbd "C-c C-g") #'lean4-toggle-info)
'@
$newB = @'
                  ;; C-c C-g：自写的 eglot 版信息面板（类型 / 期望类型 / 证明目标）。
                  ;; 不用 lean4-toggle-info：那是 lsp-mode 的实现，eglot 下会报
                  ;; "does not support method $/lean/plainGoal"；
                  ;; 也不用 lean4-toggle-info-buffer：它要 buffer 参数，不是交互命令。
                  (local-set-key (kbd "C-c C-g") #'my/lean-info-at-point)
'@

$pairs = @(
    @{ Name = '插入 my/lean-info-at-point'; Old = $oldA; New = $newA },
    @{ Name = 'C-c C-g 改绑 my/lean-info-at-point'; Old = $oldB; New = $newB }
)

$text = $init
foreach ($p in $pairs) {
    $old = (ToEol $p.Old $eol).TrimEnd("`r", "`n")
    $new = (ToEol $p.New $eol).TrimEnd("`r", "`n")
    $count = ([regex]::Matches($text, [regex]::Escape($old))).Count
    if ($count -ne 1) {
        throw ("找不到（或找到 {0} 次）要替换的内容：{1}`n--- 期望的原文 ---`n{2}" -f $count, $p.Name, $old)
    }
    $text = $text.Replace($old, $new)
    Write-Host ("[OK] {0}" -f $p.Name)
}

Write-Host ("原 {0} 行 → 新 {1} 行" -f (($init -split "`n").Count), (($text -split "`n").Count))
if ($DryRun) { Write-Host "`n[DRY-RUN] 没有写任何文件。" -ForegroundColor Yellow; exit 0 }

if (-not $Apply) {
    if (-not (Test-Path $ReviewDir)) { New-Item -ItemType Directory -Path $ReviewDir -Force | Out-Null }
    $origOut = Join-Path $ReviewDir 'init.el.lean2.orig'
    $newOut  = Join-Path $ReviewDir 'init.el.lean2.new'
    Write-Text $origOut $init
    Write-Text $newOut $text
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $diff = & git -c core.autocrlf=false -c core.safecrlf=false `
        diff --no-index --no-color --unified=6 -- $origOut $newOut 2>$null
    $ErrorActionPreference = $prev
    $patch = Join-Path $ReviewDir 'init.el.lean2.patch'
    Write-Text $patch (($diff | Out-String))
    Write-Host ("已写出审阅材料：`n  {0}`n  {1}`n  {2}" -f $origOut, $newOut, $patch)
    Write-Host "`n[审阅模式] 没有修改 init.el。" -ForegroundColor Yellow
    exit 0
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bak = "$InitPath.bak-before-lean-info-$stamp"
Copy-Item -LiteralPath $InitPath -Destination $bak -Force
Write-Host ("已备份: {0}" -f $bak)
Write-Text $InitPath $text

$check = Read-Text $InitPath
$ok = $check.Contains('(defun my/lean-info-at-point') -and
      $check.Contains("(kbd `"C-c C-g`") #'my/lean-info-at-point)") -and
      (-not $check.Contains("#'lean4-toggle-info)"))
Write-Host ("回读校验: {0}" -f $(if ($ok) { 'PASS' } else { 'FAIL' }))
if (-not $ok) { throw "写入后校验失败，请用备份恢复：$bak" }
Write-Host "完成。"
