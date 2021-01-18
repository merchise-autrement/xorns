;;; xorns-term.el --- Terminal support  -*- lexical-binding: t -*-

;; Copyright (c) Merchise Autrement [~º/~]

;; This file is NOT part of GNU Emacs but I'd like it. ;)

;;; Commentary:

;; In this module are configured all the features related to terminals, mainly
;; extensions to the `ansi-term' emulator.

;; A new terminal can be defined with the macro `>>=define-terminal' using
;; several optional keyword arguments to configure some parameters: the
;; command to execute as a shell, a list of `major-mode' symbols to associate
;; a terminal kind with buffers under these modes.  Example of terminals that
;; have already been defined: `>>=ansi-term' (the default terminal), and
;; `>>=python-term' (for Python modes) defined in the module `xorns-prog'.

;; The function `>>=terminal' orchestrates all terminal kinds based on their
;; associations with major modes.

;; Each terminal kind can trigger several tabs, each one is identified with a
;; zero or positive integer, also nil is used for the default tab.  To select
;; a terminal tab a prefix argument is used.  A negative value is used to
;; execute a paste operation from the current buffer to a target terminal
;; (using the absolute value).  The `universal-argument' (`C-u') is used to
;; paste to the default tab, and `negative-argument' (`C--') for the tab with
;; tab zero.

;; Every time a terminal is triggered, a reference to the current buffer is
;; linked to that tab, executing a command to select an active tab will
;; switch, or paste, to the linked buffer.

;; Customizable 256 colors are configured by default for `term' and
;; `ansi-term', to disable it set `>>=|term/install-customizable-colors'
;; variable to nil.

;; Enjoy!


;;; Code:

(require 'use-package)
(require 'term)
(require 'xorns-tools)
(require 'xorns-core)
(require 'xorns-simple)


;;; Common setup

(defconst >>=!default-shell-file-name
  (purecopy
    (or
      explicit-shell-file-name
      shell-file-name
      (>>=executable-find (getenv "ESHELL") (getenv "SHELL") "bash" "sh")))
  "System default shell file-name.")


(use-package eshell
  :commands (eshell eshell-command)
  :preface
  (progn
    (eval-when-compile
      (require 'em-term)
      (declare-function eshell-cmpl-initialize 'em-cmpl))

    (defun >>-eshell/first-time ()
      "Run the first time `eshell-mode' is entered.a"
      (add-to-list 'eshell-visual-commands "htop"))

    (defun >>-eshell/init ()
      "Initialize eshell."
      (eshell-cmpl-initialize)
      (define-key eshell-mode-map
	(kbd "C-c C-d") 'quit-window)
      (when (bound-and-true-p helm-mode)
	(require 'helm-eshell)
	(define-key eshell-mode-map
	  [remap eshell-pcomplete] 'helm-esh-pcomplete)
	(define-key eshell-mode-map
	  [remap eshell-list-history] 'helm-eshell-history))))
  :custom
  (eshell-history-size 1024)
  (eshell-hist-ignoredups t)
  :hook
  (eshell-first-time-mode . >>-eshell/first-time)
  (eshell-mode . >>-eshell/init)
  :config
  (progn
    (require 'esh-io)
    (require 'em-alias)
    (eshell/alias "l" "ls -lh $1")
    (eshell/alias "ll" "ls -alhF $1")
    (eshell/alias "la" "ls -A $1")))


(use-package comint
  :ensure helm
  :preface
  (defun >>-comint/init ()
    "Initialize comint."
    (when (bound-and-true-p helm-mode)
      (require 'helm-eshell)
      (define-key comint-mode-map
	(kbd "C-c C-l") 'helm-comint-input-ring)
      (define-key comint-mode-map
	(kbd "M-s f") 'helm-comint-prompts-all)))
  :hook
  (comint-mode . >>-comint/init))



;;; ANSI Terminal

(defconst >>-!term/docstring-format
  "Command to manage '%s' terminals.
See `>>=define-terminal' for more information."
  "Documentation format-string to be used with a terminal ID as argument.")


(defvar >>=|term/install-customizable-colors t
  "Add customizable 256 color support to `term' and `ansi-term' .")


(defvar >>=term-modes nil
  "An association-list mapping major modes to default ansi terminals.
See macro `>>=define-terminal' and function `>>=terminal' for more
information.")


(defvar >>-term/state nil
  "From which buffer a terminal was called.")


(defun >>-term/adjust-argument (prefix)
  "Adjust a terminal PREFIX argument.

Convert a terminal command PREFIX argument to a (TAB-INDEX . PASTE) pair.  The
first value will be an integer greater than or equal to zero, or nil for the
default tab.  The second value will be a boolean specifying if the selected
text in the current buffer must be pasted to that terminal shell.

The `universal-argument' \(or `C-u') without any further digits, means paste
to the default tab, identified with nil.  The `negative-argument' \(or `C--')
without any further digits, means paste to tab with index 0."
  (cond
    ((null prefix)
      nil)
    ((consp prefix)
      '(nil . t))
    ((integerp prefix)
      (cons (abs prefix) (< prefix 0)))
    (t
      '(0 . t))))


(defun >>-term/wrap-argument (prefix index)
  "Wrap a terminal PREFIX argument based in an existing INDEX.
See `>>=terminal' and `>>-term/adjust-argument' for more information."
  (cond
    ((null prefix)
      index)
    ((consp prefix)
      (cond
	((null index)
	  prefix)
	((= index 0)
	  '_)
	(t    ; index is a positive integer
	  (* -1 index))))
    (t
      prefix)))


(defun >>-term/adjust-string (string)
  "Adjust a STRING to paste it into a terminal."
  (let ((res (and string (string-trim-right string))))
    (if (and res (not (string-empty-p res)))
      res)))


(defun >>-term/get-mode-tuples (keywords)
  "Get the new ':mode' tuples from KEYWORDS to adjust `>>=term-modes'."
  (let ((fn (plist-get keywords :function-name))
	(modes (plist-get keywords :mode)))
    (if modes
      (let ((new (mapcar (lambda (mode) `(,mode . ,fn)) modes)))
	(append
	  new
	  (delq nil
	    (mapcar
	      (lambda (tuple) (if (not (assq (car tuple) new)) tuple))
	      >>=term-modes)))))))


(defun >>-term/get-paste-text ()
  "Get current buffer focused-text and adjust it for a terminal shell."
  (>>-term/adjust-string (>>=buffer-focused-text)))


(defun >>-term/paster (text)
  "Send TEXT to a selected terminal shell session."
  (term-send-raw-string (concat text "\n")))


(defun >>=term/define-paste-magic (&optional magic)
  "Create a ':paster' adapter like IPython's MAGIC '%paste' command."
  (if (null magic)
    (setq magic "%paste"))
  (lambda (text)
    (when text
      (if (string-match-p "\n" text)
	(progn
	  (kill-new text)
	  (>>-term/paster magic)
	  (current-kill 1))
	;; else
	(>>-term/paster text)))))


(defun >>-term-normalize/:program (value &optional keywords)
  "Adjust VALUE for ':program' using KEYWORDS environment."
  (cond
    ((eq value 'ansi)
      (plist-put keywords :program-id "ansi")
      >>=!default-shell-file-name)
    ((symbolp value)
      (>>-term-normalize/:program (symbol-name value) keywords))
    (t    ; string, or sequence of options
      (let ((pair (>>=find-env-executable "%sSHELL" value)))
	(if pair
	  (progn
	    (plist-put keywords :program-id (car pair))
	    (cdr pair))
	  ;; else
	  (error ">>= invalid ':program' value '%s'" value))))))


(defun >>-term-normalize/:mode (value &optional _keywords)
  "Adjust VALUE for ':mode' keyword."
  (mapcar
    (lambda (mode)
      (if (symbolp mode)
	(or (intern-soft (format "%s-mode" mode)) mode)
	;; else
	(error ">>= invalid ':mode' value '%s', must be a symbol" mode)))
    (>>=cast-list value)))


(defun >>-term-normalize/:paster (value &optional keywords)
  "Adjust ':paster' VALUE using KEYWORDS environment."
  (if (stringp value)
    (>>-term-normalize/:paster
      (>>=term/define-paste-magic value) keywords)
    ;; else
    (or
      (>>=cast-function value)
      (if (consp value)
	(let* ((options (>>=cast-list value))
	       (program (plist-get keywords :program-id))
	       (res (assoc program options 'string-equal)))
	  (if res
	    (>>-term-normalize/:paster (cdr res))
	    #'>>-term/paster))
	;; else
	(error ">>= invalid ':paster' value '%s'" :paster)))))


(defmacro >>=define-terminal (id &optional docstring &rest keywords)
  "Define a command to manage `ansi-term' based terminals.

This macro defines a command to manage shell terminals in two scenarios:
trigger/reuse a shell session, or paste.

ID must be a symbol, it will be used to form the command NAME using
'>>=<ID>-term' format, and for default values of KEYWORDS :program and
:buffer-name.

DOCSTRING is the terminal command documentation.

The following KEYWORDS are meaningful:

:program
	The file-name to be loaded as inferior shell.  The value must be a
	string or a list of choices to find the first valid value.  It
	defaults to the `symbol-name' result of ID.

:program-id
	Virtual value, must not be given as a formal argument.  It storage the
	original value of ':program'.

:mode
	A sequence of one or more symbols representing major modes to be used
	with terminal being defined.  See variable `>>=term-modes' and
	function `>>=terminal'.

:buffer-name
	A string prefix for buffer names, the suffix will be the TAB-INDEX,
	see below.  It defaults to 'terminal' if ID is 'ansi', or '<ID>-term'
	otherwise.

:paster
	A function to paste text into a terminal shell.  When a paste
	operation is invoked using, current buffer selected text is extracted
	with `>>-term/get-paste-text', then use specified function in target
	terminal.  A string can be specified, in which case it is converted to
	a function using `>>=term/define-paste-magic', if a `cons' or an
	assotiation-list is given, ':program-id' will be searched in a `car'
	value, the `cdr' value will be the definitive value.  It defaults to
	`>>-term/paster'.

KEYWORDS are normalized using `>>=plist-normalize', the CLASS will be
'>>-term', and the NAME will be used but replacing '>>-<ID>-term'.

The defined terminal command takes one optional prefix argument.  It is used
to identify both the terminal shell session TAB-INDEX and whether to execute a
paste operation.

The command prefix argument is converted to a \(TAB-INDEX . PASTE) pair using
the function `>>-term/adjust-argument'.  TAB-INDEX is nil, for the default
tab, or any integer greater than or equal to zero.  PASTE specifies if the
selected text in the current buffer must be pasted to the corresponding
terminal shell.

The `universal-argument', or `C-u' without any further digits, means paste to
the default tab, identified with nil.  The `negative-argument' or `C--'
without any further digits, means paste to tab with index 0."
  (declare (doc-string 2) (indent 1) (debug t))
  (unless (symbolp id)
    (error ">>= terminal ID must be a symbol, not %s" (type-of id)))
  (when (and docstring (not (stringp docstring)))
    (setq
      keywords (cons docstring keywords)
      docstring nil))
  (when (null docstring)
    (setq docstring (format >>-!term/docstring-format id)))
  (setq keywords
    (>>=plist-normalize '>>-term (format ">>-%s-term" id) keywords
      ;; defaults
      :id id
      :function-name (intern (format ">>=%s-term" id))
      :buffer-name (if (eq id 'ansi) "terminal" (format "%s-term" id))
      :program id
      :paster #'>>-term/paster))
  (let ((tuples (>>-term/get-mode-tuples keywords))
	(buffer-name (plist-get keywords :buffer-name))
	(fun-name (plist-get keywords :function-name))
	(paster (plist-get keywords :paster)))
    `(progn
       ,(if tuples
	  `(setq >>=term-modes ',tuples))
       (defun ,fun-name (&optional arg)
	 ,docstring
	 (interactive "P")
	 (setq arg (>>-term/adjust-argument arg))
	 (let* ((command ,(plist-get keywords :program))
		(tab-index (car arg))
		(paste (cdr arg))
		(paste-function ',paster)
		(bn-index (if tab-index (format " - %s" tab-index) ""))
		(buf-name (concat ,buffer-name bn-index))
		(source (current-buffer))
		(starred (format "*%s*" buf-name))
		(target (get-buffer starred))
		(process (get-buffer-process target)))
	   (when paste
	     (setq paste (>>-term/get-paste-text)))
	   (when target
	     (if process
	       (setq command nil)
	       ;; else
	       (message
		 ">>= killing '%s' terminal buffer, process was finished."
		 starred)
	       (kill-buffer target)))
	   (when command
	     (save-window-excursion
	       (with-current-buffer (setq target (ansi-term command buf-name))
		 (set (make-local-variable '>>-term/state) '(nil)))))
	   (when (eq target source)
	     ;; reentering terminal to switch to associated buffer
	     (setq
	       ;; saved associated buffer
	       target (car >>-term/state)
	       ;; calculate generic paster after switch to associated buffer
	       paste-function nil)
	     (unless (buffer-live-p target)
	       ;; associated buffer was killed, find a new one
	       (setq target
		 (or
		   (>>=find-buffer
		     :mode (car (rassq ',fun-name >>=term-modes)))
		   (>>=find-buffer
		     :mode (nth 3 >>-term/state))
		   ;; use 'scratch' as default
		   (>>=scratch/get-buffer-create)))))
	   (switch-to-buffer-other-window target)
	   (when >>-term/state
	     (let ((mode (buffer-local-value 'major-mode source)))
	       (setq >>-term/state (list source ',fun-name tab-index mode))))
	   (when paste
	     (unless paste-function
	       (setq paste-function
		 (or
		   (get (nth 1 >>-term/state) :paster)
		   (if (eq major-mode 'term-mode) '>>-term/paster)
		   (unless buffer-read-only 'insert))))
	     (if paste-function
	       (funcall paste-function paste)
	       ;; else
	       (warn
		 (concat
		   ">>= invalid paste, maybe target buffer is read only.\n"
		   "Paste text:\n%s") paste)))
	   target))
       (put ',fun-name :paster ',paster))))


(>>=define-terminal ansi)        ; define `>>=ansi-term'


(defun >>=terminal (&optional arg)
  "Use current mode to choose a terminal created with `>>=define-terminal'.
The interactive argument ARG is used without modification."
  (interactive "P")
  (let (term)
    (if >>-term/state
      (setq
	term (nth 1 >>-term/state)
	arg (>>-term/wrap-argument arg (nth 2 >>-term/state)))
      ;; else
      (setq term (cdr (assq major-mode >>=term-modes))))
    (if term
      (funcall term arg)
      ;; else
      (>>=ansi-term arg))))


(use-package term
  :preface
  (defun >>-term/raw-kill-line ()
    "Kill the rest of the current line in `term-char-mode'."
    (interactive)
    (term-send-raw-string "\C-k")
    (kill-line))
  :bind
  (("C-c t" . >>=ansi-term)
   ("s-M-t" . >>=ansi-term)
   ("s-/" . >>=terminal)
   (:map term-mode-map
     ("C-c C-t" . term-char-mode))
   (:map term-raw-map
     ("C-c C-t" . term-line-mode)
     ("C-y" . term-paste)
     ("C-k" . >>-term/raw-kill-line)))
  :custom
  (term-input-autoexpand t))


(use-package eterm-256color
  :when >>=|term/install-customizable-colors
  :ensure t
  :hook
  (term-mode . eterm-256color-mode))


(provide 'xorns-term)
;;; xorns-term.el ends here
