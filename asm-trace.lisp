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
  `(let (matches name)
     (cond ,@(mapcar
              (lambda-bind ((re . rest))
                (cons (if (or (keywordp re) (eq t re))
                          re
                          `(multiple-value-bind (match-p match-array)
                               (scan-to-strings ,re ,string)
                             (when match-p
                               (setf matches match-array
                                     name (aref match-array 0)))))
                      rest))
              forms))))

(defvar x86-control-flow-instructions
  '(;; jumps
    je jne jg jge ja jae jl jle jb jbe jo jz jnz
    ;; function calls
    call ret
    ;; loop
    loop loopx))

(defvar x86-control-flow-rx
  (format nil "^	(~(~{~a~^|~}~))" x86-control-flow-instructions))

(defvar code-label-rx "\\.L([0-9]*):")

(defvar data-label-rx "\\.L([^0-9]\\S*):")

(defvar data-reference-rx "\\$\\.L([^,\s]+)")

(defun indexed-file-lines (asm-file)
  (with-open-file (in asm-file)
    (loop :for line = (read-line in nil :eof) :as index :from 0
       :until (eq line :eof)
       :collect (cons index line))))

(defun instrument (asm-lines trace-out &key (stream t))
  "Instrument ASM-LINES to write an execution trace to TRACE-OUT."
  ;; TODO: trace function lines
  (let ((last-label "")
        (jump-count 0)
        (regs '(rax rbx rcx rdx rsi rdi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15)))
    (flet ((print-trace (name)
             `(,@(mapcar [#'string-downcase {format nil "	pushq	%~a"}]
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
                (code-label-rx          ; code labels
                 ;; print data into preamble
                 (format stream ".TRACES~a:~%	.string \"~a\\n\"~%" name name)
                 (setf last-label name)
                 (setf jump-count 0)
                 ;; return tracing code
                 (cons line (print-trace name)))
                (x86-control-flow-rx    ; control flow instructions
                 (setf name (format nil "~aJ~d" last-label jump-count)
                       jump-count (1+ jump-count))
                 ;; print data into preamble
                 (format stream ".TRACES~a:~%	.string \"~a\\n\"~%" name name)
                 (cons line (print-trace name)))
                (t (list line))))       ; all other lines
            asm-lines)))))
    (format stream "~%")))

(defun propagate (asm-lines c-counts)
  "Propagate COUNTS through ASM-LINES."
  (let ((last-label "")
        (jump-count 0)
        (last-count 0)
        (results (make-array (length asm-lines)
                             :initial-element 0 :element-type 'integer))
        d-counts)
    ;; apply counts to the code lines
    (loop :for (line-num . line) :in asm-lines :do
       (re-cond line
         (code-label-rx                 ; code labels
          (setf last-label name
                jump-count 0
                last-count (or (car (rassoc name c-counts :test #'string=)) 0))
          (incf (aref results line-num) last-count))
         (x86-control-flow-rx           ; control flow instructions
          (incf (aref results line-num) last-count)
          (setf name (format nil "~aJ~d" last-label jump-count)
                jump-count (1+ jump-count)
                last-count (or (car (rassoc name c-counts :test #'string=)) 0)))
         (data-reference-rx             ; data reference
          (unless (zerop last-count)
            (incf (aref results line-num) last-count)
            (if (rassoc name d-counts :test #'string=)
                (incf (car (rassoc name d-counts :test #'string=)) last-count)
                (push (cons last-count name) d-counts))))
         (t                             ; all other lines
          (unless (zerop last-count)
            (incf (aref results line-num) last-count)))))
    ;; apply counts to the data lines
    (loop :for (line-num . line) :in asm-lines :do
       (re-cond line
         (data-label-rx                 ; data labels
          (setf last-count (or (car (rassoc name d-counts :test #'string=)) 0))
          (incf (aref results line-num) last-count))
         (t (unless (zerop last-count)
              (incf (aref results line-num) last-count)))))
    (coerce results 'list)))


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
 prop --------------- propagate trace counts through ASM.s

Options:
 -h,--help ---------- print this help message and exit
 -t,--trace FILE ---- save traces in FILE (default trace.out)~%")
        (self (pop args)))
    (when (or (not args)
              (string= (subseq (car args) 0 2) "-h")
              (string= (subseq (car args) 0 3) "--h"))
      (format t help self) (quit))

    (let* ((action (intern (string-upcase (pop args))))
           (input (pop args))
           ;; options
           (trace-out "trace.out")
           (trace-counts "trace.counts"))

      (getopts
       ("-t" "--trace" (setf trace-out (pop args))))

      (ecase action
        (inst (instrument (indexed-file-lines input) trace-out))
        (prop
         (let ((counts
                (with-open-file (in trace-counts)
                  (loop :for l = (read-line in nil :eof) :until (eq l :eof)
                     :collect
                     (multiple-value-bind (match-p matches)
                         (scan-to-strings "\\s*(\\S+)\\s+(\\S+)" l)
                       (assert match-p (l) "malformed count-file line ~S" l)
                       (cons (parse-integer (aref matches 0))
                             (aref matches 1)))))))
           (format t "~{~a~^~%~}~%"
                   (propagate (indexed-file-lines input) counts))))))))