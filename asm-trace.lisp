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
    ;; loop
    loop loopx))

(defvar x86-unconditional-control-flow-instructions
  '(jmp ret))

(defvar x86-control-flow-rx
  (format nil "^	(~(~{~a~^|~}~))"
          (append x86-control-flow-instructions
                  x86-unconditional-control-flow-instructions)))

(defvar code-label-rx "\\.L([0-9]*):")

(defvar function-beginning-rx "\\.L(FB[0-9]*):")

(defvar data-label-rx "\\.L([^0-9]\\S*):")

(defvar data-reference-rx "\\$\\.L([^,\s]+)")

(defun indexed-file-lines (asm-file)
  (with-open-file (in asm-file)
    (loop :for line = (read-line in nil :eof) :as index :from 0
       :until (eq line :eof)
       :collect (cons index line))))

(defun instrument (asm-lines trace-out &key (stream *standard-output*))
  "Instrument ASM-LINES to write an execution trace to TRACE-OUT."
  (let ((last-label "")
        (jump-count 0))
    ;; preamble
    (let ((regs
           '(rax rbx rcx rdx rsi rdi rbp rsp r8 r9 r10 r11 r12 r13 r14 r15)))
      (mapc (lambda (line)
              (write (concatenate 'string line (list #\Newline))
                     :stream stream :escape nil))
            `("	.macro __do_trace length, name"
              ,@(mapcar [#'string-downcase {format nil "	pushq	%~a"}]
                        regs)
              " 	movq	__tracer_fd(%rip), %rax"
              " 	testq	%rax, %rax"
              " 	jne	.TRACEALREADY\\name"
              " 	movl	$.TRACE0, %esi"
              " 	movl	$.TRACE1, %edi"
              " 	call	fopen"
              " 	movq	%rax, __tracer_fd(%rip)"
              " .TRACEALREADY\\name:"
              " 	movq	__tracer_fd(%rip), %rax"
              " 	movq	%rax, %rcx"
              " 	movl	$\\length, %edx"
              " 	movl	$1, %esi"
              " 	movl	$.TRACES\\name, %edi"
              " 	call	fwrite"
              ,@(mapcar [#'string-downcase {format nil "	popq	%~a"}]
                        (reverse regs))
              "	.endm"
              "	.comm	__tracer_fd,8,8"
              "	.section	.rodata"
              ".TRACE0:	.string \"w\""
              ,(format nil ".TRACE1:~%	.string \"~a\"" trace-out))))
    (flet ((print-trace (line name)
             (list line (format nil "	__do_trace	~a, ~a"
                                (1+ (length name)) name))))
      (format stream "~{~a~^~%~}"
              (mapcan
               (lambda-bind ((line-num . line))
                 (declare (ignorable line-num))
                 (re-cond line
                   (function-beginning-rx ; function labels
                    (format stream ".TRACES~a:~%	.string \"~a\\n\"~%"
                            name name)
                    (setf last-label name)
                    (setf jump-count 0)
                    (print-trace line name))
                   (code-label-rx       ; code labels
                    (format stream ".TRACES~a:~%	.string \"~a\\n\"~%"
                            name name)
                    (setf last-label name)
                    (setf jump-count 0)
                    (print-trace line name))
                   (x86-control-flow-rx ; control flow instructions
                    (setf name (format nil "~aJ~d" last-label jump-count)
                          jump-count (1+ jump-count))
                    (format stream ".TRACES~a:~%	.string \"~a\\n\"~%"
                            name name)
                    (if (member (intern (string-upcase (aref matches 0)))
                                x86-unconditional-control-flow-instructions)
                        (list line)
                        (print-trace line name)))
                   (t (list line))))    ; all other lines
               asm-lines)))
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
         (function-beginning-rx         ; function labels
          (setf last-label name
                jump-count 0
                last-count (or (car (rassoc name c-counts :test #'string=)) 0))
          (incf (aref results line-num) last-count))
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
  (let ((help "Usage: ~a ASM.s TRACEFILE [ACTION]
 Trace AT&T syntax assembler produced by GCC

Optional argument ACTION may be one of the following to
force the action performed, the default action depends
on the TRACEFILE.  Results are written to STDOUT.

Actions:
 inst ------- instrument ASM.s to print a label trace
              (run when TRACEFILE doesn't exist)
 label ------ expand label trace to LOC trace
              (run when TRACEFILE is label trace)
 addr ------- expand address trace to LOC trace
              (run when TRACEFILE is address trace)
 prop ------- propagate LOC trace through ASM.s
                      (run when TRACEFILE is line trace)~%")
        (self (pop args)))
    (when (or (not args) (< (length args) 2)
              (string= (subseq (car args) 0 2) "-h")
              (string= (subseq (car args) 0 3) "--h"))
      (format t help self) (quit))

    (let* ((asm-file (pop args))
           (trace-file (pop args))
           (action (or (pop args)
                       (cond ; guess actions from contents of trace file
                         ((not (probe-file trace-file)) 'inst)
                         ;; TODO: more
                         (())))))

      (ecase action
        (inst (instrument (indexed-file-lines asm-file) trace-out))
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
                   (propagate (indexed-file-lines asm-file) counts))))))))
