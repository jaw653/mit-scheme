#| -*-Scheme-*-

$Id: rules3.scm,v 4.38 1993/02/19 17:48:51 cph Exp $

Copyright (c) 1988-93 Massachusetts Institute of Technology

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

;;;; LAP Generation Rules: Invocations and Entries
;;; package: (compiler lap-syntaxer)

(declare (usual-integrations))

;;;; Invocations

(define-integrable (clear-continuation-type-code)
  (if (= scheme-type-width 8)
      (LAP (CLR B (@A 7)))
      (LAP (AND L ,mask-reference (@A 7)))))

(define-rule statement
  (POP-RETURN)
  (LAP ,@(clear-map!)
       ,@(clear-continuation-type-code)
       (RTS)))

(define-rule statement
  (INVOCATION:APPLY (? frame-size) (? continuation))
  continuation
  (LAP ,@(clear-map!)
       ,@(case frame-size
	   ((1) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-1)))
	   ((2) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-2)))
	   ((3) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-3)))
	   ((4) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-4)))
	   ((5) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-5)))
	   ((6) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-6)))
	   ((7) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-7)))
	   ((8) (LAP (JMP ,entry:compiler-shortcircuit-apply-size-8)))
	   (else
	    (LAP ,@(load-dnl frame-size 2)
		 (JMP ,entry:compiler-shortcircuit-apply))))))

(define-rule statement
  (INVOCATION:JUMP (? frame-size) (? continuation) (? label))
  frame-size continuation
  (LAP ,@(clear-map!)
       (BRA (@PCR ,label))))

(define-rule statement
  (INVOCATION:COMPUTED-JUMP (? frame-size) (? continuation))
  frame-size continuation
  ;; It expects the procedure at the top of the stack
  (LAP ,@(clear-map!)
       ,@(clear-continuation-type-code)
       (RTS)))

(define-rule statement
  (INVOCATION:LEXPR (? number-pushed) (? continuation) (? label))
  continuation
  (LAP ,@(clear-map!)
       ,@(load-dnl number-pushed 2)
       (LEA (@PCR ,label) (A 0))
       (MOV L (A 0) (D 1))
       ,@(invoke-interface code:compiler-lexpr-apply)))

(define-rule statement
  (INVOCATION:COMPUTED-LEXPR (? number-pushed) (? continuation))
  continuation
  ;; It expects the procedure at the top of the stack
  (LAP ,@(clear-map!)
       ,@(load-dnl number-pushed 2)
       ,@(clear-continuation-type-code)
       (MOV L (@A+ 7) (D 1))
       ,@(invoke-interface code:compiler-lexpr-apply)))

(define-rule statement
  (INVOCATION:UUO-LINK (? frame-size) (? continuation) (? name))
  continuation
  (LAP ,@(clear-map!)
       ;; The following assumes that at label there is
       ;;	(JMP (L <entry>))
       ;; The other possibility would be
       ;;       (JMP (@@PCR ,(free-uuo-link-label name frame-size)))
       ;; and to have <entry> at label, but it is longer and slower.
       (BRA (@PCR ,(free-uuo-link-label name frame-size)))))

(define-rule statement
  (INVOCATION:GLOBAL-LINK (? frame-size) (? continuation) (? name))
  continuation
  (LAP ,@(clear-map!)
       ;; The following assumes that at label there is
       ;;	(JMP (L <entry>))
       ;; The other possibility would be
       ;;       (JMP (@@PCR ,(global-uuo-link-label name frame-size)))
       ;; and to have <entry> at label, but it is longer and slower.
       (BRA (@PCR ,(global-uuo-link-label name frame-size)))))

(define-rule statement
  (INVOCATION:CACHE-REFERENCE (? frame-size) (? continuation) (? extension))
  (QUALIFIER (interpreter-call-argument? extension))
  continuation
  (let ((set-extension
	 (interpreter-call-argument->machine-register! extension d1)))
    (delete-dead-registers!)
    (LAP ,@set-extension
	 ,@(clear-map!)
	 ,@(load-dnl frame-size 3)
	 (LEA (@PCR ,*block-label*) (A 1))
	 (MOV L (A 1) (D 2))
	 ,@(invoke-interface code:compiler-cache-reference-apply))))

(define-rule statement
  (INVOCATION:LOOKUP (? frame-size) (? continuation) (? environment) (? name))
  (QUALIFIER (interpreter-call-argument? environment))
  continuation
  (let ((set-environment
	 (interpreter-call-argument->machine-register! environment d1)))
    (delete-dead-registers!)
    (LAP ,@set-environment
	 ,@(clear-map!)
	 ,@(load-constant name (INST-EA (D 2)))
	 ,@(load-dnl frame-size 3)
	 ,@(invoke-interface code:compiler-lookup-apply))))

(define-rule statement
  (INVOCATION:PRIMITIVE (? frame-size) (? continuation) (? primitive))
  continuation
  (LAP ,@(clear-map!)
       ,@(cond ((eq? primitive compiled-error-procedure)
		(LAP ,@(load-dnl frame-size 1)
		     (JMP ,entry:compiler-error)))
	       ((eq? primitive (ucode-primitive set-interrupt-enables! 1))
		(LAP (JMP ,entry:compiler-set-interrupt-enables)))
	       (else
		(let ((arity (primitive-procedure-arity primitive)))
		  (cond ((not (negative? arity))
			 (LAP (MOV L (@PCR ,(constant->label primitive)) (D 1))
			      (JMP ,entry:compiler-primitive-apply)))
			((= arity -1)
			 (LAP (MOV L (& ,(-1+ frame-size))
				   ,reg:lexpr-primitive-arity)
			      (MOV L (@PCR ,(constant->label primitive)) (D 1))
			      (JMP ,entry:compiler-primitive-lexpr-apply)))
			(else
			 ;; Unknown primitive arity.  Go through apply.
			 (LAP ,@(load-dnl frame-size 2)
			      (MOV L (@PCR ,(constant->label primitive)) (D 1))
			      ,@(invoke-interface code:compiler-apply)))))))))

(let-syntax
    ((define-special-primitive-invocation
       (macro (name)
	 `(define-rule statement
	    (INVOCATION:SPECIAL-PRIMITIVE
	     (? frame-size)
	     (? continuation)
	     ,(make-primitive-procedure name true))
	    frame-size continuation
	    (special-primitive-invocation
	     ,(symbol-append 'CODE:COMPILER- name)))))

     (define-optimized-primitive-invocation
       (macro (name)
	 `(define-rule statement
	    (INVOCATION:SPECIAL-PRIMITIVE
	     (? frame-size)
	     (? continuation)
	     ,(make-primitive-procedure name true))
	    frame-size continuation
	    (optimized-primitive-invocation
	     ,(symbol-append 'ENTRY:COMPILER- name))))))

  (define-optimized-primitive-invocation &+)
  (define-optimized-primitive-invocation &-)
  (define-optimized-primitive-invocation &*)
  (define-optimized-primitive-invocation &/)
  (define-optimized-primitive-invocation &=)
  (define-optimized-primitive-invocation &<)
  (define-optimized-primitive-invocation &>)
  (define-optimized-primitive-invocation 1+)
  (define-optimized-primitive-invocation -1+)
  (define-optimized-primitive-invocation zero?)
  (define-optimized-primitive-invocation positive?)
  (define-optimized-primitive-invocation negative?)
  (define-optimized-primitive-invocation quotient)
  (define-optimized-primitive-invocation remainder))

(define (special-primitive-invocation code)
  (LAP ,@(clear-map!)
       ,@(invoke-interface code)))

(define (optimized-primitive-invocation hook)
  (LAP ,@(clear-map!)
       (JMP ,hook)))

;;;; Invocation Prefixes

(define-rule statement
  (INVOCATION-PREFIX:MOVE-FRAME-UP 0 (REGISTER 15))
  (LAP))

(define-rule statement
  (INVOCATION-PREFIX:MOVE-FRAME-UP (? frame-size) (REGISTER 12))
  (let ((temp (allocate-temporary-register! 'ADDRESS)))
    (LAP (MOV L ,(register-reference 12) ,(register-reference temp))
	 ,@(generate/move-frame-up* frame-size temp))))

(define-rule statement
  (INVOCATION-PREFIX:MOVE-FRAME-UP (? frame-size)
				   (OFFSET-ADDRESS (REGISTER 15) (? offset)))
  (let ((how-far (- offset frame-size)))
    (cond ((zero? how-far)
	   (LAP))
	  ((zero? frame-size)
	   (increment-machine-register 15 (* 4 how-far)))
	  ((= frame-size 1)
	   (LAP (MOV L (@A+ 7) ,(offset-reference a7 (-1+ how-far)))
		,@(increment-machine-register 15 (* 4 (-1+ how-far)))))
	  ((= frame-size 2)
	   (if (= how-far 1)
	       (LAP (MOV L (@AO 7 4) (@AO 7 8))
		    (MOV L (@A+ 7) (@A 7)))
	       (let ((i (lambda ()
			  (LAP (MOV L (@A+ 7)
				    ,(offset-reference a7 (-1+ how-far)))))))
		 (LAP ,@(i)
		      ,@(i)
		      ,@(increment-machine-register 15 (* 4 (- how-far 2)))))))
	  (else
	   (generate/move-frame-up frame-size (offset-reference a7 offset))))))

(define-rule statement
  (INVOCATION-PREFIX:MOVE-FRAME-UP (? frame-size)
				   (OFFSET-ADDRESS (REGISTER (? base))
						   (? offset)))
  (generate/move-frame-up frame-size (indirect-reference! base offset)))

(define-rule statement
  (INVOCATION-PREFIX:DYNAMIC-LINK 0 (REGISTER 15) (REGISTER 12))
  (LAP))

(define-rule statement
  (INVOCATION-PREFIX:DYNAMIC-LINK (? frame-size)
				  (OFFSET-ADDRESS (REGISTER (? base))
						  (? offset))
				  (REGISTER 12))
  (let ((label (generate-label))
	(temp (allocate-temporary-register! 'ADDRESS)))
    (let ((temp-ref (register-reference temp)))
      (LAP (LEA ,(indirect-reference! base offset) ,temp-ref)
	   (CMP L ,temp-ref (A 4))
	   (B HS B (@PCR ,label))
	   (MOV L (A 4) ,temp-ref)
	   (LABEL ,label)
	   ,@(generate/move-frame-up* frame-size temp)))))

(define-rule statement
  (INVOCATION-PREFIX:DYNAMIC-LINK (? frame-size)
				  (OBJECT->ADDRESS (REGISTER (? source)))
				  (REGISTER 12))
  (let ((dreg (standard-move-to-temporary! source 'DATA))
	(label (generate-label))
	(temp (allocate-temporary-register! 'ADDRESS)))
    (let ((areg (register-reference temp)))
      (LAP (AND L ,mask-reference ,dreg)
	   (MOV L ,dreg ,areg)
	   (CMP L ,areg (A 4))
	   (B HS B (@PCR ,label))
	   (MOV L (A 4) ,areg)
	   (LABEL ,label)
	   ,@(generate/move-frame-up* frame-size temp)))))

(define-rule statement
  (INVOCATION-PREFIX:DYNAMIC-LINK (? frame-size)
				  (REGISTER (? source))
				  (REGISTER 12))
  (let ((areg (standard-move-to-temporary! source 'ADDRESS))
	(label (generate-label)))
    (LAP (CMP L ,areg (A 4))
	 (B HS B (@PCR ,label))
	 (MOV L (A 4) ,areg)
	 (LABEL ,label)
	 ,@(generate/move-frame-up* frame-size
				    (+ (lap:ea-operand-1 areg) 8)))))

(define (generate/move-frame-up frame-size destination)
  (let ((temp (allocate-temporary-register! 'ADDRESS)))
    (LAP (LEA ,destination ,(register-reference temp))
	 ,@(generate/move-frame-up* frame-size temp))))

(define (generate/move-frame-up* frame-size destination)
  (let ((temp (allocate-temporary-register! 'ADDRESS)))
    (LAP (LEA ,(offset-reference a7 frame-size) ,(register-reference temp))
	 ,@(generate-n-times
	    frame-size 5
	    (lambda ()
	      (LAP (MOV L
			(@-A ,(- temp 8))
			(@-A ,(- destination 8)))))
	    (lambda (generator)
	      (generator (allocate-temporary-register! 'DATA))))
	 (MOV L ,(register-reference destination) (A 7)))))

;;;; External Labels

(define (make-external-label code label)
  (set! *external-labels* (cons label *external-labels*))
  (LAP (DC UW ,code)
       (BLOCK-OFFSET ,label)
       (LABEL ,label)))

;;; Entry point types

(define-integrable (make-code-word min max)
  (+ (* #x100 min) max))

(define (make-procedure-code-word min max)
  ;; The "min" byte must be less than #x80; the "max" byte may not
  ;; equal #x80 but can take on any other value.
  (if (or (negative? min) (>= min #x80))
      (error "MAKE-PROCEDURE-CODE-WORD: minimum out of range" min))
  (if (>= (abs max) #x80)
      (error "MAKE-PROCEDURE-CODE-WORD: maximum out of range" max))
  (make-code-word min (if (negative? max) (+ #x100 max) max)))

(define expression-code-word
  (make-code-word #xff #xff))

(define internal-entry-code-word
  (make-code-word #xff #xfe))

(define internal-continuation-code-word
  (make-code-word #xff #xfc))

(define (frame-size->code-word offset default)
  (cond ((not offset)
	 default)
	((< offset #x2000)
	 ;; This uses up through (#xff #xdf).
	 (let ((qr (integer-divide offset #x80)))
	   (make-code-word (+ #x80 (integer-divide-remainder qr))
			   (+ #x80 (integer-divide-quotient qr)))))
	(else
	 (error "Unable to encode continuation offset" offset))))

(define (continuation-code-word label)
  (frame-size->code-word
   (if label
       (rtl-continuation/next-continuation-offset (label->object label))
       0)
   internal-continuation-code-word))

(define (internal-procedure-code-word rtl-proc)
  (frame-size->code-word
   (rtl-procedure/next-continuation-offset rtl-proc)
   internal-entry-code-word))

;;;; Procedure headers

;;; The following calls MUST appear as the first thing at the entry
;;; point of a procedure.  They assume that the register map is clear
;;; and that no register contains anything of value.
;;;
;;; The only reason that this is true is that no register is live
;;; across calls.  If that were not true, then we would have to save
;;; any such registers on the stack so that they would be GC'ed
;;; appropriately.
;;;
;;; The only exception is the dynamic link register, handled
;;; specially.  Procedures that require a dynamic link use a different
;;; interrupt handler that saves and restores the dynamic link
;;; register.

(define-integrable (simple-procedure-header code-word label entry)
  (let ((gc-label (generate-label)))    
    (LAP (LABEL ,gc-label)
	 (JSR ,entry)
	 ,@(make-external-label code-word label)
	 ,@(interrupt-check label gc-label -12))))

(define (interrupt-check label gc-label gc-label-offset)
  (case (let ((object (label->object label)))
	  (and (rtl-procedure? object)
	       (not (rtl-procedure/stack-leaf? object))
	       compiler:generate-stack-checks?))
    ((#F)
     (LAP (CMP L ,reg:compiled-memtop (A 5))
	  (B GE B (@PCR ,gc-label))))
    ((OUT-OF-LINE)
     (LAP (JSR
	   ,(case gc-label-offset
	      ((-12) entry:compiler-stack-and-interrupt-check-12)
	      ((-14) entry:compiler-stack-and-interrupt-check-14)
	      ((-18) entry:compiler-stack-and-interrupt-check-18)
	      ((-22) entry:compiler-stack-and-interrupt-check-22)
	      ((-24) entry:compiler-stack-and-interrupt-check-24)
	      (else (error "Illegal GC label offset:"
			   gc-label-offset))))))
    (else
     (LAP (CMP L ,reg:compiled-memtop (A 5))
	  (B GE B (@PCR ,gc-label))
	  (CMP L ,reg:stack-guard (A 7))
	  (B LE B (@PCR ,gc-label))))))

(define-rule statement
  (CONTINUATION-ENTRY (? internal-label))
  (make-external-label (continuation-code-word internal-label)
		       internal-label))

(define-rule statement
  (CONTINUATION-HEADER (? internal-label))
  (simple-procedure-header (continuation-code-word internal-label)
			   internal-label
			   entry:compiler-interrupt-continuation))

(define-rule statement
  (IC-PROCEDURE-HEADER (? internal-label))
  (let ((procedure (label->object internal-label)))
    (let ((external-label (rtl-procedure/external-label procedure))
	  (gc-label (generate-label)))
      (LAP (ENTRY-POINT ,external-label)
	   (EQUATE ,external-label ,internal-label)
	   (LABEL ,gc-label)
	   ,@(invoke-interface-jsr code:compiler-interrupt-ic-procedure)
	   ,@(make-external-label expression-code-word internal-label)
	   ,@(interrupt-check internal-label gc-label -14)))))

(define-rule statement
  (OPEN-PROCEDURE-HEADER (? internal-label))
  (let ((rtl-proc (label->object internal-label)))
    (LAP (EQUATE ,(rtl-procedure/external-label rtl-proc) ,internal-label)
	 ,@(simple-procedure-header (internal-procedure-code-word rtl-proc)
				    internal-label
				    (if (rtl-procedure/dynamic-link? rtl-proc)
					entry:compiler-interrupt-dlink
					entry:compiler-interrupt-procedure)))))

(define-rule statement
  (PROCEDURE-HEADER (? internal-label) (? min) (? max))
  (LAP (EQUATE ,(rtl-procedure/external-label
		 (label->object internal-label))
	       ,internal-label)
       ,@(simple-procedure-header (make-procedure-code-word min max)
				  internal-label
				  entry:compiler-interrupt-procedure)))

;;;; Closures:

#|

The closure headers and closure consing code are heavily interdependent.

There are two different versions of the rules, depending on the closure format:

The 68020 format can be used when there is no problem with
inconsistency between the processor's I-cache and the D-cache.  In
this format, closures contain an absolute JSR instruction, stored by
the closure consing code.  The absolute address is the address of the
labelled word in the closure header.  Closures are allocated directly
from the Scheme heap, and the instructions are stored by the
cons-closure code.  Multiple entry-point closures have their entry
points tightly packed, and since the JSR instruction is 6 bytes long,
entries are not, in general at longword boundaries.  Because the rest
of the compiler requires the closure object on the stack to be
longword aligned, these objects always correspond to the first
(canonical) entry point of a closure with multiple entry points.  Thus
there is a little shuffling around to maintain this, and the identity
of the object.

The 68040 format should be used when the D-cache is in copyback mode
(ie. storing to an address may not be seen by the I-cache even if
there was no previous association).  In this format, closures contain
a JSR instruction to a fixed piece of code, and the actual entry point
is stored folling this fixed instruction.  The garbage collector can
change this to an absolute JSR instruction.  Closures are allocated
from a pool, renewed by out of line code that also pre-stores the
instructions and synchronizes the caches.  Entry points are always
long-word aligned and there is no need for shuffling.

|#

(define (MC68020/closure-header internal-label nentries entry)
  nentries				; ignored
  (let ((rtl-proc (label->object internal-label)))
    (let ((gc-label (generate-label))
	  (external-label (rtl-procedure/external-label rtl-proc)))
      (if (zero? nentries)
	  (LAP (EQUATE ,external-label ,internal-label)
	       ,@(simple-procedure-header
		  (internal-procedure-code-word rtl-proc)
		  internal-label
		  entry:compiler-interrupt-procedure))
	  (with-values
	      (lambda ()
		(let ((distance (* 10 entry)))
		  (cond ((zero? distance)
			 (values (LAP)
				 0))
			((< distance 128)
			 (values (LAP (MOVEQ (& ,distance) (D 0))
				      (ADD L (D 0) (@A 7)))
				 4))
			(else
			 (values (LAP (ADD L (& ,distance) (@A 7)))
				 6)))))
	    (lambda (adjustment adjustment-size)
	      (LAP (LABEL ,gc-label)
		   ,@adjustment
		   (JMP ,entry:compiler-interrupt-closure)
		   ,@(make-external-label internal-entry-code-word
					  external-label)
		   (ADD UL (& ,(MC68020/make-magic-closure-constant entry))
			(@A 7))
		   (LABEL ,internal-label)
		   ,@(interrupt-check internal-label
				      gc-label
				      (- -18 adjustment-size)))))))))

(define (MC68020/cons-closure target procedure-label min max size)
  (let* ((target (reference-target-alias! target 'ADDRESS))
	 (temporary (reference-temporary-register! 'ADDRESS)))
    (LAP (LEA (@PCR ,(rtl-procedure/external-label
		      (label->object procedure-label)))
	      ,temporary)
	 ,@(load-non-pointer (ucode-type manifest-closure)
			     (+ 3 size)
			     (INST-EA (@A+ 5)))
	 (MOV UL
	      (& ,(+ (* (make-procedure-code-word min max) #x10000) 8))
	      (@A+ 5))
	 (MOV L (A 5) ,target)
	 (MOV UW (& #x4eb9) (@A+ 5))	; (JSR (L <entry>))
	 (MOV L ,temporary (@A+ 5))
	 (CLR W (@A+ 5))
	 ,@(increment-machine-register 13 (* 4 size)))))

(define (MC68020/cons-multiclosure target nentries size entries)
  (let ((target (reference-target-alias! target 'ADDRESS)))
    (let ((total-size (+ size
			 (quotient (+ 3 (* 5 nentries))
				   2)))
	  (temp1 (reference-temporary-register! 'ADDRESS))
	  (temp2 (reference-temporary-register! 'DATA)))

      (define (generate-entries entries offset first?)
	(if (null? entries)
	    (LAP)
	    (let ((entry (car entries)))
	      (LAP (MOV UL (& ,(+ (* (make-procedure-code-word (cadr entry)
							       (caddr entry))
				     #x10000)
				  offset))
			(@A+ 5))
		   ,@(if first?
			 (LAP (MOV L (A 5) ,target))
			 (LAP))
		   (LEA (@PCR ,(rtl-procedure/external-label
				(label->object (car entry))))
			,temp1)
		   (MOV W ,temp2 (@A+ 5)) ; (JSR (L <entry>))
		   (MOV L ,temp1 (@A+ 5))
		   ,@(generate-entries (cdr entries)
				       (+ 10 offset)
				       false)))))	  

      (LAP ,@(load-non-pointer (ucode-type manifest-closure)
			       total-size
			       (INST-EA (@A+ 5)))
	   (MOV UL (& ,(* nentries #x10000)) (@A+ 5))
	   (MOV UW (& #x4eb9) ,temp2)
	   ,@(generate-entries entries 12 true)
	   ,@(if (odd? nentries)
		 (LAP (CLR W (@A+ 5)))
		 (LAP))
	   ,@(increment-machine-register 13 (* 4 size))))))

(define (MC68020/make-magic-closure-constant entry)
  (- (make-non-pointer-literal (ucode-type compiled-entry) 0)
     (+ (* entry 10) 6)))

(define (MC68040/closure-header internal-label nentries entry)
  nentries entry			; ignored
  (let ((rtl-proc (label->object internal-label)))
    (let ((gc-label (generate-label))
	  (external-label (rtl-procedure/external-label rtl-proc)))
      (if (zero? nentries)
	  (LAP (EQUATE ,external-label ,internal-label)
	       ,@(simple-procedure-header
		  (internal-procedure-code-word rtl-proc)
		  internal-label
		  entry:compiler-interrupt-procedure))
	  (LAP (LABEL ,gc-label)
	       (JMP ,entry:compiler-interrupt-closure)
	       ,@(make-external-label internal-entry-code-word
				      external-label)
	       (ADD UL (& ,(MC68040/make-magic-closure-constant entry)) (@A 7))
	       (LABEL ,internal-label)
	       ,@(interrupt-check internal-label gc-label -18))))))

(define (MC68040/cons-closure target procedure-label min max size)
  (MC68040/with-allocated-closure target 1 size
    (lambda (an)
      (let ((temp (reference-temporary-register! 'ADDRESS)))
	(LAP ,@(load-non-pointer (ucode-type manifest-closure)
				 (+ size MC68040/closure-entry-size)
				 (INST-EA (@A+ ,an)))
	     (MOV UL
		  (& ,(+ (* (make-procedure-code-word min max) #x10000) 8))
		  (@A+ ,an))
	     (LEA (@PCR ,(rtl-procedure/external-label
			  (label->object procedure-label)))
		  ,temp)
	     (MOV L ,temp (@AO ,an 4)))))))

(define (MC68040/cons-multiclosure target nentries size entries)
  (MC68040/with-allocated-closure target nentries size
    (lambda (atarget)
      (let* ((atmp1 (areg->an (allocate-temporary-register! 'ADDRESS)))
	     (atmp2 (areg->an (allocate-temporary-register! 'ADDRESS))))
	(define (store-entries offset entries)
	  (if (null? entries)
	      (LAP)
	      (let ((entry (car entries)))
		(LAP (MOV UL (& ,(+ (* (make-procedure-code-word (cadr entry)
								 (caddr entry))
				       #x10000)
				    offset))
			  (@A+ ,atmp1))
		     (ADDQ L (& 4) (A ,atmp1)) ; bump over JSR instr.
		     (LEA (@PCR ,(rtl-procedure/external-label
				  (label->object (car entry))))
			  (A ,atmp2))
		     (MOV L (A ,atmp2) (@A+ ,atmp1))
		     ,@(store-entries (+ 12 offset) (cdr entries))))))

	(LAP ,@(load-non-pointer (ucode-type manifest-closure)
				 (+ size 1
				    (* nentries MC68040/closure-entry-size))
				 (INST-EA (@A+ ,atarget)))
	     (MOV UL (& ,(* nentries #x10000)) (@A+ ,atarget))
	     (MOV L (A ,atarget) (A ,atmp1))
	     (ADDQ L (& 4) (A ,atarget))
	     ,@(store-entries 12 entries))))))

;;;; Utilities for MC68040 closures.

(define (MC68040/make-magic-closure-constant entry)
  entry					; ignored
  (- (make-non-pointer-literal (ucode-type compiled-entry) 0)
     6))

;; In what follows, entry:compiler-allocate-closure gets its parameter in d0
;; and returns its value in a0.

(define (MC68040/allocate-closure size)
  (LAP ,@(load-dnl size 0)
       (JSR ,entry:compiler-allocate-closure)))

;; If this issues too much code, the optional code can be eliminated at
;; some performace penalty in speed.

(define (MC68040/with-allocated-closure target nentries size recvr)
  (require-register! d0)
  (rtl-target:=machine-register! target a0)
  (let ((total-size (+ 1
		       (if (= nentries 1) 0 1)
		       (* MC68040/closure-entry-size nentries)
		       size))
	(label (generate-label)))
    (LAP
     ;; Optional code:
     (MOV L ,reg:closure-free (A 0))
     ,@(ea+=constant reg:closure-free (* 4 total-size))
     ,@(ea+=constant reg:closure-space (- 0 total-size))
     (B GE B (@PCR ,label))
     ;; End of optional code.
     ,@(MC68040/allocate-closure total-size)
     (LABEL ,label)
     ,@(recvr 0))))

(define (rtl-target:=machine-register! rtl-reg machine-reg)
  (if (machine-register? rtl-reg)
      (begin
	(require-register! machine-reg)
	(if (not (= rtl-reg machine-reg))
	    (suffix-instructions!
	     (register->register-transfer machine-reg rtl-reg))))
      (begin
	(delete-register! rtl-reg)
	(flush-register! machine-reg)
	(add-pseudo-register-alias! rtl-reg machine-reg))))

(define (require-register! machine-reg)
  (flush-register! machine-reg)
  (need-register! machine-reg))

(define-integrable (flush-register! machine-reg)
  (prefix-instructions! (clear-registers! machine-reg)))

(define-integrable (areg->an areg)
  (- areg 8))

;;;; The rules themselves.

(define-rule statement
  (CLOSURE-HEADER (? internal-label) (? nentries) (? entry))
  (generate/closure-header internal-label nentries entry))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (CONS-CLOSURE (ENTRY:PROCEDURE (? procedure-label))
			(? min) (? max) (? size)))
  (generate/cons-closure target procedure-label min max size))

(define-rule statement
  (ASSIGN (REGISTER (? target))
	  (CONS-MULTICLOSURE (? nentries) (? size) (? entries)))
  (case nentries
    ((0)
     (let ((target (reference-target-alias! target 'ADDRESS)))
       (LAP (MOV L (A 5) ,target)
	    ,@(load-non-pointer (ucode-type manifest-vector)
				size
				(INST-EA (@A+ 5)))
	    ,@(increment-machine-register 13 (* 4 size)))))
    ((1)
     (let ((entry (vector-ref entries 0)))
       (generate/cons-closure target
			      (car entry) (cadr entry) (caddr entry)
			      size)))
    (else
     (generate/cons-multiclosure target nentries size
				 (vector->list entries)))))

(let-syntax ((define/format-dependent
	       (macro (name1 name2)
		 `(define ,name1
		    (case MC68K/closure-format
		      ((MC68020)
		       ,(intern
			 (string-append "MC68020/" (symbol->string name2))))
		      ((MC68040)
		       ,(intern
			 (string-append "MC68040/" (symbol->string name2))))
		      (else
		       (error "Unknown closure format" closure-format)))))))

(define/format-dependent generate/closure-header closure-header)
(define/format-dependent generate/cons-closure cons-closure)
(define/format-dependent generate/cons-multiclosure cons-multiclosure)
)

;;;; Entry Header
;;; This is invoked by the top level of the LAP generator.

(define (generate/quotation-header environment-label free-ref-label n-sections)
  (LAP (LEA (@PCR ,environment-label) (A 0))
       (MOV L ,reg:environment (@A 0))
       (LEA (@PCR ,*block-label*) (A 0))
       (MOV L (A 0) (D 2))
       (LEA (@PCR ,free-ref-label) (A 0))
       (MOV L (A 0) (D 3))
       ,@(load-dnl n-sections 4)
       (JSR ,entry:compiler-link)
       ,@(make-external-label (continuation-code-word false)
			      (generate-label))))

(define (generate/remote-link code-block-label
			      environment-offset
			      free-ref-offset
			      n-sections)
  (let ((load-offset
	 (lambda (offset)
	   (if (<= -32768 offset 32767)
	       (LAP (LEA (@AO 0 ,offset) (A 1)))
	       (LAP (LEA (@AOF 0 E (,offset L) #F
			       ((D 0) L 1) Z
			       (0 N))
			 (A 1)))))))
    (LAP (MOV L (@PCR ,code-block-label) (D 2))
	 (AND L ,mask-reference (D 2))
	 (MOV L (D 2) (A 0))
	 ,@(load-offset environment-offset)
	 (MOV L ,reg:environment (@A 1))
	 ,@(load-offset free-ref-offset)
	 (MOV L (A 1) (D 3))
	 ,@(load-dnl n-sections 4)
	 (JSR ,entry:compiler-link)
	 ,@(make-external-label (continuation-code-word false)
				(generate-label)))))

(define (generate/constants-block constants references assignments
				  uuo-links global-links static-vars)
  (let ((constant-info
	 (declare-constants 0 (transmogrifly uuo-links)
	   (declare-constants 1 references
	     (declare-constants 2 assignments
	       (declare-constants 3 (transmogrifly global-links)
		 (declare-constants false
		     (map (lambda (pair)
			    (cons false (cdr pair)))
			  static-vars)
		   (declare-constants false constants
		     (cons false (LAP))))))))))
    (let ((free-ref-label (car constant-info))
	  (constants-code (cdr constant-info))
	  (debugging-information-label (allocate-constant-label))
	  (environment-label (allocate-constant-label))
	  (n-sections
	   (+ (if (null? uuo-links) 0 1)
	      (if (null? references) 0 1)
	      (if (null? assignments) 0 1)
	      (if (null? global-links) 0 1))))
      (values
       (LAP ,@constants-code
	    ;; Place holder for the debugging info filename
	    (SCHEME-OBJECT ,debugging-information-label DEBUGGING-INFO)
	    ;; Place holder for the load time environment if needed
	    (SCHEME-OBJECT ,environment-label
			   ,(if (null? free-ref-label) 0 'ENVIRONMENT)))
       environment-label
       free-ref-label
       n-sections))))

(define (declare-constants tag constants info)
  (define (inner constants)
    (if (null? constants)
	(cdr info)
	(let ((entry (car constants)))
	  (LAP (SCHEME-OBJECT ,(cdr entry) ,(car entry))
	       ,@(inner (cdr constants))))))
  (if (and tag (not (null? constants)))
      (let ((label (allocate-constant-label)))
	(cons label
	      (inner
	       `((,(let ((datum (length constants)))
		     (if (> datum #xffff)
			 (error "datum too large" datum))
		     (+ (* tag #x10000) datum))
		  . ,label)
		 ,@constants))))
      (cons (car info) (inner constants))))

(define (transmogrifly uuos)
  (define (inner name assoc)
    (if (null? assoc)
	(transmogrifly (cdr uuos))
	(cons (cons name (cdar assoc)) 		; uuo-label
	      (cons (cons (caar assoc)		; frame-size
			  (allocate-constant-label))
		    (inner name (cdr assoc))))))
  (if (null? uuos)
      '()
      (inner (caar uuos) (cdar uuos))))

;;; Local Variables: ***
;;; eval: (put 'declare-constants 'scheme-indent-hook 2) ***
;;; End: ***
