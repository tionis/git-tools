(declare-project
  :name "git-tools"
  :description "some tools to make working with git easier"
  :dependencies ["https://github.com/janet-lang/spork"
                 "https://tasadar.net/tionis/jeff"]
  :author "tionis.dev"
  :license "MIT"
  :url "https://tasadar.net/tionis/git-tools"
  :repo "git+https://tasadar.net/tionis/git-tools")

(each f (os/dir "git-tools/cli")
  (declare-executable # Install janet git tools
    :name (first (peg/match ~(* (* (capture (any (* (not ".janet") 1))) ".janet") -1) f))
    :entry (string "git-tools/cli/" f)
    :install true))

(each f (os/dir "bin") # Install shell scripts
  (declare-bin
    :main (string "bin/" f)))

(each f (if (os/stat "binscript") (os/dir "binscript") [])
  (declare-binscript # Install simple janet scripts
    :main (string "binscript/" f)
    :hardcode-syspath false
    :is-janet false))

(each f (if (os/stat "man") (os/dir "man") [])
  # TODO auto generate from module doc if not exists?
  (declare-manpage # Install man pages
    (string "man/" f)))

(declare-source # Declare source files to be imported by other janet based scripts
  :source ["git-tools"])
