#| -*-Scheme-*-

$Header: /Users/cph/tmp/foo/mit-scheme/mit-scheme/v7/src/compiler/back/bittop.scm,v 1.5 1987/07/30 21:26:59 jinx Exp $

Copyright (c) 1987 Massachusetts Institute of Technology

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
MIT in each case. |#

;;;; Assembler Top Level

(declare (usual-integrations))

(define *equates*)
(define *objects*)
(define *entry-points*)
(define *linkage-info*)
(define *the-symbol-table*)
(define *start-label*)
(define *end-label*)

;;; Vector header and NMV header for code section

(define compiler-output-block-number-of-header-words 2)

(define starting-pc
  (* compiler-output-block-number-of-header-words scheme-object-width))

;;;; Assembler top level procedure

(define (assemble start-label input linker)
  (with-values
   (lambda ()
     (fluid-let ((*equates* (make-queue))
		 (*objects* (make-queue))
		 (*entry-points* (make-queue))
		 (*linkage-info* (make-queue))
		 (*the-symbol-table* (make-symbol-table))
		 (*start-label* start-label)
		 (*end-label* (generate-uninterned-symbol 'END-LABEL-)))
       (initialize-symbol-table!)
       (with-values
	(lambda ()
	  (initial-phase (instruction-sequence->directives input)))
	(lambda (directives vars)
	  (relax! directives vars)
	  (let ((code-block (final-phase directives)))
	    (values code-block
		    (queue->list *entry-points*)
		    (symbol-table->assq-list *the-symbol-table*)
		    (queue->list *linkage-info*)))))))
   linker))

(define (relax! directives vars)
  (define (tension-message count)
    (newline)
    (display "assemble: Branch tensioning done in ")
    (write (1+ count))
    (if (zero? count)
	(display " iteration.")
	(display " iterations.")))

  (define (loop vars count)
    (finish-symbol-table!)
    (if (null? vars)
	(tension-message count)
	(with-values (lambda () (phase-2 vars))
	 (lambda (any-modified? number-of-vars)
	   (if any-modified?
	       (begin
		 (clear-symbol-table!)
		 (initialize-symbol-table!)
		 (loop (phase-1 directives) (1+ count)))
	       (tension-message count))))))
  (loop vars 0))

;;;; Output block generation

(define (bit-string-insert! b1 b2 position)
  (bit-substring-move-right! b1 0 (bit-string-length b1) b2 position))

(define (final-phase directives)
  ;; Label values are now integers.
  (for-each (lambda (pair)
	      (let ((val (binding-value (cdr pair))))
		(if (interval? val)
		    (set-binding-value! (cdr pair) (interval-low val)))))
	    (symbol-table-bindings *the-symbol-table*))
  (let* ((length (- (* addressing-granularity
		       (symbol-table-value *the-symbol-table* *end-label*))
		    starting-pc))
	 (output-block (bit-string-allocate (+ scheme-object-width length))))
    (bit-string-insert!
     (make-nmv-header (quotient length scheme-object-width))
     output-block
     length)
    (assemble-directives! output-block directives length)))

(define (assemble-objects! block)
  (let ((objects (queue->list *objects*))
	(bl (/ (bit-string-length block) scheme-object-width)))
    (let* ((ol (length objects))
	   (v (make-vector (+ ol bl))))
      (write-bits! v scheme-object-width block)
      (insert-objects! (primitive-set-type (ucode-type compiled-code-block) v)
		       objects bl))))

(define (insert-objects! v objects where)
  (cond ((not (null? objects))
	 (system-vector-set! v where (cadar objects))
	 (insert-objects! v (cdr objects) (1+ where)))
	((not (= where (system-vector-size v)))
	 (error "insert-objects!: object phase error" where))
	(else v)))

(define (assemble-directives! block directives block-length)

  (define (loop directives dir-stack pc pc-stack position last-blabel blabel)

    (define (actual-bits bits l)
      (let ((np (- position l)))
	(bit-string-insert! bits block np)
	(loop (cdr directives) dir-stack (+ pc l) pc-stack np
	      last-blabel blabel)))

    (define (block-offset offset last-blabel blabel)
      (let ((np (- position block-offset-width)))
	(bit-string-insert!
	 (block-offset->bit-string offset (eq? blabel *start-label*))
	 block np)
	(loop (cdr directives) dir-stack
	      (+ pc block-offset-width)
	      pc-stack np
	      last-blabel blabel)))

    (define (evaluation handler expression l)
      (actual-bits (handler
		    (evaluate expression
			      (if (null? pc-stack)
				  (->machine-pc pc)
				  (car pc-stack))))
		   l))

    (cond ((not (null? directives))
	   (let ((this (car directives)))
	     (case (vector-ref this 0)
	       ((LABEL)
		(loop (cdr directives) dir-stack pc pc-stack position
		      last-blabel blabel))
	       ((TICK)
		(loop (cdr directives) dir-stack
		      pc
		      (if (vector-ref this 1)
			  (cons (->machine-pc pc) pc-stack)
			  (cdr pc-stack))
		      position
		      last-blabel blabel))
	       ((FIXED-WIDTH-GROUP)
		(loop (vector-ref this 2) (cons (cdr directives) dir-stack)
		      pc pc-stack
		      position
		      last-blabel blabel))
	       ((CONSTANT)
		(let ((bs (vector-ref this 1)))
		  (actual-bits bs (bit-string-length bs))))
	       ((EVALUATION)
		(evaluation (vector-ref this 3)
			    (vector-ref this 1)
			    (vector-ref this 2)))
	       ((VARIABLE-WIDTH-EXPRESSION)
		(let ((sel (car (vector-ref this 3))))
		  (evaluation (variable-handler-wrapper (selector/handler sel))
			      (vector-ref this 1)
			      (selector/length sel))))
	       ((BLOCK-OFFSET)
		(let* ((label (vector-ref this 1))
		       (offset (evaluate `(- ,label ,blabel) '())))
		  (if (> offset maximum-block-offset)
		      (block-offset (evaluate `(- ,label ,last-blabel) '())
				    label last-blabel)
		      (block-offset offset label blabel))))
	       (else
		(error "assemble-directives!: Unknown directive" this)))))
	  ((not (null? dir-stack))
	   (loop (car dir-stack) (cdr dir-stack) pc pc-stack position
		 last-blabel blabel))
	  ((not (= (+ block-length starting-pc) (+ pc position)))
	   (error "assemble-directives!: phase error"
		  block-length pc position))
	  (else (assemble-objects! block))))
  (loop directives '() starting-pc '() block-length
	*start-label* *start-label*))

;;;; Input conversion

(define (initial-phase input)
  (let ((directives (make-queue)))
    (define (loop to-convert pcmin pcmax pc-stack group vars)
      (define (collect-group!)
	(if (not (null? group))
	    (add-to-queue! directives
			   (vector 'FIXED-WIDTH-GROUP
				   (car group)
				   (reverse! (cdr group))))))

      (define (new-directive! dir)
	(collect-group!)
	(add-to-queue! directives dir))

      (define (process-label! label)
	(symbol-table-define! *the-symbol-table*
			      (cadr label)
			      (make-machine-interval pcmin pcmax))
	(new-directive! (list->vector label)))

      (define (process-fixed-width directive width)
	(loop (cdr to-convert)
	      (+ width pcmin) (+ width pcmax) pc-stack
	      (if (null? group)
		  (cons width (list directive))
		  (cons (+ width (car group))
			(cons directive (cdr group))))
	      vars))

      (define (process-variable-width directive)
	(new-directive! directive)
	(variable-width-lengths directive
	 (lambda (minl maxl)
	   (loop (cdr to-convert)
		 (+ pcmin minl) (+ pcmax maxl)
		 pc-stack '()
		 (cons directive vars)))))

      (define (process-trivial-directive)
	(loop (cdr to-convert)
	      pcmin pcmax pc-stack
	      group vars))

      (if (null? to-convert)
	  (let ((emin (pad pcmin))
		(emax (+ pcmax maximum-padding-length)))
	    (symbol-table-define! *the-symbol-table*
				  *end-label*
				  (make-machine-interval emin emax))
	    (collect-group!)
	    (values (queue->list directives) vars))
	  (let ((this (car to-convert)))
	    (cond ((bit-string? this)
		   (process-fixed-width (vector 'CONSTANT this)
					(bit-string-length this)))
		  ((not (pair? this))
		   (error "initial-phase: Unknown directive" this))
		  (else
		   (case (car this)
		     ((LABEL)
		      (process-label! this)
		      (loop (cdr to-convert) pcmin pcmax pc-stack '() vars))

		     ((CONSTANT)
		      (process-fixed-width (list->vector this)
					   (bit-string-length (cadr this))))

		     ((BLOCK-OFFSET)
		      (process-fixed-width (list->vector this)
					   block-offset-width))

		     ((EVALUATION)
		      (process-fixed-width (list->vector this)
					   (caddr this)))

		     ((VARIABLE-WIDTH-EXPRESSION)
		      (process-variable-width
		       (vector 'VARIABLE-WIDTH-EXPRESSION
			       (cadr this)
			       (if (null? pc-stack)
				   (make-machine-interval pcmin pcmax)
				   (car pc-stack))
			       (map list->vector (cddr this)))))
		     ((GROUP)
		      (new-directive! (vector 'TICK true))
		      (loop (append (cdr this)
				    (cons '(TICK-OFF) (cdr to-convert)))
			    pcmin pcmax
			    (cons (make-machine-interval pcmin pcmax) pc-stack)
			    '() vars))
		     ((TICK-OFF)
		      (new-directive! (vector 'TICK false))
		      (loop (cdr to-convert) pcmin pcmax
			    (cdr pc-stack) '() vars))
		     ((EQUATE)
		      (add-to-queue! *equates* (cdr this))
		      (process-trivial-directive))
		     ((SCHEME-OBJECT)
		      (add-to-queue! *objects* (cdr this))
		      (process-trivial-directive))
		     ((ENTRY-POINT)
		      (add-to-queue! *entry-points* (cadr this))
		      (process-trivial-directive))
		     ((LINKAGE-INFORMATION)
		      (add-to-queue! *linkage-info* (cdr this))
		      (process-trivial-directive))
		     (else
		      (error "initial-phase: Unknown directive" this))))))))
    (loop input starting-pc starting-pc '() '() '())))

(define (phase-1 directives)
  (define (loop rem pcmin pcmax pc-stack vars)
    (if (null? rem)
	(let ((emin (pad pcmin))
	      (emax (+ pcmax maximum-padding-length)))
	  (symbol-table-define! *the-symbol-table*
				*end-label*
				(make-machine-interval emin emax))
	  vars)
	(let ((this (car rem)))
	  (case (vector-ref this 0)
	    ((LABEL)
	     (symbol-table-define! *the-symbol-table*
				   (vector-ref this 1)
				   (make-machine-interval pcmin pcmax))
	     (loop (cdr rem) pcmin pcmax pc-stack vars))
	    ((FIXED-WIDTH-GROUP)
	     (let ((l (vector-ref this 1)))
	       (loop (cdr rem)
		     (+ pcmin l)
		     (+ pcmax l)
		     pc-stack
		     vars)))
	    ((VARIABLE-WIDTH-EXPRESSION)
	     (vector-set! this 2
			  (if (null? pc-stack)
			      (make-machine-interval pcmin pcmax)
			      (car pc-stack)))
	     (variable-width-lengths this
	      (lambda (minl maxl)
		(loop (cdr rem)
		      (+ pcmin minl) (+ pcmax maxl)
		      pc-stack
		      (cons this vars)))))
	    ((TICK)
	     (loop (cdr rem)
		   pcmin pcmax
		   (if (vector-ref this 1)
		       (cons (make-machine-interval pcmin pcmax) pc-stack)
		       (cdr pc-stack))
		   vars))
	    (else
	     (error "phase-1: Unknown directive" this))))))
  (loop directives starting-pc starting-pc '() '()))

(define (phase-2 vars)
  (define (loop vars modified? count)
    (if (null? vars)
	(values modified? count)
	(let ((var (car vars)))
	  (let ((interval (->interval
			   (evaluate (vector-ref var 1)
				     (vector-ref var 2)))))
	    (with-values
	     (lambda ()
	       (process-variable var
				 (interval-low interval)
				 (interval-high interval)))
	     (lambda (determined? filtered?)
	       (loop (cdr vars)
		     (or modified? filtered?)
		     (if determined? count (1+ count)))))))))
  (loop vars false 0))

(define (process-variable var minval maxval)
  (define (loop sels dropped-some?)
    (cond ((null? sels)
	   (error "variable-width-expression: minimum value is too large"
		  var minval))
	  ((not (selector/fits? minval (car sels)))
	   (loop (cdr sels) true))
	  ((selector/fits? maxval (car sels))
	   (variable-width->fixed! var (car sels))
	   (values true dropped-some?))
	  (dropped-some?
	   (vector-set! var 3 sels)
	   (values false true))
	  (else (values false false))))
  (loop (vector-ref var 3) false))

(define (variable-width->fixed! var sel)
  (let* ((l (selector/length sel))
	 (v (vector 'EVALUATION
		    (vector-ref var 1)	; Expression
		    (selector/length sel)
		    (variable-handler-wrapper (selector/handler sel)))))
    (vector-set! var 0 'FIXED-WIDTH-GROUP)
    (vector-set! var 1 l)
    (vector-set! var 2 (list v))
    (vector-set! var 3 '())))

(define (variable-handler-wrapper handler)
  (lambda (value)
    (let ((l (handler value)))
      (if (null? l)
	  (bit-string-allocate 0)
	  (list->bit-string l)))))

(define (list->bit-string l)
  (if (null? (cdr l))
      (car l)
      (bit-string-append (list->bit-string (cdr l))
			 (car l))))