all: user_path_helper

PREFIX=$(HOME)/bin

FLAGS=""

user_path_helper: user_path_helper.native

user_path_helper.native: user_path_helper.ml
	corebuild $(FLAGS) user_path_helper.native

clean:
	rm *.native
	rm -fr _build

install: user_path_helper.native
	cp user_path_helper.native $(PREFIX)/user_path_helper

uninstall:
	rm $(PREFIX)/user_path_helper
