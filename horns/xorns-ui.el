;;; xorns-ui.el --- Control UI appearance

;; Copyright (c) Merchise Autrement [~º/~]

;; Author: Medardo Antonio Rodriguez <med@merchise.org>

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This library defines several utilities used to configure UI stuffs,
;; specially mode-lines.
;;
;; A common setup for this module is:
;;
;;   (use-package xorns-ui
;;     :hook
;;     (after-init . spaceline-xorns-theme))

;;; Code:

; (require 'easy-mmode)

(require 'use-package)
(require 'spaceline)

(setq-default frame-title-format
  '(multiple-frames "%b"
     ("" invocation-name " -- "
       (:eval (abbreviate-file-name default-directory)))))


(defvar >>=|show-title-in-header-line nil
  "If non-nil, assign `frame-title-format' to `header-line-format'.")


(defvar >>-project-root nil
  "Local variable to store cached `projectile-project-name'.")


(declare-function projectile-project-name 'projectile)

(defun >>-project-root ()
  "Local function to calculate and cache `projectile-project-name'."
  (when (and (not >>-project-root) (fboundp 'projectile-project-name))
    (let ((name (projectile-project-name)))
      (set (make-local-variable '>>-project-root)
	(if (string= name (buffer-name))
	  "-"
	  ;; else
	  name))))
  (unless (string= >>-project-root "-")
    >>-project-root))


(use-package minions
  :demand t
  :config
  (unless minions-mode
    (minions-mode)))


(use-package spaceline-config
  :config
  (progn
    (setq spaceline-highlight-face-func 'spaceline-highlight-face-modified)

    (spaceline-define-segment narrow
      "Show when buffer is narrowed."
      (when (buffer-narrowed-p)
	"Narrowed"))

    (spaceline-define-segment minions
      "A minions menu for minor modes."
      (if (bound-and-true-p minions-mode)
	(format-mode-line minions-mode-line-modes)
	; else
	(spaceline-minor-modes-default)))

    (spaceline-define-segment project-root
      "Show the current project root using projectile."
      (>>-project-root))

    (defun spaceline-xorns-theme ()
      "Install a variation of `spaceline-emacs-theme'."
      (spaceline-install
	`((((persp-name :fallback workspace-number)
	     window-number) :separator "|")
	  ((buffer-modified) :face highlight-face)
	  ((buffer-id which-function)
	    :separator " @ " :face highlight-face :tight-left t)
	  remote-host
	  ;; projectile-root
	  project-root
	  ((buffer-size) :separator " | " :when active)
	  (version-control :when active))
	`(selection-info
	  ((process minions) :when active)
	  ((,(if nil 'buffer-encoding 'buffer-encoding-abbrev)
	    macrodef
	    point-position
	    line-column)
	   :separator " | " :when active)
	   ((narrow buffer-position hud) :face highlight-face)))
      (setq-default
	spaceline-buffer-encoding-abbrev-p t
	mode-line-format '("%e" (:eval (spaceline-ml-main)))))))


(defun >>=ui/toggle-header-mode-line ()
  "Toggle if the header line appears or not."
  (interactive)
  (if (not header-line-format)
      (setq header-line-format
	'(multiple-frames "%b"
	   (" " (:eval (abbreviate-file-name default-directory)))))
    ; else
    (setq header-line-format nil))
  (force-mode-line-update 'all))


(defun >>=frame-title-init ()
  "Configure template for displaying the title bar of visible frames.
See `frame-title-format' variable."
  ;; TODO: Spacemacs uses a function to prepare variable value
  (require 'format-spec)
  ;; TODO: Check (display-graphic-p)
  (when (and >>=|show-title-in-header-line frame-title-format)
    (setq header-line-format frame-title-format)
    ))


(provide 'xorns-ui)
;;; xorns-ui.el ends here
