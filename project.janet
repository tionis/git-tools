(declare-project
  :name "git-tools"
  :description "some tools to make working with git easier"
  :dependencies ["https://github.com/janet-lang/spork"
                 "https://tasadar.net/tionis/jeff"]
  :author "tionis.dev"
  :license "MIT"
  :url "https://tasadar.net/tionis/jeff"
  :repo "git+https://tasadar.net/tionis/jeff")

(each f (os/dir "bin")
  (declare-executable
    :name f
    :entry (string/join ["bin" f] "/")
    :install true))

#(declare-source
#  :source ["main.janet"])

#(declare-native
# :name "mynative"
# :source ["mynative.c" "mysupport.c"]
# :embedded ["extra-functions.janet"])

#(declare-executable
#  :name "CHANGE_ME"
#  :entry "main.janet"
#  :install true)
