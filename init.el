;;; init.el --- Xorns version of user’s initialization file

;;; Commentary:
;;
;; The file that starts all our own way to Emacs

;;; Code:

;; Without this comment emacs25 adds (package-initialize) here
;; (package-initialize)

(require 'package)

(when (version< emacs-version "27")
  (package-initialize))


;; Improve startup time by temporarily increment these values to prevent
;; garbage collection from running.  They are reset after initialization is
;; finished in `xorns-gc' module (if this is not done it can produce freezes
;; or stuttering).
(defvar >>-file-name-handler-alist file-name-handler-alist
  "Original value of `file-name-handler-alist' variable.")

(setq
  gc-cons-threshold #x40000000    ; 1 GB
  gc-cons-percentage 0.6
  file-name-handler-alist nil)

(add-hook
  'emacs-startup-hook
  (defun >>-gc/configure ()
    "Restore original strategy for GC and variables for startup improvement."
    (setq file-name-handler-alist >>-file-name-handler-alist)
    (makunbound '>>-file-name-handler-alist)
    (require 'xorns-gc)))


(defconst >>=!base-dir
  (concat
    (if load-file-name
      (file-name-directory load-file-name)
      ;; else
      default-directory))
  "Base `xorns' directory.")


(defconst >>=!init-mode/package
  (let ((pkg-info (assq 'xorns package-alist)))
    (if pkg-info
      (expand-file-name
	(package-desc-full-name (cadr pkg-info))
	package-user-dir)))
  "Non-nil if `xorns' is initialized in ELPA (installed package) mode.")


(defconst >>=!init-mode/standalone
  (if (not >>=!init-mode/package)
    (expand-file-name "horns" >>=!base-dir))
  "Non-nil if `xorns' is initialized in standalone mode.")


(defconst >>=!library-directory
  (or >>=!init-mode/package >>=!init-mode/standalone)
  "Directory containing `xorns' library (valid in both modes).")


(load (expand-file-name "xorns.lock" >>=!base-dir) nil (not init-file-debug))


(if >>=!init-mode/standalone
  (add-to-list 'load-path >>=!init-mode/standalone))


(require 'xorns)


(provide 'init)
;;; init.el ends here
