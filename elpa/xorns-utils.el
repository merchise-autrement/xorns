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



;;; Strings

;;;###autoload
(defun xorns-str-trim (s)
  "Remove white-spaces at start and end of the string S."
  (let ((blanks split-string-default-separators))
    (replace-regexp-in-string
      (format "\\`%s\\|%s\\'" blanks blanks) "" s)))



;;; Files


(defconst xorns-home-dir
  (eval-when-compile
    (purecopy (file-name-as-directory "~")))
  "Home directory.")


;;;###autoload
(defun xorns-path-join (base &rest args)
  "Join BASE and ARGS to a single path."
  (let* ((path base)
	 (relative (not (file-name-absolute-p base))))
    (dolist (arg args path)
      (setq path (expand-file-name arg path)))
    (abbreviate-file-name (if relative (file-relative-name path) path))))


(defconst xorns-merchise-prefered-directory
  (eval-when-compile
    (purecopy
      (file-name-as-directory
	(or
	  (let ((env-dir (getenv "WORKSPACE")))
	    (if (and env-dir (file-directory-p env-dir))
	      (file-name-as-directory env-dir)))
	  (let ((pref-dirs
		  (list
		    (xorns-path-join "~" "work" "merchise")
		    (xorns-path-join "~" "work")
		    (xorns-path-join "~" "src" "merchise")
		    (xorns-path-join "~" "src"))))
	    (loop
	      for dir in pref-dirs
	        for res = (if (file-directory-p dir) dir)
	      until res
	      finally return res))
	  "~"))))
  "Name of preferred default directory when start a new session.")


;;;###autoload
(defun xorns-merchise-prefered-directory ()
  "Return name of preferred default directory when start a new session."
  xorns-merchise-prefered-directory)


;;;###autoload
(defun xorns-executable-find (command &rest other-commands)
  "Search for COMMAND in `exec-path' and return the absolute file name.

If COMMAND is not found, looks for alternatives given in OTHER-COMMANDS.

If none is found, nil is returned."
  (or (executable-find command)
    (loop
      for current in other-commands
      for exe = (executable-find current)
      until exe
      finally return exe)))


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
    (interactive)
    (let* ((pwd (xorns-default-directory))
	   (last (if kill-ring (car kill-ring)))
	   (new (not (equal last pwd)))
	   (sudo (equal user-real-login-name "root"))
	   (prompt (format "%s%s" (if new "<0>" "<+>") (if sudo "#" "$"))))
      (if new
	(kill-new pwd))
      (if (not no-show)
	(message "%s %s" prompt pwd))))


;; TODO: This code must be removed when every body uses Emacs >= 24.3
(unless (eval-when-compile (functionp 'file-name-base))
  (defun file-name-base (&optional filename)
     "Return the base name of the FILENAME: no directory, no extension.
FILENAME defaults to `buffer-file-name'."
     (file-name-sans-extension
	(file-name-nondirectory (or filename (buffer-file-name))))))



;;; Features

;;;###autoload
(defun xorns-missing-feature (feature)
  "Report a message about a missing recommended FEATURE."
  (message "Recommended feature `%s' is not installed." feature))


(provide 'xorns-utils)
;;; xorns-utils.el ends here
