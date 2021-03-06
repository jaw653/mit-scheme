#| -*-Scheme-*-

Copyright (c) 1988-1999 Massachusetts Institute of Technology

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
|#

;;;; Miscellaneous Global Definitions
;;; package: ()

(declare (usual-integrations))

;;;; Primitive Operators

(define-primitives
  error-procedure
  set-interrupt-enables! enable-interrupts! with-interrupt-mask
  get-fixed-objects-vector with-history-disabled
  (primitive-procedure-arity 1)
  (primitive-procedure-documentation 1)

  ;; Environment
  lexical-reference lexical-assignment local-assignment
  lexical-unassigned? lexical-unbound? lexical-unreferenceable?

  ;; Pointers
  (object-type 1)
  (object-gc-type 1)
  (object-datum 1)
  (object-type? 2)
  (object-new-type object-set-type 2)
  make-non-pointer-object
  eq?

  ;; Cells
  make-cell cell? cell-contents set-cell-contents!

  ;; System Compound Datatypes
  system-pair-cons system-pair?
  system-pair-car system-pair-set-car!
  system-pair-cdr system-pair-set-cdr!

  hunk3-cons
  system-hunk3-cxr0 system-hunk3-set-cxr0!
  system-hunk3-cxr1 system-hunk3-set-cxr1!
  system-hunk3-cxr2 system-hunk3-set-cxr2!

  (system-list->vector system-list-to-vector)
  (system-subvector->list system-subvector-to-list)
  system-vector?
  (system-vector-length system-vector-size)
  system-vector-ref
  system-vector-set!)

;;;; Potpourri

(define (identity-procedure x) x)
(define (null-procedure . args) args '())
(define (false-procedure . args) args false)
(define (true-procedure . args) args true)

;; This definition is replaced when the 
;; later in the boot sequence.
(define apply (ucode-primitive apply 2))

(define (eval expression environment)
  (extended-scode-eval (syntax expression
			       (environment-syntax-table environment))
		       environment))

(define (scode-eval scode environment)
  (if (compiled-module? scode)
      (compiled-module-eval scode environment)
      (hook/scode-eval scode environment)))

(define hook/scode-eval
  (ucode-primitive scode-eval))

(define-integrable (system-hunk3-cons type cxr0 cxr1 cxr2)
  (object-new-type type (hunk3-cons cxr0 cxr1 cxr2)))

(define (object-component-binder get-component set-component!)
  (lambda (object new-value thunk)
    (let ((old-value))
      (shallow-fluid-bind
       (lambda ()
	 (set! old-value (get-component object))
	 (set-component! object new-value)
	 (set! new-value false)
	 unspecific)
       thunk
       (lambda ()
	 (set! new-value (get-component object))
	 (set-component! object old-value)
	 (set! old-value false)
	 unspecific)))))

(define (bind-cell-contents! cell new-value thunk)
  (let ((old-value))
    (shallow-fluid-bind
     (lambda ()
       (set! old-value (cell-contents cell))
       (set-cell-contents! cell new-value)
       (set! new-value)
       unspecific)
     thunk
     (lambda ()
       (set! new-value (cell-contents cell))
       (set-cell-contents! cell old-value)
       (set! old-value)
       unspecific))))

(define (values . objects)
  (lambda (receiver)
    (apply receiver objects)))

(define (call-with-values thunk receiver)
  ((thunk) receiver))

(define with-values call-with-values)

(define (write-to-string object #!optional max)
  (if (or (default-object? max) (not max))
      (with-output-to-string (lambda () (write object)))
      (with-output-to-truncated-string max (lambda () (write object)))))

(define (pa procedure)
  (cond ((not (procedure? procedure))
	 (error:wrong-type-argument procedure "procedure" 'PA))
	((procedure-lambda procedure)
	 => (lambda (scode)
	      (pp (unsyntax-lambda-list scode))))
	((and (primitive-procedure? procedure)
	      (primitive-procedure-documentation procedure))
	 => (lambda (documentation)
	      (newline)
	      (display documentation)))
	(else
	 (newline)
	 (display "No documentation or debugging info for ")
	 (display procedure)
	 (display "."))))

(define (pwd)
  (working-directory-pathname))

(define (cd #!optional pathname)
  (set-working-directory-pathname!
    (if (default-object? pathname)
        (user-homedir-pathname)
 	pathname)))

#|
;; Compatibility.
(define %pwd pwd)
(define %cd cd)
|#

(define (show-time thunk)
  (with-timings thunk
   (lambda (process-non-gc process-gc real)		
     (newline)
     (write-string "process time: ")
     (write (+ process-non-gc process-gc))
     (write-string " (")
     (write process-non-gc)
     (write-string " RUN + ")
     (write process-gc)
     (write-string " GC); real time: ")
     (write real))))

(define (wait-interval ticks)
  (let ((end (+ (real-time-clock) ticks)))
    (let wait-loop ()
      (if (< (real-time-clock) end)
	  (wait-loop)))))

(define (exit #!optional integer)
  (hook/exit (if (default-object? integer) false integer)))

(define (default/exit integer)
  (if (prompt-for-confirmation "Kill Scheme")
      (%exit integer)))

(define hook/exit default/exit)

(define (%exit #!optional integer)
  (event-distributor/invoke! event:before-exit)
  (if (or (default-object? integer)
	  (not integer))
      ((ucode-primitive exit 0))
      ((ucode-primitive exit-with-value 1) integer)))

(define (quit)
  (hook/quit))

(define (%quit)
  (with-absolutely-no-interrupts (ucode-primitive halt))
  unspecific)

(define default/quit %quit)
(define hook/quit default/quit)

(define syntaxer/default-environment
  (let () (the-environment)))

(define user-initial-environment
  (let () (the-environment)))

(define user-initial-prompt
  "]=>")

(define (environment-link-name to from name)
  ((ucode-primitive environment-link-name)
   (->environment to)
   (->environment from)
   name))

(define-integrable (object-non-pointer? object)
  (zero? (object-gc-type object)))

(define-integrable (object-pointer? object)
  (not (object-non-pointer? object)))

(define (impurify object)
  (if (and (object-pointer? object) (object-pure? object))
      ((ucode-primitive primitive-impurify) object))
  object)

(define (fasdump object filename
		 #!optional suppress-messages? dump-option)
  (let* ((filename (->namestring (merge-pathnames filename)))
	 (do-it
	  (lambda (start-message end-message)
	    (start-message)
	    (let loop ()
	      (if ((ucode-primitive primitive-fasdump)
		   object filename
		   (if (default-object? dump-option)
		       false
		       dump-option))
		  (end-message)
		  (begin
		    (with-simple-restart 'RETRY "Try again."
		      (lambda ()
			(error "FASDUMP: Object is too large to be dumped:"
			       object)))
		    (loop))))))
	 (no-print (lambda () unspecific)))
    (if (or (default-object? suppress-messages?)
	    (not suppress-messages?))
	(let ((port (notification-output-port)))
	  (do-it (lambda ()
		   (fresh-line port)
		   (write-string ";Dumping " port)
		   (write (enough-namestring filename) port))
		 (lambda ()
		   (write-string " -- done" port))))
	(do-it no-print no-print))))

(define (undefined-value? object)
  ;; Note: the unparser takes advantage of the fact that objects
  ;; satisfying this predicate also satisfy:
  ;; (object-type? (microcode-type 'CONSTANT) object)
  (or (eq? object undefined-conditional-branch)
      ;; same as `undefined-conditional-branch'.
      ;; (eq? object *the-non-printing-object*)
      ;; (eq? object unspecific)
      (eq? object (microcode-object/unassigned))))

(define unspecific
  (object-new-type (ucode-type constant) #x3800000))

(define *the-non-printing-object*
  unspecific)

(define (obarray->list #!optional obarray)
  (let ((obarray
	 (if (default-object? obarray)
	     (fixed-objects-item 'OBARRAY)
	     obarray)))
    (let per-bucket
	((index (fix:- (vector-length obarray) 1))
	 (accumulator '()))
      (if (fix:< index 0)
	  accumulator
	  (let per-symbol
	      ((bucket (vector-ref obarray index))
	       (accumulator accumulator))
	    (if (null? bucket)
		(per-bucket (fix:- index 1) accumulator)
		(per-symbol (cdr bucket) (cons (car bucket) accumulator))))))))