;; Support for running sbt in inferior mode.

(eval-when-compile (require 'cl))
(require 'tool-bar)
(require 'compile)
(require 'comint)

(defgroup sbt nil
  "Run SBT REPL as inferior of Emacs, parse error messages."
  :group 'tools
  :group 'processes)

(defconst sbt-copyright    "Copyright (C) 2008 Raymond Paul Racine")
(defconst sbt-copyright-2  "Portions Copyright (C) Free Software Foundation")

(defconst sbt-version      "0.03-SNAPSHOT")
(defconst sbt-authors-name  '("Luke Amdor" "Raymond Racine"))
(defconst sbt-authors-email '("luke.amdor@gmail.com" "ray.racine@gamail.com"))

(defconst sbt-legal-notice
  "This is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version.  This is
distributed in the hope that it will be useful, but without any warranty;
without even the implied warranty of merchantability or fitness for a
particular purpose.  See the GNU General Public License for more details.  You
should have received a copy of the GNU General Public License along with Emacs;
see the file `COPYING'.  If not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.")

(defgroup sbt nil
  "Support for sbt build REPL."
  :group  'sbt
  :prefix "sbt-")

(defcustom sbt-program-name "sbt"
  "Program invoked by the `run-sbt' command."
  :type 'string
  :group 'sbt)

(defcustom sbt-build-buffer-name "*Scala Build Tool*"
  "Buffer name for sbt"
  :type 'string :group 'sbt)

(defun sbt ()
  "Launch the sbt shell."
  (interactive)
  (let ((buffer (shell sbt-build-buffer-name)))
    (set (make-local-variable 'compilation-error-regexp-alist)
         '(("^\\[error\\] \\([_.a-zA-Z0-9/-]+[.]scala\\):\\([0-9]+\\):" 1 2 nil 2 nil)))
    (set (make-local-variable 'compilation-mode-font-lock-keywords)
         '(("^\\[error\\] Error running compile:"
            (0 compilation-error-face))
           ("^\\[warn\\][^\n]*"
            (0 compilation-warning-face))
           ("^\\(\\[info\\]\\)\\([^\n]*\\)"
            (0 compilation-info-face)
            (1 compilation-line-face))
           ("^\\[success\\][^\n]*"
            (0 compilation-info-face))))
    (set (make-local-variable 'comint-prompt-read-only) t)
    (set (make-local-variable 'compilation-auto-jump-to-first-error) t)
    (set (make-local-variable 'comint-scroll-to-bottom-on-output) t)
    (compilation-shell-minor-mode t)
    (comint-send-string buffer (concat "cd " (sbt-find-path-to-project) "; sbt\n"))))

(defun sbt-clear ()
  "Clear (erase) the SBT buffer."
  (interactive)
  (with-current-buffer (sbt-build-buffer-name nil)
    (let ((inhibit-read-only t))
      (erase-buffer))))

;; Locate the project root directory from the source buffer location.

(defun sbt-project-dir-p (path)
  "Does a project/build.properties exists in the given path."
  (file-exists-p (concat path "/project/build.properties")))

(defun sbt-at-root (path)
  "Determine if the given path is root."
  (equal path (sbt-parent-path path)))

(defun sbt-parent-path (path)
  "The parent path for the given path."
  (file-truename (concat path "/..")))

;; Search up the directory tree until directory with a "project" subdir
;; is found with build.properties
(defun sbt-find-path-to-project ()
  "Move up the directory tree for the current buffer until root or a directory with a project/build.properities is found."
  (interactive)
  (let ((path default-directory))
    (while (and (not (sbt-project-dir-p path))
                (not (sbt-at-root path)))
      (setf path (file-truename (sbt-parent-path path))))
    path))

(provide 'sbt)