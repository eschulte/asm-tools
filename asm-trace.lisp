;;; asm-trace.lisp --- Trace execution of GCC produced AT&T syntax assembler

;; Copyright (C) Eric Schulte and Thomas Dye 2012-2013

;; Licensed under the Gnu Public License Version 3 or later

;;; Code:
(defpackage #:asm-trace
  (:use :common-lisp :alexandria :metabang-bind :curry-compose-reader-macros
        :cl-ppcre)
  (:export :main))
(in-package :asm-trace)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (enable-curry-compose-reader-macros))


;;; Instrumentation and Trace Application
(defmacro re-cond (string &rest forms)
  "Conditionally execute FORMS based on matches to STRING.
The special variable MATCH is bound to the match data"
  `(let (matches)
     (cond ,@(mapcar
              (lambda-bind ((re . rest))
                (cons (if (or (keywordp re) (eq t re))
                          re
                          `(setf matches (multiple-value-bind (match-p matches)
                                             (scan-to-strings ,re ,string)
                                           (when match-p matches))))
                      rest))
              forms))))

(defun instrument (input-file trace-out &key (stream t))
  "Instrument INPUT-FILE to write an execution trace to TRACE-OUT."
  (let ((last-label "BEGINNING")
        (regs '(rax rbx rcx rdx rsi rdi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15)))
    (mapc
     {apply #'format stream}
     `(;; preamble
       ("	.comm	__tracer_fd,8,8~%")
       ("	.section	.rodata~%")
       (".TRACE0:~%	.string \"w\"~%")
       (".TRACE1:~%	.string \"~a\"~%" ,trace-out)
       ;; body of the assembler file
       ("~{~a~^~%~}"
        ,(mapcan
          (lambda-bind ((line-num . line))
            (declare (ignorable line-num))
            (re-cond line
              ("\.L\([0-9]*\):"        ; code labels
               (let ((name (aref matches 0)))
                 ;; print data into preamble
                 (format stream ".TRACES~a:~%	.string \"~a\\n\"~%" name name)
                 (setf last-label name)
                 ;; return tracing code
                 `(,line
                   ,@(mapcar [#'string-downcase {format nil "	pushq	%~a"}]
                             regs)
                   " 	movq	__tracer_fd(%rip), %rax"
                   " 	testq	%rax, %rax"
                   ,(format nil " 	jne	.TRACE~aALREADY" name)
                   " 	movl	$.TRACE0, %esi"
                   " 	movl	$.TRACE1, %edi"
                   " 	call	fopen"
                   " 	movq	%rax, __tracer_fd(%rip)"
                   ,(format nil " .TRACE~aALREADY:" name)
                   " 	movq	__tracer_fd(%rip), %rax"
                   " 	movq	%rax, %rcx"
                   ,(format nil " 	movl	$~a, %edx"
                            (1+ (length name)))
                   " 	movl	$1, %esi"
                   ,(format nil " 	movl	$.TRACES~a, %edi" name)
                   " 	call	fwrite"
                   ,@(mapcar [#'string-downcase {format nil "	popq	%~a"}]
                             (reverse regs)))))
              ("TODO: instrument"      ; control flow instructions
               )
              (:default (list line)))) ; all other lines
          (with-open-file (in input-file)
            (loop :for line = (read-line in nil :eof) :as index :from 0
               :until (eq line :eof)
               :collect (cons index line)))))))
    (format stream "~%")))


;;; Executable
(defmacro getopts (&rest forms)
  (let ((arg (gensym)))
    `(loop :for ,arg = (pop args) :while ,arg :do
        (cond
          ,@(mapcar (lambda-bind ((short long . body))
                      `((or (and ,short (string= ,arg ,short))
                            (and ,long  (string= ,arg ,long)))
                        ,@body))
                    forms)))))

(defun quit (&optional (errno 0))
  #+sbcl (sb-ext:exit :code errno)
  #+ccl  (ccl:quit errno))

(defun main (args)
  (in-package :asm-trace)
  (let ((help "Usage: ~a ACTION ASM.s [OPTION...]
 Trace the execution of GCC produced AT&T syntax assembler

Actions:
 inst --------------- instrument ASM.s
 apply -------------- apply trace to ASM.s

Options:
 -h,--help ---------- print this help message and exit
 -t,--trace FILE ---- save traces in FILE (default trace.out)
 -o,--out FILE ------ write instrumented asm to FILE~%")
        (self (pop args)))
    (when (or (not args)
              (string= (subseq (car args) 0 2) "-h")
              (string= (subseq (car args) 0 3) "--h"))
      (format t help self) (quit))

    (let* ((action (intern (string-upcase (pop args))))
           (input (pop args))
           ;; options
           (trace-out "trace.out")
           (inst-out (make-pathname
                      :name (concatenate 'string (pathname-name input) "-trace")
                      :type (pathname-type input))))
      (getopts
       ("-t" "--trace" (setf trace-out (pop args)))
       ("-o" "--out"   (setf inst-out (pop args))))

      (ecase action
        (inst (instrument input trace-out))
        (apply (format t "applying ~a to ~a~%" trace-out input))))))
