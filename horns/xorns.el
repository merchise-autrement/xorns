;;; xorns.el --- Merchise extensions for Emacs

;; Copyright (c) Merchise Autrement [~º/~]
;; URL: https://github.com/merchise/xorns
;; Version: 0.5.9

;;; Commentary:

;; To use `xorns', just require its main module in the user’s initialization
;; file:
;;
;;   (require 'xorns)
;;
;; We advise to use our version of `user-init-file'.

;; Enjoy!


;;; Code:

(require 'xorns-preface)
(require 'xorns-packages)
(require 'use-package)


(let ((emacs-min-version "26.1"))
  (unless (version<= emacs-min-version emacs-version)
    (error "This `xorns' version requires Emacs >='%s'" emacs-min-version)))



;; Configuration Variables

(defconst >>=window-manager
  (or
    (getenv "DESKTOP_SESSION")
    (getenv "XDG_SESSION_DESKTOP")
    (getenv "GDMSESSION")
    (getenv "XDG_CURRENT_DESKTOP"))
  "Name of started Desktop Window Manager.")


(defvar >>=xorns-initialized nil
  "Whether or not Xorns has finished the startup process.
This is set to true when executing `emacs-startup-hook'.")


(defvar >>=|enable-server nil
  "If non-nil, start an Emacs server if one is not already running.")


;; these local variables speed boost during initialization
(let ((gc-cons-threshold 134217728)    ; (* 128 1024 1024)
      (gc-cons-percentage 0.6)
      (file-name-handler-alist nil))
  (require 'xorns-config)
  (>>=progn "UI and display initialization"
    (use-package xorns-ui
      :commands >>=frame-title-init
      :hook
      (after-init . spaceline-xorns-theme)
      :config
      (>>=frame-title-init))
    (use-package xorns-display
      :commands >>=configure-font
      :init
      (>>=configure-font)))
  (->? >>=building-blocks/configuration)
  (>>=progn "base initialization"
    (use-package xorns-base))
  (if (equal >>=window-manager "emacs")
    (>>=progn "start emacs as a window manager"
      (require 'xorns-exwm)))
  (add-hook
    'emacs-startup-hook
    (defun >>=startup-hook ()
      (->? >>=user-code)
      (setq >>=xorns-initialized (emacs-init-time))
      (message ">>= xorns initialized in %s seconds." >>=xorns-initialized)))
  (when >>=|enable-server
    (require 'server)
    (unless (server-running-p)
      (message ">>= starting server...")
      (server-start)))
  (>>=progn "main initialization"
    (use-package xorns-common-systems)
    (use-package xorns-building-blocks)))


(garbage-collect)


(provide 'xorns)
;;; xorns.el ends here
