(declare-project
  :name "git-tools"
  :description "some tools to make working with git easier"
  :dependencies ["https://github.com/janet-lang/spork"
                 "https://tasadar.net/tionis/jeff"]
  :author "tionis.dev"
  :license "MIT"
  :url "https://tasadar.net/tionis/jeff"
  :repo "git+https://tasadar.net/tionis/jeff")

(each f (filter |(peg/match ~(sequence "git-" (any 1) -1) $0) (os/dir "git-tools"))
  (declare-executable
    :name f
    :entry (string "git-tools/" f)
    :install true))

(each f (os/dir "bin")
  (declare-binscript
    :main (string "bin/" f)
    :hardcode-syspath false
    :is-janet false))

(declare-source
  :source ["git-tools"])
