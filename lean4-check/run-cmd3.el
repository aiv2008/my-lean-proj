;;; run-cmd3.el --- 验证「版本无关」的 my/lean-run 片段 -*- lexical-binding: t; -*-
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)
(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

;; ── 待验证的片段（就是准备交给用户的代码）────────────────────────────────
(defun my/lean-run (&optional arg)
  "用 PATH 里的 lake 跑当前 .lean 文件；C-u 前缀则加 --run 执行 main。
不依赖 lean4-rootdir，所以 WinGet 装的 elan 也能用；工具链由 lean-toolchain 决定。"
  (interactive "P")
  (let* ((file (or buffer-file-name (user-error "当前 buffer 没有关联文件")))
         (root (or (and (fboundp 'lean4-lake-find-dir) (lean4-lake-find-dir))
                   (file-name-directory file)))
         (extra (if arg "--run " ""))
         (cmd (format "lake env lean %s%s" extra (shell-quote-argument file))))
    (let ((default-directory (file-name-as-directory root)))
      (compile cmd))))
;; ───────────────────────────────────────────────────────────────────────────

(princ "== my/lean-run 验证 ==\n")
(let ((buf (find-file-noselect "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean"))
      (captured nil))
  (with-current-buffer buf
    (cl-letf (((symbol-function 'compile) (lambda (c &rest _) (setq captured c))))
      (call-interactively #'my/lean-run)          ; 无前缀
      (princ (format "无前缀 -> %s\n" captured))
      (let ((c1 captured))
        (call-interactively (lambda () (interactive) (my/lean-run '(4)))))
      (princ (format "C-u    -> %s\n" captured))
      ;; 真跑这两条
      (dolist (c (list (format "lake env lean %s" (shell-quote-argument buffer-file-name))
                       (format "lake env lean --run %s" (shell-quote-argument buffer-file-name))))
        (with-temp-buffer
          (let ((default-directory (file-name-as-directory (lean4-lake-find-dir)))
                (code (progn (message "") 0)))
            (setq code (call-process shell-file-name nil t nil shell-command-switch c))
            (princ (format "\n$ %s\n退出码 %S\n%s\n" c code (string-trim (buffer-string))))))))))
(kill-emacs 0)
