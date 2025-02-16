install:
	@echo "Installing..."
	./install

bootstrap-ubuntu:
	@echo "Bootstrapping..."
	./bootstrap-ubuntu.sh

test-docker:
	./test-bootstrap.sh
uninstall:
	@echo "Uninstalling..."
	./uninstall
