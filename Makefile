install:
	@echo "Installing..."
	./install

bootstrap-ubuntu:
	@echo "Bootstrapping..."
	./create_user.sh
	./bootstrap-ubuntu.sh

test-docker:
	./test-bootstrap.sh
uninstall:
	@echo "Uninstalling..."
	./uninstall
