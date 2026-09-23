;;; run-cmd.el --- 验证 Emacs 里 C-c C-x 到底会跑什么命令 -*- lexical-binding: t; -*-
;; 只桩掉 compile / read-string，把 lean4-execute 实际拼出的命令行打印出来，不真的执行。
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(dolist (d (directory-files (expand-file-name "elpa" user-emacs-directory) t "^[^.]"))
  (when (file-directory-p d) (add-to-list 'load-path d)))
(add-to-list 'load-path (expand-file-name "lean4-mode" user-emacs-directory))
(require 'lean4-mode nil t)

(defvar mycheck--cmd nil)
(princ (format "lean4-mode 已加载: %S\n" (featurep 'lean4-mode)))

;; 1) 不提示 arg 的情况（模拟非交互调用）
(cl-letf (((symbol-function 'compile) (lambda (cmd &rest _) (setq mycheck--cmd cmd))))
  (let ((default-directory (file-name-as-directory
                            "d:/home/anson/workspace/my-lean-proj/my-lean-project"))
        (buf (find-file-noselect
              "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean")))
    (with-current-buffer buf
      (princ (format "major-mode = %S\n" major-mode))
      (princ (format "C-c C-x 绑定 = %S\n" (key-binding (kbd "C-c C-x"))))
      (princ (format "C-c C-l 绑定 = %S\n" (key-binding (kbd "C-c C-l"))))
      (princ (format "C-c C-g 绑定 = %S\n" (key-binding (kbd "C-c C-g"))))
      (princ (format "lake 工程根 = %S\n" (ignore-errors (lean4-lake-find-dir))))
      ;; 模拟 C-c C-x：call-interactively 会走 read-string 提示分支
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) (princ "[read-string 被调用]\n") "")))
        (call-interactively #'lean4-std-exe))
      (princ (format "拼出的命令 = %s\n" mycheck--cmd))
      ;; 再试一次，arg 传 --run
      (cl-letf (((symbol-function 'read-string) (lambda (&rest _) "--run")))
        (call-interactively #'lean4-std-exe))
      (princ (format "arg=--run 时命令 = %s\n" mycheck--cmd)))))
(kill-emacs 0)
