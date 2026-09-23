<#
.SYNOPSIS
    修 init.el 里的 Lean 4 部分：新增 my/lean-run，并修正 C-c C-g 绑定。
.DESCRIPTION
    默认「审阅模式」：只在工作区生成 init.el.lean.new / init.el.lean.patch，不动 init.el。
    加 -Apply 才写入，且会先备份成 init.el.bak-before-lean-fix-<时间戳>，写完回读校验。

    改动共 3 处：
      ① 在 (if (my/ensure-lean4-mode) ...) 之前插入 my/lean-run 定义
      ② lean4-mode-hook 里 C-c C-g 由 lean4-toggle-info-buffer 改成 lean4-toggle-info
      ③ 同一个 hook 里把 C-c C-x / C-c C-l 绑到 my/lean-run（原生版本在 WinGet 版 elan 下报 lean4-rootdir 错）
.EXAMPLE
    & .\merge-lean-init.ps1 -DryRun
    & .\merge-lean-init.ps1            # 出审阅材料
    & .\merge-lean-init.ps1 -Apply     # 真正写入（需要工作区外写权限）
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
    $t = $text -replace "`r`n", "`n"
    $t = $t -replace "`r", "`n"
    if ($eol -ne "`n") { $t = $t -replace "`n", $eol }
    return $t
}

$init = Read-Text $InitPath
$eol = if ($init.Contains("`r`n")) { "`r`n" } else { "`n" }
Write-Host ("init.el: {0} 字符, 换行={1}" -f $init.Length, $(if ($eol -eq "`r`n") { 'CRLF' } else { 'LF' }))

# ── ① 插入 my/lean-run ─────────────────────────────────────────────────────
$oldA = @'
(if (my/ensure-lean4-mode)
'@
$newA = @'
;; ★ 运行当前 .lean 文件（C-c C-x）：
;; 原生的 C-c C-x / C-c C-l（lean4-execute）在 WinGet 装的 elan 上会报
;;   Incorrect `lean4-rootdir' value, path '...\WinGet\bin\lean.exe' does not exist
;; 因为 lean4-mode 从 shim 路径 ...\WinGet\Links\lean.exe 反推 rootdir=...\WinGet\，
;; 再拼 bin\lean.exe 就找不到（真正的 toolchain 在 ~/.elan/toolchains/...）。
;; 这里直接用 PATH 里的 lake —— elan 会按项目 lean-toolchain 选工具链，
;; 不依赖 lean4-rootdir，升级 toolchain 也不用改配置。
;; 若你更想用原生的 lean4-execute，可以额外加一行（版本号需跟着 toolchain 改）：
;;   (setq lean4-rootdir "C:/Users/anson/.elan/toolchains/leanprover--lean4---v4.31.0/")
(defun my/lean-run (&optional arg)
  "用 lake 跑当前 .lean 文件；有前缀参数（C-u）则加 --run 执行文件里的 main。
不依赖 `lean4-rootdir'，工具链由项目里的 lean-toolchain 决定。"
  (interactive "P")
  (let* ((file (or buffer-file-name (user-error "当前 buffer 没有关联文件")))
         (root (or (and (fboundp 'lean4-lake-find-dir) (lean4-lake-find-dir))
                   (file-name-directory file)))
         (extra (if arg "--run " ""))
         (cmd (format "lake env lean %s%s" extra (shell-quote-argument file))))
    (let ((default-directory (file-name-as-directory root)))
      (compile cmd))))

(if (my/ensure-lean4-mode)
'@

# ── ②③ 修 hook 里的按键 ────────────────────────────────────────────────────
$oldB = @'
                  (local-set-key (kbd "C-c C-g") #'lean4-toggle-info-buffer)
                  (local-set-key (kbd "M-/") #'company-complete))))
'@
$newB = @'
                  ;; lean4-toggle-info-buffer 需要 buffer 参数，不是交互命令（按了会报
                  ;; Wrong number of arguments）；交互入口是 lean4-toggle-info。
                  (local-set-key (kbd "C-c C-g") #'lean4-toggle-info)
                  ;; 原生 C-c C-x / C-c C-l（lean4-execute）在 WinGet 版 elan 下会因
                  ;; lean4-rootdir 推导错误而失败，换成走 PATH 里 lake 的版本。
                  (local-set-key (kbd "C-c C-x") #'my/lean-run)   ; 跑整个文件（看 #eval）
                  (local-set-key (kbd "C-c C-l") #'my/lean-run)   ; 同上
                  (local-set-key (kbd "M-/") #'company-complete))))
'@

$pairs = @(
    @{ Name = '插入 my/lean-run'; Old = $oldA; New = $newA },
    @{ Name = '修 C-c C-g 绑定 + 新增 C-c C-x/C-c C-l'; Old = $oldB; New = $newB }
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

$newText = $text
Write-Host ("原 {0} 行 → 新 {1} 行" -f (($init -split "`n").Count), (($newText -split "`n").Count))

if ($DryRun) {
    Write-Host "`n[DRY-RUN] 没有写任何文件。" -ForegroundColor Yellow
    exit 0
}

if (-not $Apply) {
    if (-not (Test-Path $ReviewDir)) { New-Item -ItemType Directory -Path $ReviewDir -Force | Out-Null }
    $origOut = Join-Path $ReviewDir 'init.el.lean.orig'
    $newOut  = Join-Path $ReviewDir 'init.el.lean.new'
    Write-Text $origOut $init
    Write-Text $newOut $newText
    $patch = Join-Path $ReviewDir 'init.el.lean.patch'
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $diff = & git -c core.autocrlf=false -c core.safecrlf=false `
        diff --no-index --no-color --unified=6 -- $origOut $newOut 2>$null
    $ErrorActionPreference = $prev
    Write-Text $patch (($diff | Out-String))
    Write-Host ("已写出审阅材料：`n  {0}`n  {1}`n  {2}" -f $origOut, $newOut, $patch)
    Write-Host "`n[审阅模式] 没有修改 init.el。加 -Apply 才会真正写入。" -ForegroundColor Yellow
    exit 0
}

# ── 备份 + 写入 ────────────────────────────────────────────────────────────
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bak = "$InitPath.bak-before-lean-fix-$stamp"
Copy-Item -LiteralPath $InitPath -Destination $bak -Force
Write-Host ("已备份: {0}" -f $bak)
Write-Text $InitPath $newText

$check = Read-Text $InitPath
$ok = $check.Contains('(defun my/lean-run') -and
      $check.Contains("(kbd `"C-c C-g`") #'lean4-toggle-info)") -and
      $check.Contains("(kbd `"C-c C-x`") #'my/lean-run)") -and
      (-not $check.Contains("#'lean4-toggle-info-buffer)"))
Write-Host ("回读校验: {0}" -f $(if ($ok) { 'PASS' } else { 'FAIL' }))
if (-not $ok) { throw "写入后校验失败，请用备份恢复：$bak" }
Write-Host "完成。"
