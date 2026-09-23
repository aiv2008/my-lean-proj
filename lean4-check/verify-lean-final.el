;;; verify-lean-final.el --- init.el 改完后的最终验证（Lean 运行 + 信息面板） -*- lexical-binding: t; -*-
;; 注意：批处理里 ~/.emacs.d 不可写，lsp-mode 保存 session 会报错并打断 mode body，
;; 所以把 lsp-session-file 指到工作区，模拟你正常环境（可写）下的行为。
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)
(setq lsp-session-file "d:/home/anson/workspace/my-lean-proj/lean4-check/.lsp-session-v1")
(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

(defvar myv--results nil)
(defun myv--check (name ok &optional detail)
  (push (list name (if ok "PASS" "FAIL") detail) myv--results)
  (princ (format "[%s] %s%s\n" (if ok "PASS" "FAIL") name
                 (if detail (format "  -> %s" detail) ""))))

(defun myv--wait-eglot ()
  (run-hooks 'post-command-hook)
  (let ((end (+ (float-time) 180)))
    (while (and (not (eglot-current-server)) (< (float-time) end))
      (accept-process-output nil 0.2)))
  (eglot-current-server))

(defun myv--info-text ()
  "调用信息面板并把 *Lean Info* 的内容读出来（display-buffer 返回的是 window）。"
  (my/lean-info-at-point)
  (with-current-buffer (get-buffer "*Lean Info*") (buffer-string)))

(princ "== 1. PipeTest.lean：按键与运行 ==\n")
(find-file "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean")
(let ((server (myv--wait-eglot)))
  (myv--check "主模式 lean4-mode" (eq major-mode 'lean4-mode) (format "%s" major-mode))
  (myv--check "C-c C-x → my/lean-run" (eq (key-binding (kbd "C-c C-x")) #'my/lean-run)
              (format "%S" (key-binding (kbd "C-c C-x"))))
  (myv--check "C-c C-l → my/lean-run" (eq (key-binding (kbd "C-c C-l")) #'my/lean-run)
              (format "%S" (key-binding (kbd "C-c C-l"))))
  (myv--check "C-c C-g → my/lean-info-at-point"
              (eq (key-binding (kbd "C-c C-g")) #'my/lean-info-at-point)
              (format "%S" (key-binding (kbd "C-c C-g"))))
  (myv--check "eglot 连上 Lean 服务器" (and server t)
              (format "%S" (and server (ignore-errors (eglot--server-info server)))))
  (let (captured)
    (cl-letf (((symbol-function 'compile) (lambda (c &rest _) (setq captured c))))
      (call-interactively (key-binding (kbd "C-c C-x"))))
    (myv--check "按 C-c C-x 生成 lake env lean <文件>"
                (and captured (string-match-p "\\`lake env lean \"" captured)) captured)
    (with-temp-buffer
      (let ((code (call-process shell-file-name nil t nil shell-command-switch captured)))
        (myv--check "C-c C-x 真跑：输出含全部 #eval 结果"
                    (and (zerop code)
                         (string-match-p "\\[10, 20, 30, 7, 8\\]" (buffer-string))
                         (string-match-p "\"<512>\"" (buffer-string)))
                    (format "退出码 %s" code))))
    (let (captured2)
      (cl-letf (((symbol-function 'compile) (lambda (c &rest _) (setq captured2 c))))
        (my/lean-run '(4)))
      (myv--check "C-u C-c C-x 生成 --run"
                  (and captured2 (string-match-p "--run" captured2)) captured2)
      (with-temp-buffer
        (let ((code (call-process shell-file-name nil t nil shell-command-switch captured2)))
          (myv--check "带 --run 真跑：打印 hello 2"
                      (and (zerop code) (string-match-p "hello 2" (buffer-string)))
                      (format "退出码 %s" code))))))
  ;; 2. 信息面板（PipeTest 无 by 块 → 类型 + 期望类型）
  (goto-char (point-min))
  (search-forward "IO.println" nil t)
  (let ((text (myv--info-text)))
    (princ (format "\n---- *Lean Info*（PipeTest.lean:18）----\n%s\n" text))
    (myv--check "信息面板给出光标处类型（IO Unit）"
                (and text (string-match-p "IO Unit" text))))

  ;; 3. Proofs.lean 的 by 块里应能看到「证明目标」
  (find-file "d:/home/anson/workspace/my-lean-proj/my-lean-project/MyLeanProject/Proofs.lean")
  (myv--wait-eglot)
  (goto-char (point-min))
  (search-forward "induction n with" nil t)
  (let ((text (myv--info-text)))
    (princ (format "\n---- *Lean Info*（Proofs.lean by 块内）----\n%s\n" text))
    (myv--check "by 块里能看到证明目标（⊢ 0 + n = n）"
                (and text (string-match-p "证明目标" text) (string-match-p "⊢" text)))))

(let* ((rs (reverse myv--results))
       (fails (seq-filter (lambda (r) (equal "FAIL" (cadr r))) rs)))
  (princ (format "\n==== %d/%d 通过 ====\n" (- (length rs) (length fails)) (length rs)))
  (dolist (f fails) (princ (format "FAIL: %s %s\n" (car f) (or (caddr f) ""))))
  (kill-emacs (if fails 1 0)))
