#| -*-Scheme-*-

$Id: comman.scm,v 1.79 1994/10/25 23:57:52 cph Exp $

Copyright (c) 1986, 1989-94 Massachusetts Institute of Technology

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

NOTE: Parts of this program (Edwin) were created by translation
from corresponding parts of GNU Emacs.  Users should be aware that
the GNU GENERAL PUBLIC LICENSE may apply to these parts.  A copy
of that license should have been included along with this file.
|#

;;;; Commands and Variables

(declare (usual-integrations))

(define-structure (command
		   (constructor %make-command ())
		   (print-procedure
		    (unparser/standard-method 'COMMAND
		      (lambda (state command)
			(unparse-object state (command-name command))))))
  name
  %description
  interactive-specification
  procedure)

(define-integrable (%symbol->string sym)
  (system-pair-car sym))

(define (command-description command)
  (let ((desc (command-%description command)))
    (if (string? desc)
	desc
	(let ((new (->doc-string (%symbol->string (command-name command))
				 desc)))
	  (if new
	      (set-command-%description! command new))
	  new))))

(define (command-name-string command)
  (editor-name/internal->external (symbol->string (command-name command))))

(define (editor-name/internal->external string)
  string)

(define (editor-name/external->internal string)
  string)

(define (make-command name description specification procedure)
  (let* ((sname (symbol->string name))
	 (command
	  (or (string-table-get editor-commands sname)
	      (let ((command (%make-command)))
		(string-table-put! editor-commands sname command)
		command))))
    (set-command-name! command name)
    (set-command-%description! command (doc-string->posn sname description))
    (set-command-interactive-specification! command specification)
    (set-command-procedure! command procedure)
    command))

(define editor-commands
  (make-string-table 500))

(define (name->command name)
  (let ((name (canonicalize-name name)))
    (or (string-table-get editor-commands (symbol->string name))
	(letrec ((command
		  (make-command
		   name
		   "undefined command"
		   '()
		   (lambda ()
		     (editor-error "Undefined command: "
				   (command-name-string command))))))
	  command))))

(define (->command object)
  (if (command? object)
      object
      (name->command object)))

(define (copy-command new-name command)
  (make-command new-name
		(command-%description command)
		(command-interactive-specification command)
		(command-procedure command)))

(define-structure (variable
		   (constructor %make-variable ())
		   (print-procedure
		    (unparser/standard-method 'VARIABLE
		      (lambda (state variable)
			(unparse-object state (variable-name variable))))))
  name
  %description
  %value
  buffer-local?
  initial-value
  %default-value
  assignment-daemons
  value-validity-test
  value-normalization)

(define (variable-description variable)
  (let ((desc (variable-%description variable)))
    (if (string? desc)
	desc
	(let ((new (->doc-string (%symbol->string (variable-name variable))
				 desc)))
	  (if new
	      (set-variable-%description! variable new))
	  new))))

(define-integrable variable-value variable-%value)
(define-integrable variable-default-value variable-%default-value)
(define-integrable define-variable-value-validity-test
  set-variable-value-validity-test!)

(define (variable-name-string variable)
  (editor-name/internal->external (symbol->string (variable-name variable))))

(define (make-variable name description value buffer-local?)
  (let* ((sname (symbol->string name))
	 (variable
	  (or (string-table-get editor-variables sname)
	      (let ((variable (%make-variable)))
		(string-table-put! editor-variables sname variable)
		variable))))
    (set-variable-name! variable name)
    (set-variable-%description! variable (doc-string->posn sname description))
    (set-variable-%value! variable value)
    (set-variable-buffer-local?! variable buffer-local?)
    (set-variable-initial-value! variable value)
    (set-variable-%default-value! variable value)
    (set-variable-assignment-daemons! variable '())
    (set-variable-value-validity-test! variable #f)
    (set-variable-value-normalization! variable #f)
    variable))

(define-integrable (make-variable-buffer-local! variable)
  (set-variable-buffer-local?! variable #t))

(define (normalize-variable-value variable value)
  (if (and (variable-value-validity-test variable)
	   (not ((variable-value-validity-test variable) value)))
      (editor-error "Invalid value for " (variable-name-string variable)
		    ": " value))
  (if (variable-value-normalization variable)
      ((variable-value-normalization variable) value)
      value))

(define (add-variable-assignment-daemon! variable daemon)
  (let ((daemons (variable-assignment-daemons variable)))
    (if (not (memq daemon daemons))
	(set-variable-assignment-daemons! variable (cons daemon daemons)))))

(define (invoke-variable-assignment-daemons! buffer variable)
  (if within-editor?
      (do ((daemons (variable-assignment-daemons variable) (cdr daemons)))
	  ((null? daemons))
	((car daemons) buffer variable))))

(define editor-variables
  (make-string-table 50))

(define (name->variable name)
  (let ((name (canonicalize-name name)))
    (or (string-table-get editor-variables (symbol->string name))
	(make-variable name "" #f #f))))

(define (->variable object)
  (if (variable? object)
      object
      (name->variable object)))

(define (variable-permanent-local! variable)
  (hash-table/put! permanent-local-variables variable #t))

(define (variable-permanent-local? variable)
  (hash-table/get permanent-local-variables variable #f))

(define permanent-local-variables
  (make-eq-hash-table))