#!/bin/env janet
(import spork/path)
(import spork/sh)
(import jeff)

(defn- exec [& argv]
  (when (not= (os/execute [;argv] :p) 0)
    (error (string "command '" (string/join argv " ") "' failed"))))

(defn filter-and-split-paths-into-components [p]
  # Use path/posix as git always returns posix parts, if on windows they can be converted later
  (def parts (path/posix/parts p))
  (def ret (array/new (length parts)))
  (array/push ret (get parts 0 "/"))
  (if (> (length parts) 1)
    (do
      (each part (slice parts 1 -1)
        (array/push ret (path/posix/join (last ret) part)))
      ret)
    [])) # Ignore top level or empty paths

(defn interactive-sparse-checkout []
  (def selected-paths @[])
  (def available-paths
    (->> (sh/exec-slurp "git" "ls-tree" "--name-only" "-r" "-z" "HEAD")
         (string/split "\0")
         (mapcat filter-and-split-paths-into-components)
         (distinct)))
  (exec "git" "sparse-checkout" "set" ;(jeff/choose available-paths :multi true))
  (exec "git" "checkout" "HEAD"))
