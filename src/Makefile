LISP:="sbcl"
BA:=buildapp
QUICK_LISP?=$(HOME)/quicklisp/

ifeq ($(shell [ -f $(QUICK_LISP)/setup.lisp ] && echo exists),)
$(error The QUICK_LISP environment variable must point to your quicklisp install)
endif

QUIT=(lambda (error hook-value)
QUIT+=(declare (ignorable hook-value))
QUIT+=(format *error-output* \"ERROR: ~a~%\" error)
QUIT+=\#+sbcl (sb-ext:exit :code 2) \#+ccl (quit 2))
BUILD_APP_FLAGS=--manifest-file $(QUICK_LISP)/local-projects/system-index.txt \
	--asdf-tree $(QUICK_LISP)/dists/quicklisp/software \
	--eval "(setf *debugger-hook* $(QUIT))" \
	--load-system asm-trace

ifneq ($(LISP_STACK),)
BUILD_APP_FLAGS+= --dynamic-space-size $(LISP_STACK)
endif

asm-trace: asm-trace.lisp
	$(BA) $(BUILD_APP_FLAGS) --output $@ --entry "asm-trace:main"
