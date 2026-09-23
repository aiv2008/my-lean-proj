;;; run-cmd2.el --- 在「你的真实 init.el」环境下验证 Lean 的几种运行方式 -*- lexical-binding: t; -*-
;; 只读取/执行，不修改任何配置。
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)
(princ "== 加载你的 init.el ==\n")
(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

(defvar mycheck--proj "d:/home/anson/workspace/my-lean-proj/my-lean-project/")
(defvar mycheck--file (concat mycheck--proj "PipeTest.lean"))

(defun mycheck--cmd (args)
  "按 lean4-mode 的拼法构造命令行（lake env lean ARGS FILE）。"
  (lean4-compile-string
   (shell-quote-argument (expand-file-name (lean4-get-executable lean4-lake-name)))
   (shell-quote-argument (expand-file-name (lean4-get-executable lean4-executable-name)))
   args
   (shell-quote-argument (expand-file-name mycheck--file))))

(defun mycheck--run (cmd)
  "在 lake 工程根目录执行 CMD，返回 (退出码 . 输出)。"
  (let ((default-directory (file-name-as-directory (lean4-lake-find-dir))))
    (with-temp-buffer
      (let ((code (call-process shell-file-name nil t nil shell-command-switch cmd)))
        (cons code (string-trim (buffer-string)))))))

(princ "\n== 环境 ==\n")
(princ (format "executable-find lean     = %S\n" (executable-find "lean")))
(princ (format "executable-find lake     = %S\n" (executable-find "lake")))
(princ (format "lean4-rootdir（自动推导） = %S\n" (ignore-errors (lean4-get-rootdir))))
(princ (format "lean4-executable-name    = %S\n" lean4-executable-name))
(princ (format "lean4-lake-name          = %S\n" lean4-lake-name))

(let ((buf (find-file-noselect mycheck--file)))
  (with-current-buffer buf
    (princ "\n== buffer ==\n")
    (princ (format "major-mode = %S / eglot = %S\n" major-mode (and (eglot-current-server) t)))
    (princ (format "C-c C-x -> %S ；C-c C-g -> %S\n"
                   (key-binding (kbd "C-c C-x")) (key-binding (kbd "C-c C-g"))))
    (princ (format "lake 工程根 = %S\n" (lean4-lake-find-dir)))

    (princ "\n== 1) 官方 C-c C-x（当前环境）==\n")
    (princ (format "lean4-get-executable 结果: %s\n"
                   (or (condition-case e
                           (progn (lean4-get-executable lean4-executable-name) nil)
                         (error (error-message-string e)))
                       "OK")))

    (princ "\n== 2) 把 lean4-rootdir 指到项目锁定的 v4.31.0 toolchain ==\n")
    (setq lean4-rootdir "C:/Users/anson/.elan/toolchains/leanprover--lean4---v4.31.0/")
    (let* ((cmd (mycheck--cmd ""))
           (res (mycheck--run cmd)))
      (princ (format "命令 = %s\n" cmd))
      (princ (format "实跑退出码 = %S\n输出:\n%s\n" (car res) (cdr res)))
      (let* ((cmd2 (mycheck--cmd "--run"))
             (res2 (mycheck--run cmd2)))
        (princ (format "带 --run 的命令 = %s\n" cmd2))
        (princ (format "实跑退出码 = %S\n输出末行: %s\n" (car res2)
                       (car (last (split-string (cdr res2) "\n")))))))

    (princ "\n== 3) lean4-toggle-info-buffer（你绑的 C-c C-g）==\n")
    (princ (format "结果: %s\n"
                   (condition-case e (progn (lean4-toggle-info-buffer) "没报错")
                     (error (format "报错: %s" (error-message-string e))))))))
(kill-emacs 0)
