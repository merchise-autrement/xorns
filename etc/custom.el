;;; custom.el --- User custom configuration for new age -*- mode: emacs-lisp -*-

;; Copyright (C) Merchise Autrement [~º/~]

;; Author: Medardo Rodriguez <med@merchise.org>

;;; Commentary:
;;
;; This file is a base template to generate the user-specific customization
;; file.  See `>>=user-config/load' function for more information.


;;; Code:

(defun >>=building-blocks/configuration ()
  "Initialization code for building-blocks configuration."
  (setq-default
    ;; It should only modify building-block setting-variables (those prefixed
    ;; with ">>=+") when their default values are not suitable for your
    ;; configuration.  For example:
    ; >>=|base/extra-packages '(autorevert recentf gcmh)
    ))


(defun >>=settings/init ()
  "Initialization code for user-settings customization."
  (setq-default
    ;; Called at the very beginning of the startup process, before building
    ;; blocks configuration.  It should only modify modify setting-variables
    ;; (those prefixed with ">>=|") when their default values are not suitable
    ;; for your configuration.  For example:
    ; >>=|default-font '(:size 12 :weight normal :width normal)
    ; >>=|base/make-backup-files t
    ; >>=|base/user-mail-address-template "${USER}@gmail.com"
    ))


(defun >>=custom/user-init ()
  "User-code as part of initialization process."
  ; This function is called immediately after `>>=settings/init', before
  ; building-blocks configuration.  It''s mostly for variables that should be
  ; set before package-system is loaded.
  )


(defun >>=user-config ()
  "User-code after initialization process."
  )


;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
