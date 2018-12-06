;;; xorns-fci --- Fill Column Indicator

;; Copyright (c) Merchise Autrement [~º/~]

;; Author: Medardo Rodriguez <med@merchise.org>
;; URL: http://dev.merchise.org/emacs/xorns-fci
;; Keywords: initialization, merchise, convenience
;; Version: 20181025.1315

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

;; Generic definitions for editing programming language source code.

;; This module is automatically used when::
;;
;;     (require 'xorns)

;; Enjoy!


;;; Code:


(eval-when-compile
  (require 'use-package nil 'noerror))


(use-package fill-column-indicator
  :defer t
  :ensure t

  :preface

  (defun xorns-fci-mode-on ()
    "Set `fci-mode' on."
    (fci-mode 1))

  (defun xorns-fci-mode-off ()
    "Set `fci-mode' off."
    (fci-mode 0))

  :custom
  (fill-column 78)
  (fci-rule-width 1)
  (fci-rule-color "#CCCCCC")    ;; or "Legislatively"?

  :hook ((text-mode . xorns-fci-mode-on)
	 (prog-mode . xorns-fci-mode-on)
	 (conf-mode . xorns-fci-mode-on))
  )



(provide 'xorns-fci)
;;; xorns-fci.el ends here