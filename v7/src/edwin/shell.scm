#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/edwin/shell.scm,v 1.4 1991/05/09 03:25:21 cph Exp $

Copyright (c) 1991 Massachusetts Institute of Technology

This material was developed by the Scheme project at the Massachusetts
Institute of Technology, Department of Electrical Engineering and
Computer Science.  Permission to copy this software, to redistribute
it, and to use it for any purpose is granted, subject to the following
restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. Users of this software agree to make their best efforts (a) to
return to the MIT Scheme project any improvements or extensions that
they make, so that these may be included in future releases; and (b)
to inform MIT of noteworthy uses of this software.

3. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

4. MIT has made no warrantee or representation that the operation of
this software will be error-free, and MIT is under no obligation to
provide any services, by way of maintenance, update, or otherwise.

5. In conjunction with products arising from the use of this material,
there shall be no use of the name of the Massachusetts Institute of
Technology nor of any adaptation thereof in any advertising,
promotional, or sales literature without prior written consent from
MIT in each case.

NOTE: Parts of this program (Edwin) were created by translation from
corresponding parts of GNU Emacs.  Users should be aware that the GNU
GENERAL PUBLIC LICENSE may apply to these parts.  A copy of that
license should have been included along with this file. |#

;;;; Shell subprocess in a buffer
;;; Translated from "cmushell.el", by Olin Shivers.

(declare (usual-integrations))

(define-variable shell-prompt-pattern
  "Regexp to match prompts in the inferior shell."
  "^[^#$>]*[#$>] *")

(define-variable explicit-shell-file-name
  "If not #F, file name to use for explicitly requested inferior shell."
  false)

(define-variable explicit-csh-args
  "Args passed to inferior shell by M-x shell, if the shell is csh.
Value is a list of strings."
  (if (string=? microcode-id/operating-system-variant "HP-UX")
      ;; -T persuades HP's csh not to think it is smarter
      ;; than us about what terminal modes to use.
      '("-i" "-T")
      '("-i")))

(define-major-mode shell comint "Shell"
  "Major mode for interacting with an inferior shell.
Return after the end of the process' output sends the text from the 
    end of process to the end of the current line.
Return before end of process output copies rest of line to end (skipping
    the prompt) and sends it.

If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it.

cd, pushd and popd commands given to the shell are watched to keep
this buffer's default directory the same as the shell's working directory.
\\[shell-resync-dirs] queries the shell and resyncs Edwin's idea of what the
    current directory stack is.
\\[shell-dirtrack-toggle] turns directory tracking on and off.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
shell-mode-hook (in that order).

Variables shell-cd-regexp, shell-pushd-regexp and shell-popd-regexp are used
to match their respective commands."
  (set-variable! comint-prompt-regexp (ref-variable shell-prompt-pattern))
  (set-variable! comint-input-sentinel shell-directory-tracker)
  (local-set-variable! shell-dirstack '())
  (local-set-variable! shell-dirtrack? true)
  (event-distributor/invoke! (ref-variable shell-mode-hook)))

(define-variable shell-mode-hook
  "An event distributor that is invoked when entering Shell mode."
  (make-event-distributor))

(define-key 'shell #\tab 'comint-dynamic-complete)
(define-key 'shell #\M-? 'comint-dynamic-list-completions)

(define-command shell
  "Run an inferior shell, with I/O through buffer *shell*.
If buffer exists but shell process is not running, make new shell.
If buffer exists and shell process is running, just switch to buffer *shell*.

The shell to use comes from the first non-#f variable found from these:
explicit-shell-file-name in Edwin, ESHELL in the environment or SHELL in the
environment.  If none is found, /bin/sh is used.

The buffer is put in Shell mode, giving commands for sending input
and controlling the subjobs of the shell.

The shell file name (sans directories) is used to make a symbol name
such as `explicit-csh-arguments'.  If that symbol is a variable,
its value is used as a list of arguments when invoking the shell.
Otherwise, one argument `-i' is passed to the shell."
  ()
  (lambda ()
    (select-buffer
     (let ((program
	    (or (ref-variable explicit-shell-file-name)
		(get-environment-variable "ESHELL")
		(get-environment-variable "SHELL")
		"/bin/sh")))
       (apply make-comint
	      (ref-mode-object shell)
	      "shell"
	      program
	      (let ((variable
		     (string-table-get editor-variables
				       (string-append "explicit-"
						      (pathname-name-string
						       (->pathname program))
						      "-args"))))
		(if variable
		    (variable-value variable)
		    '("-i"))))))))

(define-variable shell-popd-regexp
  "Regexp to match subshell commands equivalent to popd."
  "popd")

(define-variable shell-pushd-regexp
  "Regexp to match subshell commands equivalent to pushd."
  "pushd")

(define-variable shell-cd-regexp
  "Regexp to match subshell commands equivalent to cd."
  "cd")

(define-variable shell-dirstack-query
  "Command used by shell-resync-dirlist to query shell."
  "dirs")

(define-variable shell-dirstack
  "List of directories saved by pushd in this buffer's shell."
  '())

(define-variable shell-dirtrack? "" false)

(define (shell-directory-tracker string)
  (if (ref-variable shell-dirtrack?)
      (let ((start
	     (re-match-string-forward (re-compile-pattern "^\\s *" false)
				      false
				      (ref-variable syntax-table)
				      string))
	    (end (string-length string)))
	(let ((try
	       (let ((match
		      (lambda (regexp start)
			(re-match-substring-forward
			 (re-compile-pattern regexp false)
			 false
			 (ref-variable syntax-table)
			 string start end))))
		 (lambda (command)
		   (let ((eoc (match command start)))
		     (cond ((not eoc)
			    false)
			   ((match "\\s *\\(\;\\|$\\)" eoc)
			    "")
			   ((match "\\s +\\([^ \t\;]+\\)\\s *\\(\;\\|$\\)" eoc)
			    (substring string
				       (re-match-start-index 1)
				       (re-match-end-index 1)))
			   (else false)))))))
	  (cond ((try (ref-variable shell-cd-regexp))
		 => shell-process-cd)
		((try (ref-variable shell-pushd-regexp))
		 => shell-process-pushd)
		((try (ref-variable shell-popd-regexp))
		 => shell-process-popd))))))

(define (shell-process-popd filename)
  filename
  unspecific)

(define (shell-process-pushd filename)
  filename
  unspecific)

(define (shell-process-cd filename)
  (call-with-current-continuation
   (lambda (continuation)
     (bind-condition-handler (list condition-type:editor-error)
	 (lambda (condition)
	   (apply message (editor-error-strings condition))
	   (continuation unspecific))
       (lambda ()
	 (set-default-directory
	  (if (string-null? filename)
	      (home-directory-pathname)
	      filename))))))
  (shell-dirstack-message))

(define (shell-dirstack-message)
  (apply message
	 (let loop
	     ((dirs
	       (cons (buffer-default-directory (current-buffer))
		     (ref-variable shell-dirstack))))
	   (cons (os/pathname->display-string (->pathname (car dirs)))
		 (if (null? (cdr dirs))
		     '()
		     (cons " " (loop (cdr dirs))))))))

(define-command shell-dirtrack-toggle
  "Turn directory tracking on and off in a shell buffer."
  "P"
  (lambda (argument)
    (set-variable!
     shell-dirtrack?
     (let ((argument (command-argument-value argument)))
       (cond ((not argument) (not (ref-variable shell-dirtrack?)))
	     ((positive? argument) true)
	     ((negative? argument) false)
	     (else (ref-variable shell-dirtrack?)))))
    (message "Directory tracking "
	     (if (ref-variable shell-dirtrack?) "on" "off")
	     ".")))