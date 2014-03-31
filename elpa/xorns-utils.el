;;; xorns-utils --- Common manipulation utility functions

;; Copyright (C) 2014 Merchise Autrement

;; Author: Medardo Rodriguez <med@merchise.org>
;; URL: http://dev.merchise.org/emacs/xorns-utils
;; Keywords: merchise, utilities, convenience
;; Version: 20140324.1457

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

;; Extensions functions that can be used in a plain Emacs (with no ELPA
;; extensions installed).  All mode specific functions must be placed
;; in the specific `xorns' sub-module.

;; Enjoy!


;;; Code:


(eval-when-compile
  (require 'cl))

;; TODO: How to auto-load other stuff but functions.

;;;###autoload
(defgroup xorns nil
  "Merchise extensions for Emacs."
  :prefix "xorns-"
  :group 'extensions
  :group 'convenience)



;;; Symbols and variables

;;;###autoload
(defun xorns-get-value (symbol)
  "Return SYMBOL's value or  nil if that is void."
  (if (boundp symbol)
    (symbol-value symbol)))



;;; Strings

;;;###autoload
(defun xorns-str-trim (s)
  "Remove white-spaces at start and end of the string S."
  (let ((blanks split-string-default-separators))
    (replace-regexp-in-string
      (format "\\`%s\\|%s\\'" blanks blanks) "" s)))



;;; Files

(defconst xorns-home-dir
  (purecopy (file-name-as-directory "~"))
  "Home directory.")


(defconst xorns-directory-separator
  (eval-when-compile
    (purecopy
      (char-to-string (elt (file-name-as-directory "x") 1))))
  "Director separator.")


;;;###autoload
(defun xorns-path-join (base &rest args)
  "Join BASE and ARGS to a single path.
The empty string or nil could be used as BASE in order to define root
directory.  At the end make the returned value to have the final separator."
  (let ((res base))
    (if (or (null res) (equal res ""))
      (setq res xorns-directory-separator))
    (mapc
      (lambda (arg)
	(setq res (concat (file-name-as-directory res) (or arg ""))))
      args)
    res))


;;;###autoload
(defun xorns-prefered-default-directory ()
  "Return name of preferred default directory when start a new session."
  (file-name-as-directory
    (cl-some
      (lambda (dir) (if (and dir (file-directory-p dir)) dir))
      (list
	(getenv "WORKSPACE")
	(xorns-path-join "~" "work" "merchise")
	(xorns-path-join "~" "work")
	(xorns-path-join "~" "src" "merchise")
	(xorns-path-join "~" "src")
	"~"))))


;;;###autoload
(defun xorns-executable-find (command &rest other-commands)
  "Search for COMMAND in `exec-path' and return the absolute file name.

If COMMAND is not found, looks for alternatives given in OTHER-COMMANDS.

This function is safe avoiding nil commands.  If none is found, nil
is returned."
  (cl-some
    #'(lambda (cmd) (if cmd (executable-find cmd)))
    (push command other-commands)))


;;;###autoload
(defun xorns-default-directory ()
  "Name of default directory of current buffer.

This functions assures that the result always ends with slash and it is
in abbreviated format.  To interactively change the default directory,
use command `cd'."
  (file-name-as-directory (abbreviate-file-name default-directory)))


;;;###autoload
(defun xorns-pwd (&optional no-show)
    "Show and put in the kill ring the current directory.

If optional argument NO-SHOW is not nil, the message is not shown.  The
format for the message is: The first position is used as `<0>' for the
first time this command is executed for each directory, and `<+>' when
repeated; next is printed `$' for an ordinary user or `#' for `root';
then a space and the value of `default-directory'."
    (interactive "P")
    (let* ((pwd (xorns-default-directory))
	   (last (if kill-ring (car kill-ring)))
	   (new (not (equal last pwd)))
	   (sudo (equal user-real-login-name "root"))
	   (prompt (format "%s%s" (if new "<0>" "<+>") (if sudo "#" "$"))))
      (if new
	(kill-new pwd))
      (unless no-show
	(message "%s %s" prompt pwd))))


;; TODO: This code must be removed when every body uses Emacs >= 24.3
(unless (eval-when-compile (functionp 'file-name-base))
  (defun file-name-base (&optional filename)
     "Return the base name of the FILENAME: no directory, no extension.
FILENAME defaults to `buffer-file-name'."
     (file-name-sans-extension
	(file-name-nondirectory (or filename (buffer-file-name))))))



;;; Configuration levels

(defun xorns-get-config-level (arg &optional strict)
  "Transform argument ARG in a valid configuration level.

Value semantics for ARG when STRICT is true are::
- `0' or `\'basic': execute configurations defined as basic.
- `1' or `\'general': execute general configurations (including `basic').
- `2' or `\'maximum': execute all specific configurations.

If STRICT is nil::
- not configured or nil: don't execute specific configurations.
- any other value is synonym of `'maximum'."
  (let ((res
	  (when arg
	    (let ((options
		    '((maximum . 2) (2 . 2)
		      (general . 1) (1 . 1)
		      (basic . 0)   (0 . 0)))
		   (default '(t . t)))
	      (cdr (or (assq arg options) default))))))
    (if strict
      (if (not (or (null res) (eq res t)))
	res
	;else
	(error "Invalid argument `%s' in strict mode!" arg))
      ;else
      (if (eq res t) 2 res))))


;;;###autoload
(defun xorns-configure-p (&optional arg)
  "Return if a configuration level could be executed.

Optional argument ARG specifies the level to match with the value of
`xorns-config-level' variable; if nil `maximum' is assumed.

Variable `xorns-config-level' only must be defined in the scope of
initialization process (See README file and documentation of
`xorns-get-config-level' function)."
  (let ((conf
	  (xorns-get-config-level
	    (if (boundp 'xorns-config-level)
	      (symbol-value 'xorns-config-level))))
	(level (xorns-get-config-level arg 'strict)))
    (if conf (<= level conf))))



;;; Features

;;;###autoload
(defun xorns-missing-feature (feature)
  "Report a message about a missing recommended FEATURE."
  (message "Recommended feature `%s' is not installed." feature))


(provide 'xorns-utils)
;;; xorns-utils.el ends here
