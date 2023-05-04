(import spork/sh)

(defn git [& args]
  (sh/exec-slurp "git" ;args))
