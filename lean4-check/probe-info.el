;;; probe-info.el --- 验证 my/lean-info-at-point（eglot 版 Lean 信息面板） -*- lexical-binding: t; -*-
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)
(setq lsp-session-file "d:/home/anson/workspace/my-lean-proj/lean4-check/.lsp-session-v1")
(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

;; ── 候选实现（准备写进 init.el）────────────────────────────────────────────
(defun my/lean-info-at-point ()
  "把光标处的类型/期望类型/证明目标显示到 *Lean Info* 里。
走 eglot 的 textDocument/hover、$/lean/plainTermGoal、$/lean/plainGoal，
因此不依赖 lsp-mode（lean4-toggle-info 是 lsp-mode 的实现，eglot 下会报错）。"
  (interactive)
  (let ((server (or (eglot-current-server) (user-error "当前 buffer 没有 eglot 连接")))
        (params (eglot--TextDocumentPositionParams))
        (pos (format "%s:%d" (buffer-name) (line-number-at-pos))))
    (let* ((hover (ignore-errors (eglot--request server :textDocument/hover params :timeout 15)))
           (term (ignore-errors (eglot--request server "$/lean/plainTermGoal" params :timeout 15)))
           (goal (ignore-errors (eglot--request server "$/lean/plainGoal" params :timeout 15)))
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
      (display-buffer buf)
      (with-current-buffer buf (buffer-string)))))
;; ───────────────────────────────────────────────────────────────────────────

(defun myv--grab (file marker)
  (find-file file)
  (run-hooks 'post-command-hook)
  (let ((end (+ (float-time) 120)))
    (while (and (not (eglot-current-server)) (< (float-time) end))
      (accept-process-output nil 0.2)))
  (goto-char (point-min))
  (search-forward marker nil t)
  (let ((text (my/lean-info-at-point)))
    (princ (format "\n=== %s @ %S ===\n%s\n" (file-name-nondirectory file) marker text))))

(myv--grab "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean" "IO.println")
;; Proofs.lean 里有 by 块，能拿到 plainGoal
(myv--grab "d:/home/anson/workspace/my-lean-proj/my-lean-project/MyLeanProject/Proofs.lean" "theorem two_plus_two")
(kill-emacs 0)
