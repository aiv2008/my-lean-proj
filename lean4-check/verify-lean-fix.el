;;; verify-lean-fix.el --- 验证 init.el 改完后 Lean 的运行按键真的能用 -*- lexical-binding: t; -*-
(setq user-emacs-directory "d:/home/anson/.emacs.d/")
(require 'package)
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(package-initialize)
(condition-case err (load "d:/home/anson/.emacs.d/init.el" nil :nomessage)
  (error (princ (format "init.el 报错: %s\n" (error-message-string err)))))

(defvar myv--results nil)
(defun myv--check (name ok &optional detail)
  (push (list name (if ok "PASS" "FAIL") detail) myv--results)
  (princ (format "[%s] %s%s\n" (if ok "PASS" "FAIL") name
                 (if detail (format "  -> %s" detail) ""))))

(princ "== 打开 PipeTest.lean ==\n")
(find-file "d:/home/anson/workspace/my-lean-proj/my-lean-project/PipeTest.lean")
(run-hooks 'post-command-hook)
(myv--check "主模式是 lean4-mode" (eq major-mode 'lean4-mode) (format "%s" major-mode))
(myv--check "my/lean-run 已定义" (fboundp 'my/lean-run))
(myv--check "C-c C-x → my/lean-run" (eq (key-binding (kbd "C-c C-x")) #'my/lean-run)
            (format "%S" (key-binding (kbd "C-c C-x"))))
(myv--check "C-c C-l → my/lean-run" (eq (key-binding (kbd "C-c C-l")) #'my/lean-run)
            (format "%S" (key-binding (kbd "C-c C-l"))))
(myv--check "C-c C-g → lean4-toggle-info（已修）"
            (eq (key-binding (kbd "C-c C-g")) #'lean4-toggle-info)
            (format "%S" (key-binding (kbd "C-c C-g"))))

;; 抓出 my/lean-run 实际会执行的命令，并真跑一遍
(princ "\n== 实跑 my/lean-run 生成的命令 ==\n")
(let (captured)
  (cl-letf (((symbol-function 'compile) (lambda (c &rest _) (setq captured c))))
    (call-interactively #'my/lean-run)
    (princ (format "无前缀: %s\n" captured))
    (myv--check "无前缀生成 lake env lean <文件>"
                (and captured (string-match-p "\\`lake env lean \"" captured))
                captured)
    (let ((c1 captured))
      (with-temp-buffer
        (let ((code (call-process shell-file-name nil t nil shell-command-switch c1)))
          (princ (format "退出码 %S\n%s\n" code (string-trim (buffer-string))))
          (myv--check "无前缀真跑：输出含全部 #eval 结果"
                      (and (zerop code)
                           (string-match-p "\\[10, 20, 30, 7, 8\\]" (buffer-string))
                           (string-match-p "\"<512>\"" (buffer-string)))
                      (format "退出码 %s" code)))))
    (my/lean-run '(4))
    (princ (format "C-u    : %s\n" captured))
    (myv--check "C-u 生成 --run" (and captured (string-match-p "--run" captured)) captured)
    (let ((c2 captured))
      (with-temp-buffer
        (let ((code (call-process shell-file-name nil t nil shell-command-switch c2)))
          (princ (format "退出码 %S，末行: %s\n" code
                         (car (last (split-string (string-trim (buffer-string)) "\n")))))
          (myv--check "带 --run 真跑：执行了 main（打印 hello 2）"
                      (and (zerop code) (string-match-p "hello 2" (buffer-string)))
                      (format "退出码 %s" code)))))))

;; C-c C-g 修好之后至少不该再报参数错误
(princ "\n== C-c C-g（lean4-toggle-info）==\n")
(myv--check "lean4-toggle-info 调用不报参数错误"
            (condition-case e (progn (lean4-toggle-info) t)
              (error (princ (format "  报错: %s\n" (error-message-string e))) nil)))

(let* ((rs (reverse myv--results))
       (fails (seq-filter (lambda (r) (equal "FAIL" (cadr r))) rs)))
  (princ (format "\n==== %d/%d 通过 ====\n" (- (length rs) (length fails)) (length rs)))
  (dolist (f fails) (princ (format "FAIL: %s %s\n" (car f) (or (caddr f) ""))))
  (kill-emacs (if fails 1 0)))
