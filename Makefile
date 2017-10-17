all: src/2584.jl
	julia build/juliac.jl src/2584.jl


.PHONY: test
test:
	julia src/2584.jl --save=test.bin
	test/2584-judge --load=test.bin --check
	rm test.bin
