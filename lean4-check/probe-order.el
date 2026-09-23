;;; probe-order.el --- 查清 lean4-mode 初始化时按键被谁覆盖 -*- lexical-binding: t; -*-
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)

(princ "== define-derived-mode 的展开顺序 ==\n")
(princ (pp-to-string (macroexpand-1 '(define-derived-mode foo-x prog-mode "FooX" (foo-body)))))

(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

;; 追一下每次 lean4-set-keys 之后按键是什么
(advice-add 'lean4-set-keys :after
            (lambda (&rest _)
              (princ (format "[lean4-set-keys 之后] buffer=%s local-map=%S C-c C-x=%S C-c C-g=%S\n"
                             (buffer-name) (eq (current-local-map) lean4-mode-map)
                             (lookup-key (current-local-map) (kbd "C-c C-x"))
                             (lookup-key (current-local-map) (kbd "C-c C-g"))))))
;; 追加一个「最后运行」的 hook 观察者
(add-hook 'lean4-mode-hook
          (lambda ()
            (princ (format "[hook 末尾] C-c C-x=%S C-c C-g=%S\n"
                           (lookup-key (current-local-map) (kbd "C-c C-x"))
                           (lookup-key (current-local-map) (kbd "C-c C-g")))))
          'append)

(princ "\n== 打开 PipeTest.lean ==\n")
(find-file "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean")
(princ (format "\n最终：C-c C-x=%S  C-c C-g=%S\n"
               (key-binding (kbd "C-c C-x")) (key-binding (kbd "C-c C-g"))))
(princ (format "lean4-mode-map 对象=%S\n" lean4-mode-map))
(princ (format "prog-mode-map 里的 C-c C-x=%S（若被污染会看到 lean4-std-exe）\n"
               (lookup-key prog-mode-map (kbd "C-c C-x"))))
(kill-emacs 0)
