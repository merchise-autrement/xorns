;;; xorns-base.el --- Xorns Configuration for Base System

;; Copyright (c) Merchise Autrement [~º/~]

;; Author: Medardo Antonio Rodriguez <med@merchise.org>

;; This file is not part of GNU Emacs.

;;; Commentary:

;; It's installed just by calling `(require 'xorns-packages)' in the
;; initialization process, which is done automatically.
;;
;; Pending tasks:
;; - See alternatives for `make-backup-files' in:
;;   - https://www.emacswiki.org/emacs/Auto Save
;;   - https://www.emacswiki.org/emacs/BackupFiles

;;; Code:

(require 'use-package)
(require 'use-package-chords)
(require 'xorns-tools)



;; Configuration variables

(defvar >>=|user-mail-address-template nil
  "Template to set `user-mail-address'.
If non-nil must be a string to use `substitute-env-vars' function (t is
converted to \"${USER}@merchise.org\").  The value of EMAIL environment
variable is the best way to configure this leaving this value unchanged as
nil).")


(defvar >>=|base/extra-packages '()
  "List of optional base packages to install.
There is a fix list (window files), that are always configured by default.
Here is the full list (autorevert recentf gcmh).")


(defvar >>=|make-backup-files nil
  "Non-nil means make a backup of a file the first time it is saved.
In this package, the default value is nil (negating taht used in Emacs
`make-backup-files').  In case to use a non-nil value to this variable, a
minimum configuration is done, but you may like to review some extra variables
to configure for yourself: see `save-buffer' function for more information.")


(defmacro >>=-base/configure? (pkg)
  "True if extra PKG must be configured."
  `(memq ',pkg >>=|base/extra-packages))



;; Default base packages (always configured)

(use-package startup
  :defer
  :custom
  (inhibit-startup-screen t)
  (initial-scratch-message nil)
  ; (inhibit-startup-echo-area-message (or (getenv "USER") ""))
  :init
  (progn
    ;; Replace `yes|not' commands for simpler `[yn]'
    (defalias 'yes-or-no-p 'y-or-n-p)
    ; TODO: Move this to another place
    (when >>=|user-mail-address-template
      (if (eq >>=|user-mail-address-template t)
	(setq >>=|user-mail-address-template "${USER}@merchise.org"))
      (setq user-mail-address
	(substitute-env-vars >>=|user-mail-address-template)))))


(use-package window
  :preface (provide 'window)
  :custom
  (split-width-threshold 120)
  :chords
  ("xk" . kill-buffer-and-window))


(use-package files
  :bind (("C-c f /" . revert-buffer)
	 ("C-c f n" . normal-mode))
  :hook
  (before-save . delete-trailing-whitespace)
  :custom
  (require-final-newline t)
  :config
  (if >>=|make-backup-files
    (setq
      make-backup-files t
      backup-by-copying t
      backup-directory-alist
	`((".*" . ,(expand-file-name ".backups" user-emacs-directory)))
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 0    ; check this
      version-control t)
    ; else
    (setq make-backup-files nil)))


(use-package frame
  :when window-system
  :config
  (progn
    ; Kill `suspend-frame' and start Emacs maximized
    (global-unset-key (kbd "C-z"))
    (global-unset-key (kbd "C-x C-z"))
    (set-frame-parameter nil 'undecorated t)
    (add-to-list 'default-frame-alist '(undecorated . t))
    (unless (frame-parameter nil 'fullscreen)
      (toggle-frame-maximized))
    ; TODO: Check if both are needed
    (let ((no-border '(internal-border-width . 0))
	  (full-screen '(fullscreen . maximized)))
      (add-to-list 'default-frame-alist no-border)
      (add-to-list 'initial-frame-alist no-border)
      (add-to-list 'default-frame-alist full-screen)
      (add-to-list 'initial-frame-alist full-screen))))


(use-package windmove
  :custom
  (windmove-wrap-around t)
  :config
  (windmove-default-keybindings 'ctrl))


(use-package xt-mouse
  :unless window-system
  :config
  (progn
    ; Enable mouse support when running in a console
    (require 'mouse)
    (xterm-mouse-mode t)
    (global-set-key [mouse-4]
      (lambda () (interactive) (scroll-down 1)))
    (global-set-key [mouse-5]
      (lambda () (interactive) (scroll-up 1)))))


(use-package elec-pair
  :demand t
  :config
  (electric-pair-mode t))    ; TODO: Check `custom-set-variables' for user


(use-package ido
  :bind ("C-x b" . ido-switch-buffer)
  :custom
  (ido-auto-merge-work-directories-length -1)
  (ido-enable-flex-matching t)
  :init
  (ido-mode 1))


(use-package mwheel
  :custom
  ;; Use the trackpade to scroll the buffer horizontally
  (mouse-wheel-flip-direction t)
  (mouse-wheel-tilt-scroll t))


;; Fix dead characters
;; https://wiki.archlinux.org/index.php/Emacs#Dead-accent_keys_problem:_.27.3Cdead-acute.3E_is_undefined.27
(use-package iso-transl
  :demand t
  :config
  (define-key key-translation-map (kbd "M-[") 'iso-transl-ctl-x-8-map))


;; browse UNIX manual pages
(use-package man
  :defer t
  :custom
  (Man-notify-method 'aggressive))


(use-package autorevert
  :when (>>=-base/configure? autorevert)
  :init
  (defun >>=-auto-revert? ()
    (unless (>>=current-buffer-remote?)
      (auto-revert-mode)))
  :defer t
  :diminish (auto-revert-mode . " ⟲")
  :custom
  (auto-revert-verbose nil)
  (auto-revert-check-vc-info nil)
  :hook
  (find-file . >>=-auto-revert?)
  (dired-mode . auto-revert-mode))


(use-package recentf
  :when (>>=-base/configure? recentf)
  :defer 0.1
  :custom
  (recentf-auto-cleanup 30)
  :config
  (run-with-idle-timer 30 t 'recentf-save-list))


(use-package gcmh
  :when (>>=-base/configure? gcmh)
  :ensure t
  :commands gcmh-mode
  :diminish " ♻"
  :config
  (gcmh-mode 1))


(provide 'xorns-base)
;;; xorns-base.el ends here