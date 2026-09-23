;;; probe-keys.el --- 为什么 lean4-mode-hook 里的按键没生效 + eglot 能否取 goal -*- lexical-binding: t; -*-
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)
(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

(find-file "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean")
(run-hooks 'post-command-hook)

(princ (format "major-mode = %S\n" major-mode))
(princ (format "lean4-mode-hook 内容 = %S\n" lean4-mode-hook))
(princ (format "current-local-map 是 lean4-mode-map？ %S\n" (eq (current-local-map) lean4-mode-map)))
(princ (format "current-local-map 是 prog-mode-map？ %S\n" (eq (current-local-map) prog-mode-map)))
(princ (format "lookup-key(current-local-map, C-c C-x) = %S\n"
               (lookup-key (current-local-map) (kbd "C-c C-x"))))
(princ (format "key-binding(C-c C-x) = %S\n" (key-binding (kbd "C-c C-x"))))
(princ (format "key-binding(C-c C-g) = %S\n" (key-binding (kbd "C-c C-g"))))

(princ "\n-- 手动再跑一次 lean4-mode-hook 之后 --\n")
(run-hooks 'lean4-mode-hook)
(princ (format "key-binding(C-c C-x) = %S\n" (key-binding (kbd "C-c C-x"))))
(princ (format "key-binding(C-c C-g) = %S\n" (key-binding (kbd "C-c C-g"))))
(princ (format "lookup-key(lean4-mode-map, C-c C-x) = %S\n"
               (lookup-key lean4-mode-map (kbd "C-c C-x"))))

;; eglot 能不能拿到 Lean 的 proof goal（$/lean/plainGoal）
(princ "\n-- eglot + lake serve 的 $/lean/plainGoal --\n")
(let ((server (eglot-current-server)))
  (princ (format "eglot server = %S\n" (and server t)))
  (when server
    (goto-char (point-min))
    (search-forward "def greet" nil t)
    (let* ((params (eglot--TextDocumentPositionParams))
           (res (condition-case e
                    (eglot--request server "$/lean/plainGoal" params :timeout 30)
                  (error (format "报错: %s" (error-message-string e))))))
      (princ (format "返回 = %S\n" res)))))
(kill-emacs 0)
