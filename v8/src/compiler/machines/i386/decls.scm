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

;;;; Compiler File Dependencies
;;; package: (compiler declarations)

(declare (usual-integrations))

(define (initialize-package!)
  (add-event-receiver! event:after-restore reset-source-nodes!)
  (reset-source-nodes!))

(define (reset-source-nodes!)
  (set! source-filenames '())
  (set! source-hash)
  (set! source-nodes)
  (set! source-nodes/by-rank)
  unspecific)

(define (maybe-setup-source-nodes!)
  (if (null? source-filenames)
      (setup-source-nodes!)))

(define (setup-source-nodes!)
  (let ((filenames
	 (append-map!
	  (lambda (subdirectory)
	    (map (lambda (pathname)
		   (string-append subdirectory
				  "/"
				  (pathname-name pathname)))
		 (directory-read
		  (string-append subdirectory
				 "/"
				 source-file-expression))))
	  '("back" "base" 
		   "midend"
		   "rtlbase"
		   "rtlopt"
		   "machines/i386"))))
    (if (null? filenames)
	(error "Can't find source files of compiler"))
    (set! source-filenames filenames))
  (set! source-hash (make-string-hash-table))
  (set! source-nodes
	(map (lambda (filename)
	       (let ((node (make/source-node filename)))
		 (hash-table/put! source-hash filename node)
		 node))
	     source-filenames))
  (initialize/syntax-dependencies!)
  (initialize/integration-dependencies!)
  (initialize/expansion-dependencies!)
  (source-nodes/rank!))

(define source-file-expression "*.scm")
(define source-filenames)
(define source-hash)
(define source-nodes)
(define source-nodes/by-rank)

(define (filename/append directory . names)
  (map (lambda (name) (string-append directory "/" name)) names))

(define-structure (source-node
		   (conc-name source-node/)
		   (constructor make/source-node (filename)))
  (filename false read-only true)
  (pathname (->pathname filename) read-only true)
  (forward-links '())
  (backward-links '())
  (forward-closure '())
  (backward-closure '())
  (dependencies '())
  (dependents '())
  (rank false)
  (syntax-table false)
  (declarations '())
  (modification-time false))

(define (filename->source-node filename)
  (let ((node (hash-table/get source-hash filename #f)))
    (if (not node)
	(error "Unknown source file:" filename))
    node))

(define (source-node/circular? node)
  (memq node (source-node/backward-closure node)))

(define (source-node/link! node dependency)
  (if (not (memq dependency (source-node/backward-links node)))
      (begin
	(set-source-node/backward-links!
	 node
	 (cons dependency (source-node/backward-links node)))
	(set-source-node/forward-links!
	 dependency
	 (cons node (source-node/forward-links dependency)))
	(source-node/close! node dependency))))

(define (source-node/close! node dependency)
  (if (not (memq dependency (source-node/backward-closure node)))
      (begin
	(set-source-node/backward-closure!
	 node
	 (cons dependency (source-node/backward-closure node)))
	(set-source-node/forward-closure!
	 dependency
	 (cons node (source-node/forward-closure dependency)))
	(for-each (lambda (dependency)
		    (source-node/close! node dependency))
		  (source-node/backward-closure dependency))
	(for-each (lambda (node)
		    (source-node/close! node dependency))
		  (source-node/forward-closure node)))))

;;;; Rank

(define (source-nodes/rank!)
  (compute-dependencies! source-nodes)
  (compute-ranks! source-nodes)
  (set! source-nodes/by-rank (source-nodes/sort-by-rank source-nodes))
  unspecific)

(define (compute-dependencies! nodes)
  (for-each (lambda (node)
	      (set-source-node/dependencies!
	       node
	       (list-transform-negative (source-node/backward-closure node)
		 (lambda (node*)
		   (memq node (source-node/backward-closure node*)))))
	      (set-source-node/dependents!
	       node
	       (list-transform-negative (source-node/forward-closure node)
		 (lambda (node*)
		   (memq node (source-node/forward-closure node*))))))
	    nodes))

(define (compute-ranks! nodes)
  (let loop ((nodes nodes) (unranked-nodes '()))
    (if (null? nodes)
	(if (not (null? unranked-nodes))
	    (loop unranked-nodes '()))
	(loop (cdr nodes)
	      (let ((node (car nodes)))
		(let ((rank (source-node/rank* node)))
		  (if rank
		      (begin
			(set-source-node/rank! node rank)
			unranked-nodes)
		      (cons node unranked-nodes))))))))

(define (source-node/rank* node)
  (let loop ((nodes (source-node/dependencies node)) (rank -1))
    (if (null? nodes)
	(1+ rank)
	(let ((rank* (source-node/rank (car nodes))))
	  (and rank*
	       (loop (cdr nodes) (max rank rank*)))))))

(define (source-nodes/sort-by-rank nodes)
  (sort nodes (lambda (x y) (< (source-node/rank x) (source-node/rank y)))))

;;;; File Syntaxer

(define (syntax-files!)
  (maybe-setup-source-nodes!)
  (for-each
   (lambda (node)
     (let ((modification-time
	    (let ((source (modification-time node "scm"))
		  (binary (modification-time node "bin")))
	      (if (not source)
		  (error "Missing source file" (source-node/filename node)))
	      (and binary (< source binary) binary))))
     (set-source-node/modification-time! node modification-time)
     (if (not modification-time)
	 (begin (write-string "\nSource file newer than binary: ")
		(write (source-node/filename node))))))
   source-nodes)
  (if compiler:enable-integration-declarations?
      (begin
	(for-each
	 (lambda (node)
	   (let ((time (source-node/modification-time node)))
	     (if (and time
		      (there-exists? (source-node/dependencies node)
			(lambda (node*)
			  (let ((newer?
				 (let ((time*
					(source-node/modification-time node*)))
				   (or (not time*)
				       (> time* time)))))
			    (if newer?
				(begin
				  (write-string "\nBinary file ")
				  (write (source-node/filename node))
				  (write-string " newer than dependency ")
				  (write (source-node/filename node*))))
			    newer?))))
		 (set-source-node/modification-time! node false))))
	 source-nodes)
	(for-each
	 (lambda (node)
	   (if (not (source-node/modification-time node))
	       (for-each (lambda (node*)
			   (if (source-node/modification-time node*)
			       (begin
				 (write-string "\nBinary file ")
				 (write (source-node/filename node*))
				 (write-string " depends on ")
				 (write (source-node/filename node))))
			   (set-source-node/modification-time! node* false))
			 (source-node/forward-closure node))))
	 source-nodes)))
  (for-each (lambda (node)
	      (if (not (source-node/modification-time node))
		  (pathname-delete!
		   (pathname-new-type (source-node/pathname node) "ext"))))
	    source-nodes/by-rank)
  (write-string "\n\nBegin pass 1:")
  (for-each (lambda (node)
	      (if (not (source-node/modification-time node))
		  (source-node/syntax! node)))
	    source-nodes/by-rank)
  (if (there-exists? source-nodes/by-rank
	(lambda (node)
	  (and (not (source-node/modification-time node))
	       (source-node/circular? node))))
      (begin
	(write-string "\n\nBegin pass 2:")
	(for-each (lambda (node)
		    (if (not (source-node/modification-time node))
			(if (source-node/circular? node)
			    (source-node/syntax! node)
			    (source-node/touch! node))))
		  source-nodes/by-rank))))

(define (source-node/touch! node)
  (with-values
      (lambda ()
	(sf/pathname-defaulting (source-node/pathname node) "" false))
    (lambda (input-pathname bin-pathname spec-pathname)
      input-pathname
      (pathname-touch! bin-pathname)
      (pathname-touch! (pathname-new-type bin-pathname "ext"))
      (if spec-pathname (pathname-touch! spec-pathname)))))

(define (pathname-touch! pathname)
  (if (file-exists? pathname)
      (begin
	(write-string "\nTouch file: ")
	(write (enough-namestring pathname))
	(file-touch pathname))))

(define (pathname-delete! pathname)
  (if (file-exists? pathname)
      (begin
	(write-string "\nDelete file: ")
	(write (enough-namestring pathname))
	(delete-file pathname))))

(define (sc filename)
  (maybe-setup-source-nodes!)
  (source-node/syntax! (filename->source-node filename)))

(define (source-node/syntax! node)
  (with-values
      (lambda ()
	(sf/pathname-defaulting (source-node/pathname node) "" false))
    (lambda (input-pathname bin-pathname spec-pathname)
      (sf/internal
       input-pathname bin-pathname spec-pathname
       (source-node/syntax-table node)
       ((if compiler:enable-integration-declarations?
	    identity-procedure
	    (lambda (declarations)
	      (list-transform-negative declarations
		integration-declaration?)))
	((if compiler:enable-expansion-declarations?
	     identity-procedure
	     (lambda (declarations)
	       (list-transform-negative declarations
		 expansion-declaration?)))
	 (source-node/declarations node)))))))

(define-integrable (modification-time node type)
  (file-modification-time
   (pathname-new-type (source-node/pathname node) type)))

;;;; Syntax dependencies

(define (initialize/syntax-dependencies!)
  (let ((file-dependency/syntax/join
	 (lambda (filenames syntax-table)
	   (for-each (lambda (filename)
		       (set-source-node/syntax-table!
			(filename->source-node filename)
			syntax-table))
		     filenames))))
    (file-dependency/syntax/join
     (append (filename/append "base"
			      "toplev" "asstop" "crstop"
			      "cfg1" "cfg2" "cfg3" "constr"
			      "debug" "enumer"
			      "infnew"
			      "object" "pmerly"
			      "scode" "sets" 
			      "stats"
			      "switch" "utils")
	     (filename/append "back"
			      "asmmac" "bittop" "bitutl" "insseq" "lapgn1"
			      "lapgn2" "lapgn3" "linear" "regmap" "symtab"
			      "syntax")
	     (filename/append "machines/i386"
			      "dassm1" "insmac" "lapopt" "machin" "rgspcm"
			      "rulrew")
	     (filename/append "midend"
			      "alpha" "applicat" "assconv" "cleanup"
			      "closconv" "coerce" "compat" "copier" "cpsconv"
			      "dataflow" "dbgstr" "debug" "earlyrew"
			      "envconv" "expand" "fakeprim" "graph"
			      "indexify" "inlate" "lamlift" "laterew"
			      "load" "midend" "rtlgen" "simplify"
			      "split" "stackopt" "staticfy" "synutl"
			      "triveval" "utils" "widen"
			      )
	     (filename/append "rtlbase"
			      "regset" "rgraph" "rtlcfg" "rtlcon" "rtlexp"
			      "rtline" "rtlobj" "rtlreg" "rtlty1" "rtlty2"
			      "valclass"
			      ;; New stuff
			      "rtlpars"
			      ;; End of New stuff
			      )
	     (filename/append "rtlopt"
			      "ralloc" "rcompr" "rcse1" "rcse2" "rcseep"
			      "rcseht" "rcserq" "rcsesr" "rcsemrg"
			      "rdebug" "rdflow" "rerite" "rinvex"
			      "rlife" "rtlcsm"))
     compiler-syntax-table)
    (file-dependency/syntax/join
     (filename/append "machines/i386"
		      "lapgen"
		      "rules1" "rules2" "rules3" "rules4" "rulfix" "rulflo")
     lap-generator-syntax-table)
    (file-dependency/syntax/join
     (filename/append "machines/i386" "insutl" "instr1" "instr2" "instrf")
     assembler-syntax-table)))

;;;; Integration Dependencies

(define (initialize/integration-dependencies!)
  (define (add-declaration! declaration filenames)
    (for-each (lambda (filenames)
		(let ((node (filename->source-node filenames)))
		  (set-source-node/declarations!
		   node
		   (cons declaration
			 (source-node/declarations node)))))
	      filenames))

  (let* ((front-end-base
	  (filename/append "base"
			   "cfg1" "cfg2" "cfg3"
			   "enumer" "lvalue"
			   "object"
			   "scode"
			   "stats"
			   "utils"))
	 (midend-base
	  (filename/append "midend"
			   "fakeprim"  "utils"))
	 (i386-base
	  (append (filename/append "machines/i386" "machin")
		  (filename/append "back" "asutl")))
	 (rtl-base
	  (filename/append "rtlbase"
			   "rgraph" "rtlcfg" "rtlobj" "rtlreg" "rtlty1"
			   "rtlty2"))
	 (cse-base
	  (filename/append "rtlopt"
			   "rcse1" "rcseht" "rcserq" "rcsesr"))
	 (cse-all
	  (append (filename/append "rtlopt"
				   "rcse2" "rcsemrg" "rcseep")
		  cse-base))
	 (instruction-base
	  (filename/append "machines/i386" "assmd" "machin"))
	 (lapgen-base
	  (append (filename/append "back" "linear" "regmap")
		  (filename/append "machines/i386" "lapgen")))
	 (assembler-base
	  (append (filename/append "back" "symtab")
		  (filename/append "machines/i386" "insutl")))
	 (lapgen-body
	  (append
	   (filename/append "back" "lapgn1" "lapgn2" "syntax")
	   (filename/append "machines/i386"
			    "rules1" "rules2" "rules3" "rules4"
			    "rulfix" "rulflo")))
	 (assembler-body
	  (append
	   (filename/append "back" "bittop")
	   (filename/append "machines/i386"
			    "instr1" "instr2" "instrf"))))

    (define (file-dependency/integration/join filenames dependencies)
      (for-each (lambda (filename)
		  (file-dependency/integration/make filename dependencies))
		filenames))

    (define (file-dependency/integration/make filename dependencies)
      (let ((node (filename->source-node filename)))
	(for-each (lambda (dependency)
		    (let ((node* (filename->source-node dependency)))
		      (if (not (eq? node node*))
			  (source-node/link! node node*))))
		  dependencies)))

    (define (define-integration-dependencies directory name directory* . names)
      (file-dependency/integration/make
       (string-append directory "/" name)
       (apply filename/append directory* names)))

    (define-integration-dependencies "machines/i386" "machin" "back" "asutl")
    (define-integration-dependencies "base" "object" "base" "enumer")
    (define-integration-dependencies "base" "enumer" "base" "object")
    (define-integration-dependencies "base" "utils" "base" "scode")
    (define-integration-dependencies "base" "cfg1" "base" "object")
    (define-integration-dependencies "base" "cfg2" "base"
      "cfg1" "cfg3" "object")
    (define-integration-dependencies "base" "cfg3" "base" "cfg1" "cfg2")

    (define-integration-dependencies "machines/i386" "machin" "rtlbase"
      "rtlreg" "rtlty1" "rtlty2")

    (define-integration-dependencies "rtlbase" "rgraph" "base" "cfg1" "cfg2")
    (define-integration-dependencies "rtlbase" "rgraph" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlcfg" "base"
      "cfg1" "cfg2" "cfg3")
    (define-integration-dependencies "rtlbase" "rtlcon" "base" "cfg3" "utils")
    (define-integration-dependencies "rtlbase" "rtlcon" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlexp" "rtlbase"
      "rtlreg" "rtlty1")
    (define-integration-dependencies "rtlbase" "rtline" "base" "cfg1" "cfg2")
    (define-integration-dependencies "rtlbase" "rtline" "rtlbase"
      "rtlcfg" "rtlty2")
    (define-integration-dependencies "rtlbase" "rtlobj" "base"
      "cfg1" "object" "utils")
    (define-integration-dependencies "rtlbase" "rtlreg" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlreg" "rtlbase"
      "rgraph" "rtlty1")
    (define-integration-dependencies "rtlbase" "rtlty1" "rtlbase" "rtlcfg")
    (define-integration-dependencies "rtlbase" "rtlty2" "base" "scode")
    (define-integration-dependencies "rtlbase" "rtlty2" "machines/i386"
      "machin")
    (define-integration-dependencies "rtlbase" "rtlty2" "rtlbase" "rtlty1")

    ;; New stuff
    (file-dependency/integration/join (filename/append "rtlbase" "rtlpars")
				      rtl-base)
    ;;(file-dependency/integration/join
    ;; (filename/append "midend"
	;;	      "alpha" "applicat" "assconv" "cleanup"
	;;	      "closconv" "compat" "copier" "cpsconv"
	;;	      "dataflow" "dbgstr" "debug" "earlyrew"
	;;              "envconv" "expand"   "graph"
	;;	      "indexify" "inlate" "lamlift" "laterew"
	;;	      "load" "midend" "rtlgen" "simplify"
	;;	      "split" "stackopt" "staticfy" "synutl"
	;;	      "triveval" "widen")
    ;; midend-base)

    ;; End of new stuff

    (file-dependency/integration/join
     (append cse-all
	     (filename/append "rtlopt" "ralloc" "rcompr" "rdebug" "rdflow"
			      "rerite" "rinvex" "rlife" "rtlcsm")
	     (filename/append "machines/i386" "rulrew"))
     (append i386-base rtl-base))

    (file-dependency/integration/join cse-all cse-base)

    (file-dependency/integration/join
     (filename/append "rtlopt" "ralloc" "rcompr" "rdebug" "rlife")
     (filename/append "rtlbase" "regset"))

    (file-dependency/integration/join
     (filename/append "rtlopt" "rcseht" "rcserq")
     (filename/append "base" "object"))

    (define-integration-dependencies "rtlopt" "rlife"  "base" "cfg2")

    (let ((dependents
	   (append instruction-base
		   lapgen-base
		   lapgen-body
		   assembler-base
		   assembler-body
		   (filename/append "back" "linear" "syerly"))))
      (add-declaration! '(USUAL-DEFINITION (SET EXPT)) dependents)
      (file-dependency/integration/join dependents instruction-base))

    (file-dependency/integration/join (append lapgen-base lapgen-body)
				      lapgen-base)

    (file-dependency/integration/join (append assembler-base assembler-body)
				      assembler-base)

    (define-integration-dependencies "back" "lapgn1" "base"
      "cfg1" "cfg2" "utils")
    (define-integration-dependencies "back" "lapgn1" "rtlbase"
      "rgraph" "rtlcfg")
    (define-integration-dependencies "back" "lapgn2" "rtlbase" "rtlreg")
    (define-integration-dependencies "back" "linear" "base" "cfg1" "cfg2")
    (define-integration-dependencies "back" "linear" "rtlbase" "rtlcfg")
    (define-integration-dependencies "back" "mermap" "back" "regmap")
    (define-integration-dependencies "back" "regmap" "base" "utils")
    (define-integration-dependencies "back" "symtab" "base" "utils"))

  (for-each (lambda (node)
	      (let ((links (source-node/backward-links node)))
		(if (not (null? links))
		    (set-source-node/declarations!
		     node
		     (cons (make-integration-declaration
			    (source-node/pathname node)
			    (map source-node/pathname links))
			   (source-node/declarations node))))))
	    source-nodes))

(define (make-integration-declaration pathname integration-dependencies)
  `(INTEGRATE-EXTERNAL
    ,@(map (let ((default
		  (make-pathname
		   false
		   false
		   (cons 'RELATIVE
			 (make-list
			  (length (cdr (pathname-directory pathname)))
			  'UP))
		   false
		   false
		   false)))
	     (lambda (pathname)
	       (merge-pathnames pathname default)))
	   integration-dependencies)))

(define-integrable (integration-declaration? declaration)
  (eq? (car declaration) 'INTEGRATE-EXTERNAL))

;;;; Expansion Dependencies

(define (initialize/expansion-dependencies!)
  (let ((file-dependency/expansion/join
	 (lambda (filenames expansions)
	   (for-each (lambda (filename)
		       (let ((node (filename->source-node filename)))
			 (set-source-node/declarations!
			  node
			  (cons (make-expansion-declaration expansions)
				(source-node/declarations node)))))
		     filenames))))
    (file-dependency/expansion/join
     (filename/append "machines/i386"
		      "lapgen" "rules1" "rules2" "rules3" "rules4"
		      "rulfix" "rulflo")
     (map (lambda (entry)
	    `(,(car entry)
	      (PACKAGE/REFERENCE (FIND-PACKAGE '(COMPILER LAP-SYNTAXER))
				 ',(cadr entry))))
	  '((LAP:SYNTAX-INSTRUCTION LAP:SYNTAX-INSTRUCTION-EXPANDER)
	    (INSTRUCTION->INSTRUCTION-SEQUENCE
	     INSTRUCTION->INSTRUCTION-SEQUENCE-EXPANDER)
	    (SYNTAX-EVALUATION SYNTAX-EVALUATION-EXPANDER)
	    (CONS-SYNTAX CONS-SYNTAX-EXPANDER)
	    (OPTIMIZE-GROUP-EARLY OPTIMIZE-GROUP-EXPANDER)
	    (EA-KEYWORD-EARLY EA-KEYWORD-EXPANDER)
	    (EA-MODE-EARLY EA-MODE-EXPANDER)
	    (EA-REGISTER-EARLY EA-REGISTER-EXPANDER)
	    (EA-EXTENSION-EARLY EA-EXTENSION-EXPANDER)
	    (EA-CATEGORIES-EARLY EA-CATEGORIES-EXPANDER))))))

(define-integrable (make-expansion-declaration expansions)
  `(EXPAND-OPERATOR ,@expansions))

(define-integrable (expansion-declaration? declaration)
  (eq? (car declaration) 'EXPAND-OPERATOR))
