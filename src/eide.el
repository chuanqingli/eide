;;; eide.el --- Emacs-IDE

;; Copyright (C) 2008-2013 Cédric Marie

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(provide 'eide)

(if (featurep 'xemacs)
  (progn
    (read-string "Sorry, XEmacs is not supported by Emacs-IDE, press <ENTER> to exit...")
    (kill-emacs)))

;; Set root directory (expand-file-name replaces ~ with /home/<user>)
(setq eide-root-directory (expand-file-name default-directory))
(setq eide-root-directory-at-startup eide-root-directory)

;; Emacs modules
(require 'desktop)
(require 'hideshow)
(require 'imenu)
(require 'mwheel)
(require 'ediff)

;; Emacs-IDE modules
(require 'eide-compare)
(require 'eide-config)
(require 'eide-edit)
(require 'eide-help)
(require 'eide-keys)
(require 'eide-menu)
(require 'eide-popup)
(require 'eide-project)
(require 'eide-search)
(require 'eide-vc)
(require 'eide-windows)

;; ----------------------------------------------------------------------------
;; INTERNAL FUNCTIONS
;; ----------------------------------------------------------------------------

(defun eide-i-global-settings ()
  "Global settings."
  ;; Do not display startup message
  (setq inhibit-startup-message t)
  ;; Disable warning for large files (especially for TAGS)
  (setq large-file-warning-threshold nil)
  ;; Do not save backup files (~)
  (setq make-backup-files nil)
  ;; Do not save place in .emacs-places
  (setq-default save-place nil)
  ;; No confirmation when refreshing buffer
  (setq revert-without-query '(".*"))
  ;; Use 'y' and 'n' instead of 'yes' and 'no' for minibuffer questions
  (fset 'yes-or-no-p 'y-or-n-p)
  ;; Use mouse wheel (default for Windows but not for Linux)
  (mouse-wheel-mode 1)
  ;; Mouse wheel should scroll the window over which the mouse is
  (setq mouse-wheel-follow-mouse t)
  ;; Set mouse wheel scrolling speed
  (if (equal (safe-length mouse-wheel-scroll-amount) 1)
    ;; Old API
    (setq mouse-wheel-scroll-amount '(4 . 1))
    ;; New API
    (setq mouse-wheel-scroll-amount '(4 ((shift) . 1) ((control)))))
  ;; Disable mouse wheel progressive speed
  (setq mouse-wheel-progressive-speed nil)
  ;; Keep cursor position when moving page up/down
  (setq scroll-preserve-screen-position t)
  ;; Show end of buffer
  ;;(setq-default indicate-empty-lines t)
  ;; "One line at a time" scrolling
  (setq-default scroll-conservatively 1)
  ;; Display line and column numbers
  (setq line-number-mode t)
  (setq column-number-mode t)
  ;; Disable beep
  ;;(setq visible-bell t)
  (setq ring-bell-function (lambda() ()))
  ;; Ignore invisible lines when moving cursor in project configuration
  ;; TODO: not used anymore in project configuration => still necessary?
  (setq line-move-ignore-invisible t)
  ;; Display current function (relating to cursor position) in info line
  ;; (if possible with current major mode)
  (which-function-mode)
  ;; "Warning" color highlight when possible error is detected
  ;;(global-cwarn-mode)
  ;; Do not prompt for updating tag file if necessary
  (setq tags-revert-without-query t)
  ;; Highlight matching parentheses (when cursor on "(" or just after ")")
  (show-paren-mode 1)

  ;; ediff: Highlight current diff only
  ;;(setq ediff-highlight-all-diffs nil)
  ;; ediff: Control panel in the same frame
  (if window-system
    (ediff-toggle-multiframe))
  ;; ediff: Split horizontally for buffer comparison
  (setq ediff-split-window-function 'split-window-horizontally)

  ;; gdb: Use graphical interface
  (setq gdb-many-windows t))

(defun eide-i-add-hooks ()
  "Add hooks for major modes."
  ;; C major mode
  (add-hook
   'c-mode-hook
   '(lambda()
      (if eide-option-select-whole-symbol-flag
        ;; "_" should not be a word delimiter
        (modify-syntax-entry ?_ "w" c-mode-syntax-table))

      ;; Indentation
      (c-set-style "K&R") ; Indentation style
      (if (and eide-custom-override-emacs-settings eide-custom-c-indent-offset)
        (progn
          (setq tab-width eide-custom-c-indent-offset)
          (setq c-basic-offset eide-custom-c-indent-offset)))
      (c-set-offset 'case-label '+) ; Case/default in a switch (default value: 0)

      ;; Turn hide/show mode on
      (if (not hs-minor-mode)
        (hs-minor-mode))
      ;; Do not hide comments when hidding all
      (setq hs-hide-comments-when-hiding-all nil)

      ;; Turn ifdef mode on (does not work very well with ^M turned into empty lines)
      (hide-ifdef-mode 1)

      ;; Pour savoir si du texte est sélectionné ou non
      (setq mark-even-if-inactive nil)))

  ;; C++ major mode
  (add-hook
   'c++-mode-hook
   '(lambda()
      (if eide-option-select-whole-symbol-flag
        ;; "_" should not be a word delimiter
        (modify-syntax-entry ?_ "w" c-mode-syntax-table))

      ;; Indentation
      (c-set-style "K&R") ; Indentation style
      (if (and eide-custom-override-emacs-settings eide-custom-c-indent-offset)
        (progn
          (setq tab-width eide-custom-c-indent-offset)
          (setq c-basic-offset eide-custom-c-indent-offset)))
      (c-set-offset 'case-label '+) ; Case/default in a switch (default value: 0)

      ;; Turn hide/show mode on
      (if (not hs-minor-mode)
        (hs-minor-mode))
      ;; Do not hide comments when hidding all
      (setq hs-hide-comments-when-hiding-all nil)

      ;; Turn ifdef mode on (does not work very well with ^M turned into empty lines)
      (hide-ifdef-mode 1)

      ;; Pour savoir si du texte est sélectionné ou non
      (setq mark-even-if-inactive nil)))

  ;; Shell Script major mode

  ;; Enable colors
  ;;(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
  ;; Shell color mode is disabled because it disturbs shell-command (run
  ;; command), and I have no solution for that!...
  ;; - ansi-term: Does not work correctly ("error in process filter").
  ;; - eshell: Uses specific aliases.
  ;; - ansi-color-for-comint-mode-on: Does not apply to shell-command and
  ;;   disturb it ("Marker does not point anywhere"). Moreover, it is not
  ;;   buffer local (this would partly solve the issue).
  ;; - Using shell for shell-command: previous run command is not killed, even
  ;;   if process and buffer are killed.

  (add-hook
   'sh-mode-hook
   '(lambda()
      (if eide-option-select-whole-symbol-flag
        ;; "_" should not be a word delimiter
        (modify-syntax-entry ?_ "w" sh-mode-syntax-table))
      ;; Indentation
      (if (and eide-custom-override-emacs-settings eide-custom-sh-indent-offset)
        (progn
          (setq tab-width eide-custom-sh-indent-offset)
          (setq sh-basic-offset eide-custom-sh-indent-offset)))))

  ;; Emacs Lisp major mode
  (add-hook
   'emacs-lisp-mode-hook
   '(lambda()
      (if eide-option-select-whole-symbol-flag
        ;; "-" should not be a word delimiter
        (modify-syntax-entry ?- "w" emacs-lisp-mode-syntax-table))

      ;; Indentation
      (if (and eide-custom-override-emacs-settings eide-custom-lisp-indent-offset)
        (progn
          (setq tab-width eide-custom-lisp-indent-offset)
          (setq lisp-body-indent eide-custom-lisp-indent-offset)
          ;; Indentation after "if" (with default behaviour, the "then" statement is
          ;; more indented than the "else" statement)
          (put 'if 'lisp-indent-function 1)))))

  ;; Perl major mode
  (add-hook
   'perl-mode-hook
   '(lambda()
      ;; Indentation
      (if (and eide-custom-override-emacs-settings eide-custom-perl-indent-offset)
        (progn
          (setq tab-width eide-custom-perl-indent-offset)
          (setq perl-indent-level eide-custom-perl-indent-offset)))))

  ;; Python major mode
  (add-hook
   'python-mode-hook
   '(lambda()
      (if eide-option-select-whole-symbol-flag
        ;; "_" should not be a word delimiter
        (modify-syntax-entry ?_ "w" python-mode-syntax-table))

      ;; Indentation
      (if (and eide-custom-override-emacs-settings eide-custom-python-indent-offset)
        (progn
          (setq tab-width eide-custom-python-indent-offset)
          (setq python-indent eide-custom-python-indent-offset))))))

  ;; SGML (HTML, XML...) major mode
  (add-hook
   'sgml-mode-hook
   '(lambda()
      ;; Indentation
      (if (and eide-custom-override-emacs-settings eide-custom-sgml-indent-offset)
        (progn
          (setq tab-width eide-custom-sgml-indent-offset)
          (setq sgml-basic-offset eide-custom-sgml-indent-offset)))))

(defun eide-i-init ()
  "Initialization."
  (if (not (file-directory-p "~/.emacs-ide"))
    (make-directory "~/.emacs-ide"))
  ;; Config must be initialized before desktop is loaded, because it reads some
  ;; variables that might be overridden by local values in buffers.
  (eide-config-init)
  (eide-project-load-root-directory-content t)
  (eide-menu-init)
  (eide-windows-init))

;; ----------------------------------------------------------------------------
;; FUNCTIONS
;; ----------------------------------------------------------------------------

(defun eide-shell-open ()
  "Open a shell."
  (interactive)
  ;; Force to open a new shell (in current directory)
  (if eide-shell-buffer
    (kill-buffer eide-shell-buffer))
  (eide-windows-select-source-window t)
  ;; Shell buffer name will be updated in eide-i-windows-display-buffer-function
  (setq eide-windows-update-output-buffer-id "s")
  (shell))

(defun eide-start ()
  "Start Emacs-IDE."
  (eide-i-global-settings)
  (eide-i-add-hooks)
  (eide-i-init))

;;; eide.el ends here
