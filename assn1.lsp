(include-book "intro")

(plev)

(set-slow-alist-action :break)
(set-debugger-enable t)
(break-on-error t)

(value-triple (set-max-mem (* 2 (expt 2 30))))

; EXERCISE 4

; translating the ALU design
(defmodules *translation3*
  (vl2014::make-vl-loadconfig
   :start-files (list "assn1.v")))

; lookup the simplified version of "alu"
(defconst *alu-vl3*
  (vl2014::vl-find-module "alu"
                          (vl2014::vl-design->mods
                           (vl2014::vl-translation->good *translation3*))))

; extract the E module
(defconst *alu3*
  (vl2014::vl-module->esim *alu-vl3*))

; writing a Symbolic Test Vector (STV)
(defstv test-vector3
  :mod *alu3*
  :inputs
  '(("a" a)
    ("b" b)
    ("alu_op" op))


  :outputs
  '(("c_out" c)
    ("z" z)
    ("v" v)
    ("n" n)
    ("r" res)))

; test it - only for us- REMOVE THIS
; a+1
(stv-run (test-vector3)
         '((a . 9)
           (b . 5)
           (op . 9)))
; a+b
(stv-run (test-vector3)
         '((a . 9)
           (b . 5)
           (op . 12)))


; EXERCISE 5

; prove of operation 'a'
(def-gl-thm alu3-proof-a
  :hyp (and (unsigned-byte-p 8 a)
            (unsigned-byte-p 8 b)
            (unsigned-byte-p 4 op)
            (equal op 8))

  :concl (let* ((in-alist (list (cons 'a a)
                                (cons 'b b)
                                (cons 'op op)))
                (out-alist (stv-run (test-vector3) in-alist))
                (res       (cdr (assoc 'res out-alist))))
           (equal res a))
  :g-bindings (gl::auto-bindings (:nat a 8)
                                 (:nat b 8)
                                 (:nat op 4)))

; prove of operation 'a+b'
(def-gl-thm alu3-proof-a-plus-b
  :hyp (and (unsigned-byte-p 8 a)
            (unsigned-byte-p 8 b)
            (unsigned-byte-p 4 op)
            (equal op 12))

  :concl (let* ((in-alist (list (cons 'a a)
                                (cons 'b b)
                                (cons 'op op)))
                (out-alist (stv-run (test-vector3) in-alist))
                (res       (cdr (assoc 'res out-alist))))
           (equal res (mod (+ a b) (expt 2 8))))
  :g-bindings (gl::auto-bindings (:nat a 8)
                                 (:nat b 8)
                                 (:nat op 4)))
