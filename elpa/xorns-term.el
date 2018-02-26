;;; xorns-term --- Terminal support

;; Copyright (c) Merchise Autrement [~º/~]

;; Author: Medardo Rodriguez <med@merchise.org>
;; URL: http://dev.merchise.org/emacs/xorns-term
;; Keywords: initialization, merchise, convenience
;; Version: 20150516.1620

;; This file is NOT part of GNU Emacs but I'd like it. ;)

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>
;; or type `C-h C-c' in Emacs.

;;; Commentary:

;; Configure use of `ansi-term' with a system shell or a python shell.
;; Define the key\-binding `C-c t' to launch the terminal shell.
;;
;; This module is automatically used when::
;;
;;     (require 'xorns)

;; Enjoy!


;;; Code:

(require 'term nil 'noerror)
(require 'xorns-utils nil 'noerror)


(defgroup xorns-term nil
   "Running `xorns' shell from within Emacs buffers."
   :prefix "xorns-term-"
   :group 'xorns
   :group 'shell)


(setenv "PATH" (concat (getenv "PATH") ":" (expand-file-name "~/.local/bin")))

;; eshell-load-hook
;; (eshell/addpath "/home/med/.local/bin")


(defun -is-valid-command (widget)
  "Check if the command WIDGET value is valid."
  (let ((value (widget-value widget)))
    (unless (or (null value) (executable-find value))
      (widget-put widget :error (format "Invalid executable: '%s'" value))
      widget)))


(defcustom xorns-term-shells nil
  "Shell definition list to be managed by `xorns-ansi-term'.

Shells configuration to manage ansi\-terminal\-emulators.  The value is an
`alist' of the form `((IDENTIFIER . DEFINITION) ...)'.

IDENTIFIER is used to select the shell kind (for example, with a prefix
argument).  The semantic of `0' is reserved for system shell.

DEFINITION can either be a list with: the COMMAND to execute when creating a
new terminal\-emulator, for example `/bin/bash'; initial buffer NAME;
MAJOR\-MODE preferring the shell; and how to PASTE (send) the selected content
to the shell process.  Or it can be only the COMMAND string.

The buffer name will be formatted using the template \"*IDENTIFIER - NAME*\".

The PASTE method could be *Standard*, to use the content literally; a string
containing '%s', to format the content using the given *template*; any other
string: will yank the content to the clipboard and then send the given value
to the shell process (useful in shells like 'IPython' using '%paste' magic
macro); and a function, to format the content in a custom defined way."
  :type '(repeat
	   (cons
	     (integer :tag "Identifier")
	     (list :tag "Shell definition"
	       (choice :tag "Command"
		 (string :tag "Simple Executable")
		 (cons :tag "Compound"
		   (string :tag "Executable")
		   (string :tag "Arguments")))
	       (string :tag "Name")
	       (repeat :tag "Major modes" symbol)
	       (choice :tag "Paste"
		 (const :tag "Standard" nil)
		 (string :tag "Template")
		 (function :tag "Custom")))))
  :group 'xorns-term)


(defcustom xorns-system-shell nil
  "Preferred system shell command.

Normally, this command is associated with identifier `0' of
`xorns-term-shells' definitions.  See `xorns-system-shell' function."
  :type 'string
  :group 'xorns-term)


(defcustom xorns-python-shell nil
  "Python shell command name.

Preferred python shell command.  The definitive command to execute, is
calculated by the function of equal name."
  :type 'string
  :group 'xorns-term)


(defun xorns-system-shell ()
  "Command to use as system shell.

To calculate the value, test first the custom value of equal name and
if not valid, looks up in a list of alternatives (in order):
environment variables `ESHELL' and `SHELL', custom Emacs variable
`shell-file-name', any of [`bash' `sh' `ksh' `zsh' `tclsh' `csh'
`tcsh']."
  (let ((variants
	  (list
	    (getenv "ESHELL")
	    (getenv "SHELL")
	    (xorns-get-value 'shell-file-name)
	    "bash" "sh" "ksh" "zsh" "tclsh" "csh" "tcsh")))
    (apply 'xorns-executable-find xorns-system-shell variants)))


(defun xorns-python-shell ()
  "Command to use as python shell.

To calculate the value, test first the custom value of equal name and
if not valid, looks up in a list of alternatives (in order):
`ipython', custom Emacs variable `python-command', environment
variable `PYTHON' and custom variables `python-python-command' and
`python-jython-command'."
  (let ((variants
	  (list
	    (xorns-get-value 'python-shell-interpreter)
	    "ipython"
	    "python"
	    (getenv "PYTHON"))))
    (apply 'xorns-executable-find xorns-python-shell variants)))


(defun xorns-python3-shell ()
  "Command to use as python\-3 shell.

In this case there is not a paired custom variable.  To calculate the
value to return, this function tests first two alternatives:
`ipython3' and `python3'.  If none is valid, use the logic for the
python shell defined in function `xorns-python-shell'."
  (let ((py3 (xorns-executable-find "ipython3" "python3")))
    (or py3 (xorns-python-shell))))


(defun xorns-get-ansi-term-shell-name (&optional arg)
  "Get the shell name for a terminal\-emulator.

The meaning of optional argument ARG depends of `major-mode' value.
Non nil means alternative shell, if `major-mode' is not `python-mode'
`base' is a system shell and *alternative* is a python shell;
otherwise the logic is inverted.  If ARG is number `3' (independently
of `major-mode') try to run a `python-3' shell if installed.

The base shell to execute is defined in the custom variable
`xorns-base-shell'; if it is nil, use the function
`xorns-default-shell'.

The python shell to execute is defined in the custom variable
`xorns-python-shell'; if it is nil, use the function
`xorns-default-python-shell'."
  (let*
    ((in-python (eq major-mode 'python-mode))
     (shell
       (cond
	 ((null arg) (if in-python 'Python 'System))
	 ((= (prefix-numeric-value arg) 3) 'Python-3)
	 ((if in-python 'System 'Python)))))
  shell))


;;;###autoload
(defun xorns-ansi-term (&optional arg)
  "Start a terminal\-emulator in a new buffer.

The meaning of optional argument ARG is explained in
`xorns-get-ansi-term-shell-name' function.

Return the buffer hosting the shell."
  (interactive "P")
  (let*
    ((shell (xorns-get-ansi-term-shell-name arg))
     (cmd
       (cond
	 ((eq shell 'System) (xorns-system-shell))
	 ((eq shell 'Python)  (xorns-python-shell))
	 ((xorns-python3-shell))))
      (buf-name (format "%s Shell" shell))
      (starred (format "*%s*" buf-name))
      (cur-buf (get-buffer starred))
      (cur-proc (get-buffer-process cur-buf)))
    (if cur-buf
      (if cur-proc
	(progn
	  (setq cmd nil)
	  (switch-to-buffer cur-buf))
	;else
	(message ">>> Killing buffer: %s" starred)
	(kill-buffer cur-buf)))
    (if cmd
      (progn
	(message ">>> Opening: %s" starred)
	(ansi-term cmd buf-name))
      ;else
      cur-buf)))


;; (defsubst ibuffer-get-region-and-prefix ()
;;   (let ((arg (prefix-numeric-value current-prefix-arg)))
;;     (if (use-region-p) (list (region-beginning) (region-end) arg)
;;       (list nil nil arg))))




;;;###autoload
(defun xorns-toggle-term-mode ()
  "Toggle term-mode between \"term-line-mode\" and \"term-char-mode\"."
  (interactive)
  (if (term-in-char-mode)
    (term-line-mode)
    ;else
    (term-char-mode)))


(global-set-key (kbd "C-c t") 'xorns-ansi-term)

(add-hook 'term-mode-hook
  (lambda ()
    (condition-case err
      (progn
	(define-key term-mode-map (kbd "C-c C-t") 'xorns-toggle-term-mode)
	(define-key term-raw-map (kbd "C-c C-t") 'xorns-toggle-term-mode)

        )
      (error (message "error@term-mode-hook: %s" err)))))


(provide 'xorns-term)
;;; xorns-term.el ends here
