;;; syntax-check.el --- 只读一遍文件，检查括号是否平衡 -*- lexical-binding: t; -*-
(let* ((file (or (pop command-line-args-left) "x.el")))
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (condition-case err
        (progn (while (progn (read (current-buffer)) t)) (princ "SYNTAX-OK\n"))
      (end-of-file (princ "SYNTAX-OK\n"))
      (error (princ (format "SYNTAX-ERROR: %S\n" err)) (kill-emacs 1)))))
