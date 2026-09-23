;;; probe-keys2.el --- 把 lsp-session 重定向到工作区后重验按键 + 试 $/lean/plainGoal -*- lexical-binding: t; -*-
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)

;; 关键：批处理里 ~/.emacs.d 不可写，lsp-mode 保存 session 时会报错并打断 mode body；
;; 这里把它指到工作区，模拟你正常环境（可写）下的行为。
(setq lsp-session-file "d:/home/anson/workspace/my-lean-proj/lean4-check/.lsp-session-v1")

(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

(add-hook 'lean4-mode-hook
          (lambda ()
            (princ (format "[hook 末尾] C-c C-x=%S C-c C-g=%S\n"
                           (lookup-key (current-local-map) (kbd "C-c C-x"))
                           (lookup-key (current-local-map) (kbd "C-c C-g")))))
          'append)

(princ "== 打开 PipeTest.lean ==\n")
(find-file "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean")
(princ (format "最终：C-c C-x=%S  C-c C-l=%S  C-c C-g=%S  C-c C-i=%S\n"
               (key-binding (kbd "C-c C-x")) (key-binding (kbd "C-c C-l"))
               (key-binding (kbd "C-c C-g")) (key-binding (kbd "C-c C-i"))))

(run-hooks 'post-command-hook)
(let ((end (+ (float-time) 120)))
  (while (and (not (eglot-current-server)) (< (float-time) end))
    (accept-process-output nil 0.2)))
(let ((server (eglot-current-server)))
  (princ (format "\neglot = %S\n" (and server t)))
  (when server
    ;; 1) 证明 my/lean-run 的按键是真的能用
    (let (captured)
      (cl-letf (((symbol-function 'compile) (lambda (c &rest _) (setq captured c))))
        (call-interactively (key-binding (kbd "C-c C-x"))))
      (princ (format "按 C-c C-x 实际执行 = %s\n" captured)))
    ;; 2) 光标放在 greet 的函数体里，试 Lean 的 proof goal 请求
    (goto-char (point-min))
    (search-forward "IO.println" nil t)
    (dolist (method '("$/lean/plainGoal" "$/lean/plainTermGoal"))
      (let ((res (condition-case e
                     (eglot--request server method (eglot--TextDocumentPositionParams) :timeout 30)
                   (error (format "报错: %s" (error-message-string e))))))
        (princ (format "%s => %S\n" method res))))
    ;; 3) 对比：hover 拿得到什么
    (princ (format "hover => %S\n"
                   (condition-case e
                       (eglot--request server :textDocument/hover
                                       (eglot--TextDocumentPositionParams) :timeout 30)
                     (error (format "报错: %s" (error-message-string e))))))))
(kill-emacs 0)
