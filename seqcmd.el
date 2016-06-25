;;; seqcmd.el --- Integrated C-a, C-e, M-u, M-l, M-c -*- lexical-binding: t; -*-

;; Author: Yuta Yamada <cokesboy"at"gmail.com>
;; Keywords: convenience, lisp

;;; License:
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package is almost same feature as sequential-command.el, but
;; this package was created to avoid namespace conflict between
;; sequential-command and seq.el.

;; Original version (written by rubikitch):
;;   https://www.emacswiki.org/emacs/sequential-command.el

;;; Code:

(require 'cl-lib)

(defvar seqcmd-store-count 0)
(defvar seqcmd-start-position nil
  "Stores `point' and `window-start' when sequence of calls of the same
 command was started. This variable is updated by `seqcmd-count'")

(defun seqcmd-count ()
  "Returns number of times `this-command' was executed.
It also updates `seqcmd-start-position'."
  (if (eq last-command this-command)
      (cl-incf seqcmd-store-count)
    (setq seqcmd-start-position  (cons (point) (window-start))
          seqcmd-store-count     0)))

(defmacro seqcmd-define-command (name &rest commands)
  "Define a command whose behavior is changed by sequence of calls of the same command."
  (let ((cmdary (apply 'vector commands)))
    `(defun ,name ()
       ,(concat "Sequential command of "
                (mapconcat
                 (lambda (cmd) (format "`%s'" (symbol-name cmd)))
                 commands " and ")
                ".")
       (interactive)
       (call-interactively
        (aref ,cmdary (mod (seqcmd-count) ,(length cmdary)))))))

(defun seqcmd-return ()
  "Return to the position when sequence of calls of the same command was started."
  (interactive)
  (goto-char (car seqcmd-start-position))
  (set-window-start (selected-window) (cdr seqcmd-start-position)))

(seqcmd-define-command seqcmd-home
  beginning-of-line beginning-of-buffer seqcmd-return)
(seqcmd-define-command seqcmd-end
  end-of-line end-of-buffer seqcmd-return)

(defun seqcmd-upcase-backward-word ()
  (interactive)
  (upcase-word (- (1+ (seqcmd-count)))))
(defun seqcmd-capitalize-backward-word ()
  (interactive)
  (capitalize-word (- (1+ (seqcmd-count)))))
(defun seqcmd-downcase-backward-word ()
  (interactive)
  (downcase-word (- (1+ (seqcmd-count)))))

(with-eval-after-load "org"
  (seqcmd-define-command
   seqcmd-org-home org-beginning-of-line beginning-of-buffer seqcmd-return)
  (seqcmd-define-command
   seqcmd-org-end org-end-of-line end-of-buffer seqcmd-return)
  (autoload 'seqcmd-org-home "seqcmd")
  (autoload 'seqcmd-org-end "seqcmd"))

;;;###autoload
(progn
  (autoload 'seqcmd-home "seqcmd")
  (autoload 'seqcmd-end "seqcmd")
  (autoload 'seqcmd-upcase-backward-word "seqcmd")
  (autoload 'seqcmd-capitalize-backward-word "seqcmd")
  (autoload 'seqcmd-downcase-backward-word "seqcmd"))

;;;###autoload
(defun seqcmd-setup-keys ()
  "Rebind C-a, C-e, M-u, M-c, and M-l to seqcmd-* commands.
If you use `org-mode', rebind C-a and C-e."
  (interactive)
  (global-set-key "\C-a" 'seqcmd-home)
  (global-set-key "\C-e" 'seqcmd-end)
  (global-set-key "\M-u" 'seqcmd-upcase-backward-word)
  (global-set-key "\M-c" 'seqcmd-capitalize-backward-word)
  (global-set-key "\M-l" 'seqcmd-downcase-backward-word)
  (with-eval-after-load "org"
    (add-hook 'org-mode-hook
              '(lambda ()
                 (define-key org-mode-map "\C-a" 'seqcmd-org-home)
                 (define-key org-mode-map "\C-e" 'seqcmd-org-end)))))

(provide 'seqcmd)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; seqcmd.el ends here
