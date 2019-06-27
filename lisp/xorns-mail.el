;;; xorns-mail --- Merchise extensions for sending and receiving mail

;; Copyright (c) Merchise Autrement [~º/~]

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

;; This file is NOT part of GNU Emacs but I'd like it. ;)

;;; Commentary:

;; Extends standard Emacs modules `smtpmail.el' (simple SMTP protocol for
;; sending mail) and `pop3.el' (Post Office Protocol interface for receiving
;; mails).

;; This module is not automatically used when require plain `xorns',
;; to use it::
;;
;;     (require 'xorns-extra)

;; Enjoy!


;;; Code:


;; Requires, auto-loads and declarations

(eval-when-compile
  (require 'cl))

(require 'sendmail)
(require 'smtpmail)
(require 'message)

(require 'cl-lib)
(require 'string-utils)

(require 'xorns-utils)
(require 'xorns-widgets)

;; TODO: Use 'xorns-set-value' and 'xorns-set-values' instead 'setq'


;; Local definitions

(setq
  mail-default-directory "~/mail/"
  message-directory "~/mail/"
  )

(defgroup xorns-email nil
  "Xorns Email"
  :prefix "xorns-email-"
  :group 'xorns)


(defcustom xorns-email-smtp-accounts nil
  "Several SMTP accounts."
  :group 'xorns-email
  :risky t
  :type '(repeat xorns-smtp-account-line))


(defcustom xorns-email-debug nil
  "Set to t for adding debuging messages to SMTP."
  :group 'xorns-email
  :risky t
  :type 'boolean)


(defun xorns-get-from-address ()
  "Return the from address (without quoted name) in a message buffer."
  (save-excursion
    (mail-strip-quoted-names
      (save-restriction
        (message-narrow-to-headers)
        (message-fetch-field "from")))))


(defun xorns-select-appropriate-smtp-server ()
  "Choose the SMTP account according to the current message's from line."
  (let* ((from (xorns-get-from-address))
          (account
            (car
              ;; Chooses the first account that matches
              (loop
                for account in xorns-email-smtp-accounts
                for address = (car account)
                for match = (string-match address from)
                if match
                collect account
                until match))
            ))
    account))


(defun xorns-use-appropriate-smtp-server (&optional buffer)
  "Set the appropriate SMTP related variables in the BUFFER.
If BUFFER is not present, use the current buffer."
  (let ((account (xorns-select-appropriate-smtp-server))
         (buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (when account
        ;; TODO: (address login server mech) <- account
        (let* ((address (car account))
                (login (cadr account))
                (server (string-utils-trim-whitespace (caddr account)))
                (stream-type (cadddr account))
                (message-from (split-string (xorns-get-from-address) "@"))
                (email-login (car message-from))
                (email-domain (cadr message-from))
                (user
                  (cond
                    ((eq login 'full-email-address)
                      (concat email-login "@" email-domain))
                    ((eq login 'user-from-email)
                      email-login)
                    (t login)))
                (envelop-address
                  (cond
                    ((eq login 'full-email-address) user)
                    (t nil))))
          (when (equal "" server)
            ;; TODO: find a function for this
            (setq server
              (concat "smtp." email-domain)))
          (message
            "xorns-email: Setting SMTP. Server: '%s'. Login: '%s'. Type: '%s'"
            server user stream-type)
          (setq
            smtpmail-smtp-server server
            smtpmail-smtp-user user
            smtpmail-stream-type stream-type)
          (when envelop-address
            (setq smtpmail-mail-address envelop-address))
          (setq
            smtpmail-smtp-service
            (case stream-type
              ('ssl 465)
              ('starttls 587)
              (otherwise 25)))
          (when xorns-email-debug
            (setq
              smtpmail-debug-info t
              smtpmail-debug-verb t)))))
    (unless account
      (error "No account matches message's from '%s'"
        (xorns-get-from-address)))))


(defun -xorns-use-appropriate-server (recipient smtpmail-text-buffer &optional ask-for-password)
  "Choose the SMTP account from `xorns-smtp-accounts'."
  (xorns-use-appropriate-smtp-server smtpmail-text-buffer))

(advice-add 'smtpmail-via-smtp :before #'-xorns-use-appropriate-server)



;;; Integration with Gnus reply

(require 'gnus nil)
(require 'gnus-sum nil)

(spam-initialize)


(defun -xorns-gnus-summary-reply (reply-func &rest args)
  "Change the From message header to one of the recipients of the message
that's being replied.

This function is prepared to advice the `gnus-summary-reply' function.  The
REPLY-FUNC is expected to behave as such.  The ARGS contain the arguments to
the original REPLY-FUNC."
  (let* ((article (gnus-summary-article-number))
          (header (gnus-summary-article-header article))
          (rcpt (assoc 'To (mail-header-extra header))))
    (apply reply-func args)
    (save-excursion
      (save-restriction
        (message-narrow-to-headers-or-head)
        (goto-char (point-min))
        ;; Remove the "From: " header
        (delete-matching-lines "^From: "))
      ;; And put it back using the To address... TODO: When the original email
      ;; was sent to several emails, how to get the From from it.
      (message-carefully-insert-headers
        (list (cons 'From (mail-decode-encoded-address-string (cdr rcpt))))))))

(advice-add 'gnus-summary-reply :around #'-xorns-gnus-summary-reply)


(provide 'xorns-mail)
;;; xorns-mail.el ends here