(include-book "intro")

(plev)

(set-slow-alist-action :break)
(set-debugger-enable t)
(break-on-error t)

(value-triple (set-max-mem (* 2 (expt 2 30))))

; EXERCISE 4

; translating the ALU design
(defmodules *translation*
  (vl2014::make-vl-loadconfig
   :start-files (list "alu8.v")))

; lookup the simplified version of "alu"
(defconst *alu8-vl*
  (vl2014::vl-find-module "alu8"
                          (vl2014::vl-design->mods
                           (vl2014::vl-translation->good *translation*))))

; extract the E module
(defconst *alu8*
  (vl2014::vl-module->esim *alu8-vl*))

; writing a Symbolic Test Vector (STV)
(defstv test-vector
  :mod *alu8*
  :inputs
  '(("a" a)
    ("b" b)
    ("op" op))


  :outputs
  '(("flg" flg)
    ("res" res)))

(defconst *op-a*             8)
(defconst *op-plus-one*      9)
(defconst *op-minus-one*     10)
(defconst *op-plus*          12)
(defconst *op-plus-plus-one* 13)
(defconst *op-plus-not*      14)
(defconst *op-minus*         15)
(defconst *op-bitand*        0)
(defconst *op-bitxor*        2)
(defconst *op-bitor*         4)

; testing it
; a+1
;(stv-run (test-vector3)
;         `((a . 9)
;           (b . 5)
;           (op . ,*op-plus-one*)))
; a+b
;(stv-run (test-vector3)
;         `((a . 9)
;           (b . 5)
;           (op . ,*op-plus*)))


; EXERCISE 5

; prove of operation 'a'
(def-gl-thm alu8-proof-a
  :hyp (and (unsigned-byte-p 8 a)
            (unsigned-byte-p 8 b)
            (unsigned-byte-p 4 op)
            (equal op 8))

  :concl (let* ((in-alist (list (cons 'a a)
                                (cons 'b b)
                                (cons 'op op)))
                (out-alist (stv-run (test-vector) in-alist))
                (res       (cdr (assoc 'res out-alist))))
           (equal res a))
  :g-bindings (gl::auto-bindings (:nat a 8)
                                 (:nat b 8)
                                 (:nat op 4)))

; prove of operation 'a+b'
(def-gl-thm alu8-proof-a-plus-b
  :hyp (and (unsigned-byte-p 8 a)
            (unsigned-byte-p 8 b)
            (unsigned-byte-p 4 op)
            (equal op 12))

  :concl (let* ((in-alist (list (cons 'a a)
                                (cons 'b b)
                                (cons 'op op)))
                (out-alist (stv-run (test-vector) in-alist))
                (res       (cdr (assoc 'res out-alist))))
           (equal res (mod (+ a b) (expt 2 8))))
  :g-bindings (gl::auto-bindings (:nat a 8)
                                 (:nat b 8)
                                 (:nat op 4)))


; macros

(defmacro alu8-basic-result ()
  `(let* ((in-alist  (test-vector-autoins))
         (out-alist (stv-run (test-vector) in-alist))
         (res       (cdr (assoc 'res out-alist))))
    res))

(defmacro alu8-default-bindings ()
  `(gl::auto-bindings (:nat a 8)
                      (:nat b 8)
                      (:nat op 4)))

(defmacro alu8-thm (name &key opcode spec (g-bindings
                                           '(alu8-default-bindings)))
  `(def-gl-thm ,name
     :hyp (and (test-vector-autohyps)
               (equal op ,opcode))
     :concl (equal (alu8-basic-result) ,spec)
     :g-bindings ,g-bindings))

; EXERCISE 7
(alu8-thm another-proof-a
          :opcode *op-a*
          :spec a)

(alu8-thm proof-plus-one
          :opcode *op-plus-one*
          :spec (mod (+ a 1) (expt 2 8)))

(alu8-thm proof-minus-one
          :opcode *op-minus-one*
          :spec (mod (- a 1) (expt 2 8)))

(alu8-thm another-proof-plus
          :opcode *op-plus*
          :spec (mod (+ a b) (expt 2 8)))

(alu8-thm proof-plus-plus-one
          :opcode *op-plus-plus-one*
          :spec (mod (+ a b 1) (expt 2 8)))

(alu8-thm proof-plus-not
          :opcode *op-plus-not*
          :spec (mod (+ a (lognot b)) (expt 2 8)))

(alu8-thm proof-minus
          :opcode *op-minus*
          :spec (mod (- a b) (expt 2 8)))

(alu8-thm proof-bitand
          :opcode *op-bitand*
          :spec (logand a b))

(alu8-thm proof-bitxor
          :opcode *op-bitxor*
          :spec (logxor a b))

(alu8-thm proof-bitor
          :opcode *op-bitor*
          :spec (logior a b))
